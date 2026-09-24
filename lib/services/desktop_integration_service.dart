import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dart_flutter_demo/services/ico_encoder.dart';
import 'package:linux_desktop_integration_vincentzyu/linux_desktop_integration_vincentzyu.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:windows_desktop_integration_vincentzyu/windows_desktop_integration_vincentzyu.dart';

/// What activating a desktop shortcut does inside the window.
enum DesktopShortcutKind {
  /// One page of the bottom navigation bar.
  page,

  /// The About dialog of the drawer.
  about,

  /// The page guide dialog of the drawer.
  guide,
}

/// One destination shared by every desktop shell surface.
class DesktopShortcut {
  const DesktopShortcut({
    required this.id,
    required this.label,
    required this.arguments,
    required this.icon,
    required this.kind,
    this.pageIndex,
  });

  /// Stable identifier reported by the Windows thumbnail toolbar.
  final String id;

  /// Title rendered by the desktop shell.
  final String label;

  /// Command line fragment used by jump lists and desktop entry actions.
  final String arguments;

  /// Glyph rendered into the Windows thumbnail toolbar.
  final IconData icon;

  /// What activating this destination does.
  final DesktopShortcutKind kind;

  /// Bottom navigation index, set for [DesktopShortcutKind.page].
  final int? pageIndex;
}

/// Page titles used by desktop previews and MPRIS metadata.
const List<String> desktopPageLabels = <String>[
  'System Info',
  'Dialog Lab',
  'Typography',
  'Adaptive Grid',
  'Controls',
];

/// Number of page destinations, which are the first entries of
/// [desktopShortcuts].
const int desktopPageCount = 5;

/// The seven destinations exposed to the desktop shell.
///
/// The order is also the Windows thumbnail toolbar order, and Windows drops the
/// rightmost buttons first, so the two drawer destinations stay last.
const List<DesktopShortcut> desktopShortcuts = <DesktopShortcut>[
  DesktopShortcut(
    id: 'system',
    label: 'System Info',
    arguments: '--tab=system',
    icon: Icons.info_outline,
    kind: DesktopShortcutKind.page,
    pageIndex: 0,
  ),
  DesktopShortcut(
    id: 'dialog',
    label: 'Dialog Lab',
    arguments: '--tab=dialog',
    icon: Icons.chat_bubble_outline,
    kind: DesktopShortcutKind.page,
    pageIndex: 1,
  ),
  DesktopShortcut(
    id: 'type',
    label: 'Typography',
    arguments: '--tab=type',
    icon: Icons.text_fields,
    kind: DesktopShortcutKind.page,
    pageIndex: 2,
  ),
  DesktopShortcut(
    id: 'grid',
    label: 'Adaptive Grid',
    arguments: '--tab=grid',
    icon: Icons.grid_view,
    kind: DesktopShortcutKind.page,
    pageIndex: 3,
  ),
  DesktopShortcut(
    id: 'controls',
    label: 'Controls',
    arguments: '--tab=controls',
    icon: Icons.tune,
    kind: DesktopShortcutKind.page,
    pageIndex: 4,
  ),
  DesktopShortcut(
    id: 'about',
    label: 'About',
    arguments: '--action=about',
    icon: Icons.info,
    kind: DesktopShortcutKind.about,
  ),
  DesktopShortcut(
    id: 'guide',
    label: 'Guide',
    arguments: '--action=guide',
    icon: Icons.menu_book_outlined,
    kind: DesktopShortcutKind.guide,
  ),
];

final List<DesktopShortcut> _pendingDesktopRequests = <DesktopShortcut>[];

/// Name the desktop shell attributes notifications to.
const String desktopAppName = 'DartFlutterDemo';

/// Desktop entry the Linux notification service attributes notifications to.
const String desktopEntryName = 'io.github.vincentzyuapps.dartflutterdemo';

/// Where a desktop request came from.
///
/// The origin is written to the session log, and it decides whether the request
/// is worth a system notification: a cold start and the automatic page tour only
/// need the in-window feedback.
enum DesktopRequestOrigin {
  /// The command line this process was started with.
  processCommandLine('process-command-line'),

  /// A launch the shell forwarded to the running instance.
  launchArguments('launch-arguments'),

  /// A click on a taskbar hover (thumbnail toolbar) button.
  taskbarCommand('taskbar-command'),

  /// A desktop entry action, which is what a dock click sends on Linux.
  dockAction('dock-action'),

  /// A transport button of the MPRIS media player.
  mpris('mpris'),

  /// The automatic page tour.
  tour('tour');

  const DesktopRequestOrigin(this.wireName);

  /// Stable identifier written to the log.
  final String wireName;
}

/// Controls the optional KDE Wayland focus fallback for tokenless requests.
///
/// `safe` is the default and never attempts to bypass compositor focus policy.
/// The other choices are intentionally command-line opt-ins for a local user.
enum KdeWaylandFocusPolicy {
  safe,
  mpris,
  all;

  static KdeWaylandFocusPolicy fromArguments(List<String> arguments) {
    for (final String argument in arguments) {
      if (argument == '--kde-wayland-focus=mpris') {
        return KdeWaylandFocusPolicy.mpris;
      }
      if (argument == '--kde-wayland-focus=all') {
        return KdeWaylandFocusPolicy.all;
      }
    }
    return KdeWaylandFocusPolicy.safe;
  }
}

/// Origins that report the applied request through a system notification.
const Set<DesktopRequestOrigin> notifyingOrigins = <DesktopRequestOrigin>{
  DesktopRequestOrigin.launchArguments,
  DesktopRequestOrigin.taskbarCommand,
  DesktopRequestOrigin.dockAction,
  DesktopRequestOrigin.mpris,
};

/// Bumped whenever the desktop shell queued a new request.
final ValueNotifier<int> desktopRequestNotifier = ValueNotifier<int>(0);

/// Receives a line per desktop request, wired to the system information log.
void Function(String message)? desktopRequestLogger;

/// Removes and returns the next request queued by the desktop shell.
DesktopShortcut? takePendingDesktopRequest() {
  if (_pendingDesktopRequests.isEmpty) {
    return null;
  }
  return _pendingDesktopRequests.removeAt(0);
}

void _enqueueDesktopRequest(
  DesktopShortcut shortcut, {
  DesktopRequestOrigin origin = DesktopRequestOrigin.tour,
  String? activationToken,
}) {
  _pendingDesktopRequests.add(shortcut);
  desktopRequestNotifier.value++;
  desktopRequestLogger?.call(
    'Desktop request: ${shortcut.id} (${shortcut.arguments}) via '
    '${origin.wireName}',
  );
  if (origin != DesktopRequestOrigin.processCommandLine) {
    unawaited(DesktopIntegrationService.raiseWindow(
      activationToken: activationToken,
      origin: origin,
    ));
  }
  if (notifyingOrigins.contains(origin)) {
    unawaited(DesktopIntegrationService.showShortcutNotification(shortcut));
  }
}

/// Bridges the running window to its taskbar, dock and desktop entry.
///
/// Every capability is optional. Windows drives a jump list plus the taskbar
/// hover toolbar, Linux drives desktop entry activation plus an MPRIS player
/// for supported desktop media controls, and platforms without an
/// implementation keep the plain in-window behaviour.
class DesktopIntegrationService {
  DesktopIntegrationService._();

  /// Edge length of the square MPRIS cover art.
  static const double _artSize = 256;

  /// Radius of the disc behind a cover art glyph, relative to `_artSize`.
  static const double _artDiscRadius = 0.42;

  /// Font size of a cover art glyph, relative to `_artSize`.
  ///
  /// The ink of a Material glyph is roughly 0.72 of its font size, so this
  /// fills a little over half of the disc.
  static const double _artGlyphScale = 0.6;

  /// Disc drawn behind a cover art glyph.
  ///
  /// A cover carries its own background, so unlike the taskbar glyphs it does
  /// not follow the system theme.
  static const Color _artBackgroundColour = Color(0xFF1F1F1F);

  /// Edge length of a taskbar thumbnail toolbar button.
  static const int _toolbarIconSize = 32;

  /// Icon sizes Windows picks between for one jump list entry.
  static const List<int> _jumpListIconSizes = <int>[32, 16];

  /// Cover art of a page whose own cover could not be rendered.
  static const String _fallbackArtAsset = 'assets/images/logo-icon-favicon.png';

  static DesktopActivationClient? _activationClient;
  static MprisBridge? _mprisBridge;
  static DesktopNotifier? _notifier;
  static StreamSubscription<TaskbarEvent>? _taskbarEvents;

  /// Cover art URL of every destination, keyed by shortcut identifier.
  static final Map<String, String> _artUrls = <String, String>{};

  /// Cover art used by a destination that has no rendered cover.
  static String? _fallbackArtUrl;

  static bool _artPrepared = false;
  static KdeWaylandFocusPolicy _kdeWaylandFocusPolicy =
      KdeWaylandFocusPolicy.safe;
  static int _currentPage = 0;
  // MPRIS uses Playing and Paused for a presentation request: Playing means
  // the app asked to be restored, Paused means it asked to be minimized.
  // Wayland can decline a focus request, so this is intentionally not claimed
  // to be a compositor-observed window state.
  static bool _windowPresented = true;
  static bool _shortcutsPublished = false;

  /// Cover art of the page that is currently visible.
  ///
  /// The desktop shells draw their own transport buttons, so the cover is the
  /// only part of the hover preview this application controls.
  static String? get _artUrl =>
      _artUrls[_pageShortcut(_currentPage).id] ?? _fallbackArtUrl;

  /// Finds the shortcut addressed by a command line.
  static DesktopShortcut? matchShortcut(List<String> arguments) {
    for (final String argument in arguments) {
      for (final String token in argument.split(' ')) {
        for (final DesktopShortcut shortcut in desktopShortcuts) {
          if (token == shortcut.arguments) {
            return shortcut;
          }
        }
      }
    }
    return null;
  }

  /// Finds the shortcut with the given [id].
  static DesktopShortcut? shortcutById(String? id) {
    if (id == null) {
      return null;
    }
    for (final DesktopShortcut shortcut in desktopShortcuts) {
      if (shortcut.id == id) {
        return shortcut;
      }
    }
    return null;
  }

  /// Configures the process-local KDE Wayland focus fallback before desktop
  /// activation is claimed. The policy is never inherited by later launches.
  static void configureKdeWaylandFocus(List<String> arguments) {
    _kdeWaylandFocusPolicy = KdeWaylandFocusPolicy.fromArguments(arguments);
  }

  /// Claims the single instance slot and wires the event sources.
  ///
  /// Returns false when another instance already owns the slot and received this
  /// command line, in which case the caller should exit immediately.
  static Future<bool> claimSingleInstance(List<String> arguments) async {
    if (Platform.isWindows) {
      if (!await WindowsDesktopIntegration.acquireSingleInstance()) {
        return false;
      }
      _taskbarEvents =
          WindowsDesktopIntegration.events.listen(_handleTaskbarEvent);
      return true;
    }
    if (Platform.isLinux) {
      final DesktopActivationClient client = DesktopActivationClient();
      final DesktopActivationRole role =
          await client.acquireSingleInstance(arguments: arguments);
      if (role == DesktopActivationRole.secondary) {
        return false;
      }
      _activationClient = client;
      if (role == DesktopActivationRole.primary) {
        client.activations.listen(_handleDesktopActivation);
      }
      return true;
    }
    return true;
  }

  /// Applies a command line, either of this process or of a forwarded launch.
  static void handleLaunchArguments(
    List<String> arguments, {
    DesktopRequestOrigin origin = DesktopRequestOrigin.processCommandLine,
  }) {
    final DesktopShortcut? shortcut = matchShortcut(arguments);
    if (shortcut != null) {
      _enqueueDesktopRequest(shortcut, origin: origin);
    }
  }

  /// Applies a request a later launch of the application forwarded.
  static void _handleDesktopActivation(DesktopActivation activation) {
    final DesktopShortcut? shortcut = matchShortcut(activation.arguments);
    if (shortcut == null) {
      return;
    }
    _enqueueDesktopRequest(
      shortcut,
      origin: DesktopRequestOrigin.dockAction,
      activationToken: activation.activationToken,
    );
  }

  /// Brings the application window back to the front of the desktop.
  ///
  /// Windows raises the window inside the native plugin, right where the shell
  /// message arrives, so only Linux needs the channel call. Both paths are still
  /// routed through here so every origin behaves the same.
  static Future<void> raiseWindow({
    String? activationToken,
    DesktopRequestOrigin origin = DesktopRequestOrigin.processCommandLine,
  }) async {
    if (!Platform.isLinux) {
      return;
    }
    _windowPresented = true;
    await _activationClient?.activateWindow(activationToken: activationToken);
    if (_shouldUseKdeFocusFallback(
      origin: origin,
      activationToken: activationToken,
    )) {
      await _activationClient?.focusWindowWithKWin();
    }
    await _publishNowPlaying();
  }

  static bool _shouldUseKdeFocusFallback({
    required DesktopRequestOrigin origin,
    required String? activationToken,
  }) {
    if (activationToken != null && activationToken.isNotEmpty) {
      return false;
    }
    return switch (_kdeWaylandFocusPolicy) {
      KdeWaylandFocusPolicy.safe => false,
      KdeWaylandFocusPolicy.mpris => origin == DesktopRequestOrigin.mpris,
      KdeWaylandFocusPolicy.all => true,
    };
  }

  /// Asks Linux to minimize the application window.
  ///
  /// This is best effort for the same reason as [raiseWindow]: the compositor
  /// owns final window state. The MPRIS state reflects the request so the
  /// middle media control remains a predictable toggle.
  static Future<void> minimizeWindow() async {
    if (!Platform.isLinux) {
      return;
    }
    _windowPresented = false;
    await _activationClient?.minimizeWindow();
    await _publishNowPlaying();
  }

  /// Reports an applied desktop request through a system notification.
  ///
  /// Best effort on both platforms: Windows draws the shell balloon and Linux
  /// asks the freedesktop notification service, and a desktop that declines the
  /// notification still gets the in-window feedback.
  static Future<bool> showShortcutNotification(DesktopShortcut shortcut) async {
    final String body = 'Opened ${shortcut.label}';
    if (Platform.isWindows) {
      return WindowsDesktopIntegration.showNotification(
        title: desktopAppName,
        body: body,
      );
    }
    if (Platform.isLinux) {
      final DesktopNotifier notifier =
          _notifier ??= DesktopNotifier(desktopEntry: desktopEntryName);
      final String? artUrl = _artUrl;
      return notifier.notify(
        summary: desktopAppName,
        body: body,
        iconPath: artUrl == null ? null : Uri.parse(artUrl).toFilePath(),
      );
    }
    return false;
  }

  /// Publishes every shortcut surface of the current desktop environment.
  static Future<void> publishShortcuts() async {
    if (_shortcutsPublished) {
      return;
    }
    _shortcutsPublished = true;
    if (Platform.isWindows) {
      await _publishJumpList();
      await _publishThumbnailToolbar();
      return;
    }
    if (Platform.isLinux) {
      await _startMprisBridge();
    }
  }

  /// Reports the page that is currently visible.
  static Future<void> setActivePage(int pageIndex) async {
    _currentPage = _wrapPage(pageIndex);
    if (Platform.isWindows) {
      await _publishThumbnailToolbar();
      return;
    }
    if (Platform.isLinux) {
      await _publishNowPlaying();
    }
  }

  /// Re-renders the Windows surfaces for the current system theme.
  ///
  /// Both surfaces switch between a light and a dark glyph, and the jump list
  /// icons carry the theme in their file name so the shell never keeps showing
  /// a cached copy of the other theme.
  static Future<void> refreshToolbar() async {
    if (!_shortcutsPublished || !Platform.isWindows) {
      return;
    }
    await _publishJumpList();
    await _publishThumbnailToolbar();
  }

  /// Releases the desktop resources owned by this process.
  static Future<void> dispose() async {
    _windowPresented = true;
    final StreamSubscription<TaskbarEvent>? taskbarEvents = _taskbarEvents;
    _taskbarEvents = null;
    await taskbarEvents?.cancel();
    final MprisBridge? bridge = _mprisBridge;
    _mprisBridge = null;
    await bridge?.close();
    final DesktopNotifier? notifier = _notifier;
    _notifier = null;
    await notifier?.close();
    final DesktopActivationClient? activationClient = _activationClient;
    _activationClient = null;
    await activationClient?.close();
  }

  /// Registers the jump list of the current theme.
  static Future<void> _publishJumpList() async {
    await WindowsDesktopIntegration.setJumpList(await _jumpListEntries());
  }

  static Future<List<TaskbarEntry>> _jumpListEntries() async {
    final Map<String, String> icons = await _writeJumpListIcons();
    return desktopShortcuts
        .map(
          (DesktopShortcut shortcut) => TaskbarEntry(
            id: shortcut.id,
            label: shortcut.label,
            arguments: shortcut.arguments,
            iconPath: icons[shortcut.id],
          ),
        )
        .toList(growable: false);
  }

  /// Renders the jump list icon of every destination.
  ///
  /// Returns the path of each icon, keyed by shortcut identifier, and omits the
  /// destinations whose icon could not be written.
  ///
  /// Explorer loads the image from the file, so the icons have to be real files
  /// outside the installation directory: a packaged build lives in a read-only
  /// folder behind an access control list Explorer cannot pass, and the assets
  /// of the bundle are not files either. `%LOCALAPPDATA%` is writable for every
  /// installation kind, and it keeps the icons after this process exits, which
  /// matters because the jump list outlives it.
  static Future<Map<String, String>> _writeJumpListIcons() async {
    final Map<String, String> paths = <String, String>{};
    final Directory directory = _jumpListIconDirectory();
    try {
      await directory.create(recursive: true);
    } catch (_) {
      return paths;
    }
    final String theme = _jumpListTheme();
    for (final DesktopShortcut shortcut in desktopShortcuts) {
      try {
        final List<IcoFrame> frames = <IcoFrame>[];
        for (final int size in _jumpListIconSizes) {
          frames.add(
            IcoFrame(
              size: size,
              rgba: await _renderGlyph(shortcut.icon, size),
            ),
          );
        }
        final Uint8List encoded = encodeIco(frames);
        // The digest in the name keeps a new glyph or a new theme from fighting
        // the icon cache of the shell, which keys on the path.
        final File file = File(
          '${directory.path}/${shortcut.id}-$theme-${_fingerprint(encoded)}.ico',
        );
        if (!await file.exists()) {
          await file.writeAsBytes(encoded, flush: true);
        }
        paths[shortcut.id] = file.path;
      } catch (_) {
        // This entry keeps the icon of the executable.
      }
    }
    return paths;
  }

  /// Directory that holds the jump list icons of the current user.
  static Directory _jumpListIconDirectory() {
    final String? localAppData = Platform.environment['LOCALAPPDATA'];
    final String root = localAppData == null || localAppData.isEmpty
        ? Directory.systemTemp.path
        : localAppData;
    return Directory('$root/$desktopAppName/taskbar-icons');
  }

  /// Theme the jump list icons are rendered for.
  static String _jumpListTheme() {
    return ui.PlatformDispatcher.instance.platformBrightness == Brightness.dark
        ? 'dark'
        : 'light';
  }

  static Future<void> _publishThumbnailToolbar() async {
    final List<TaskbarToolbarButton> buttons = <TaskbarToolbarButton>[];
    for (final DesktopShortcut shortcut in desktopShortcuts) {
      buttons.add(
        TaskbarToolbarButton(
          id: shortcut.id,
          label: shortcut.label,
          arguments: shortcut.arguments,
          icon: TaskbarIcon(
            width: _toolbarIconSize,
            height: _toolbarIconSize,
            rgba: await _renderGlyph(shortcut.icon, _toolbarIconSize),
          ),
          enabled: shortcut.pageIndex != _currentPage,
        ),
      );
    }
    await WindowsDesktopIntegration.setThumbnailToolbar(
      buttons,
      activeId: _pageShortcut(_currentPage).id,
    );
  }

  /// Renders a Material glyph into premultiplied RGBA pixels.
  static Future<Uint8List> _renderGlyph(
    IconData icon,
    int size, {
    Color? color,
    double glyphScale = 0.72,
  }) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
    );
    final TextPainter painter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: size * glyphScale,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: color ?? _toolbarGlyphColor(),
        ),
      ),
    )..layout();
    painter.paint(
      canvas,
      Offset((size - painter.width) / 2, (size - painter.height) / 2),
    );
    final ui.Image image = await recorder.endRecording().toImage(size, size);
    final ByteData? data =
        await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    if (data == null) {
      return Uint8List(size * size * 4);
    }
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  /// Glyph colour that stays visible on both taskbar themes.
  static Color _toolbarGlyphColor() {
    return ui.PlatformDispatcher.instance.platformBrightness == Brightness.dark
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF1F1F1F);
  }

  static Future<void> _startMprisBridge() async {
    await _prepareNowPlayingArt();
    final MprisBridge bridge = MprisBridge();
    if (!await bridge.start(initialState: _nowPlayingState())) {
      return;
    }
    final MprisMediaPlayerObject? player = bridge.player;
    if (player != null) {
      player.onNext = () async {
        _enqueueDesktopRequest(
          _pageShortcut(_currentPage + 1),
          origin: DesktopRequestOrigin.mpris,
        );
      };
      player.onPrevious = () async {
        _enqueueDesktopRequest(
          _pageShortcut(_currentPage - 1),
          origin: DesktopRequestOrigin.mpris,
        );
      };
      player.onRaise = () => raiseWindow(origin: DesktopRequestOrigin.mpris);
      player.onPlay = () => raiseWindow(origin: DesktopRequestOrigin.mpris);
      player.onPause = minimizeWindow;
      player.onPlayPause = () =>
          _windowPresented
              ? minimizeWindow()
              : raiseWindow(origin: DesktopRequestOrigin.mpris);
      player.onStop = minimizeWindow;
    }
    _mprisBridge = bridge;
  }

  static Future<void> _publishNowPlaying() async {
    final MprisBridge? bridge = _mprisBridge;
    if (bridge == null) {
      return;
    }
    await bridge.update(_nowPlayingState());
  }

  static NowPlayingState _nowPlayingState() {
    final DesktopShortcut page = _pageShortcut(_currentPage);
    return NowPlayingState(
      title: desktopPageLabels[_currentPage],
      // A page is a track: a new object path makes the shell take the new cover
      // instead of reusing the one it cached for the previous page.
      trackId: '${NowPlayingState.trackIdPrefix}/${page.id}',
      artUrl: _artUrl,
      isPlaying: _windowPresented,
    );
  }

  static DesktopShortcut _pageShortcut(int index) {
    return desktopShortcuts[_wrapPage(index)];
  }

  /// Wraps a page index into `0 .. desktopPageCount - 1`.
  static int _wrapPage(int index) {
    return ((index % desktopPageCount) + desktopPageCount) % desktopPageCount;
  }

  /// Renders and writes the cover art of every destination.
  ///
  /// Desktop shells draw any transport controls themselves, so the cover is
  /// the only part of a media preview this application controls. Giving every
  /// destination its own file also means the shell never has to refresh an
  /// image it already cached under a path.
  static Future<void> _prepareNowPlayingArt() async {
    if (_artPrepared) {
      return;
    }
    _artPrepared = true;
    final Directory directory = Directory(
      '${Directory.systemTemp.path}/dart-flutter-demo/now-playing',
    );
    try {
      await directory.create(recursive: true);
    } catch (_) {
      return;
    }
    for (final DesktopShortcut shortcut in desktopShortcuts) {
      try {
        final Uint8List? encoded = await _renderGlyphArt(shortcut.icon);
        if (encoded == null) {
          continue;
        }
        final File file = File('${directory.path}/${shortcut.id}.png');
        await file.writeAsBytes(encoded, flush: true);
        _artUrls[shortcut.id] = Uri.file(file.path).toString();
      } catch (_) {
        // This destination keeps the fallback cover.
      }
    }
    try {
      final ByteData data = await rootBundle.load(_fallbackArtAsset);
      final File file = File('${directory.path}/app.png');
      await file.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
      _fallbackArtUrl = Uri.file(file.path).toString();
    } catch (_) {
      // Cover art stays empty, which the shells show as a placeholder.
    }
  }

  /// Renders the cover art of one destination as a PNG.
  static Future<Uint8List?> _renderGlyphArt(IconData icon) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(
      recorder,
      const Rect.fromLTWH(0, 0, _artSize, _artSize),
    );
    canvas.drawCircle(
      const Offset(_artSize / 2, _artSize / 2),
      _artSize * _artDiscRadius,
      Paint()..color = _artBackgroundColour,
    );
    final TextPainter painter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: _artSize * _artGlyphScale,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: const Color(0xFFFFFFFF),
        ),
      ),
    )..layout();
    painter.paint(
      canvas,
      Offset((_artSize - painter.width) / 2, (_artSize - painter.height) / 2),
    );
    final ui.Image image = await recorder
        .endRecording()
        .toImage(_artSize.toInt(), _artSize.toInt());
    final ByteData? data =
        await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (data == null) {
      return null;
    }
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  static void _handleTaskbarEvent(TaskbarEvent event) {
    switch (event.type) {
      case TaskbarEventType.command:
        final DesktopShortcut? shortcut = shortcutById(event.commandId);
        if (shortcut != null) {
          _enqueueDesktopRequest(
            shortcut,
            origin: DesktopRequestOrigin.taskbarCommand,
          );
        }
        break;
      case TaskbarEventType.launch:
        handleLaunchArguments(
          event.arguments,
          origin: DesktopRequestOrigin.launchArguments,
        );
        break;
    }
  }
}

/// Short stable digest that keeps icon file names unique per rendered glyph.
///
/// The shell caches an icon by its path, so a glyph change has to produce a new
/// name, and a name that only depends on the bytes keeps a re-render from
/// writing the same image again.
String _fingerprint(Uint8List bytes) {
  int hash = 0x811c9dc5;
  for (final int byte in bytes) {
    hash ^= byte;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}
