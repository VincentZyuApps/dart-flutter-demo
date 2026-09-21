import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:desktop_integration_vincentzyu/desktop_integration_vincentzyu.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taskbar_integration_vincentzyu/taskbar_integration_vincentzyu.dart';

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

/// Page titles used by hover previews and MPRIS metadata.
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
    unawaited(TaskbarIntegrationService.raiseWindow(
      activationToken: activationToken,
    ));
  }
  if (notifyingOrigins.contains(origin)) {
    unawaited(TaskbarIntegrationService.showShortcutNotification(shortcut));
  }
}

/// Bridges the running window to its taskbar, dock and desktop entry.
///
/// Every capability is optional. Windows drives a jump list plus the taskbar
/// hover toolbar, Linux drives desktop entry activation plus an MPRIS player
/// that Plasma renders inside its taskbar tooltip, and platforms without an
/// implementation keep the plain in-window behaviour.
class TaskbarIntegrationService {
  TaskbarIntegrationService._();

  /// One MPRIS track covers one page.
  static const Duration pageDuration = Duration(seconds: 4);

  static const Duration _tourTick = Duration(seconds: 1);

  static DesktopActivationClient? _activationClient;
  static MprisBridge? _mprisBridge;
  static DesktopNotifier? _notifier;
  static StreamSubscription<TaskbarEvent>? _taskbarEvents;
  static Timer? _tourTimer;
  static String? _artUrl;
  static int _currentPage = 0;
  static bool _tourRunning = false;
  static Duration _tourPosition = Duration.zero;
  static bool _shortcutsPublished = false;

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

  /// True while the page tour advances automatically.
  static bool get isTourRunning => _tourRunning;

  /// Claims the single instance slot and wires the event sources.
  ///
  /// Returns false when another instance already owns the slot and received this
  /// command line, in which case the caller should exit immediately.
  static Future<bool> claimSingleInstance(List<String> arguments) async {
    if (Platform.isWindows) {
      if (!await TaskbarIntegration.acquireSingleInstance()) {
        return false;
      }
      _taskbarEvents = TaskbarIntegration.events.listen(_handleTaskbarEvent);
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
  static Future<void> raiseWindow({String? activationToken}) async {
    if (!Platform.isLinux) {
      return;
    }
    await _activationClient?.activateWindow(activationToken: activationToken);
  }

  /// Reports an applied desktop request through a system notification.
  ///
  /// Best effort on both platforms: Windows draws the shell balloon and Linux
  /// asks the freedesktop notification service, and a desktop that declines the
  /// notification still gets the in-window feedback.
  static Future<bool> showShortcutNotification(DesktopShortcut shortcut) async {
    final String body = 'Opened ${shortcut.label}';
    if (Platform.isWindows) {
      return TaskbarIntegration.showNotification(
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
      await TaskbarIntegration.setJumpList(_jumpListEntries());
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
    _tourPosition = Duration.zero;
    if (Platform.isWindows) {
      await _publishThumbnailToolbar();
      return;
    }
    if (Platform.isLinux) {
      await _publishNowPlaying();
    }
  }

  /// Starts or stops the automatic page tour.
  static Future<void> setTourRunning(bool running) async {
    _tourRunning = running;
    _tourTimer?.cancel();
    _tourTimer = null;
    if (running) {
      _tourPosition = Duration.zero;
      _tourTimer = Timer.periodic(_tourTick, (_) => _advanceTour());
    }
    await _publishNowPlaying();
  }

  /// Re-renders the taskbar toolbar for the current system theme.
  static Future<void> refreshToolbar() async {
    if (!_shortcutsPublished || !Platform.isWindows) {
      return;
    }
    await _publishThumbnailToolbar();
  }

  /// Releases the desktop resources owned by this process.
  static Future<void> dispose() async {
    _tourTimer?.cancel();
    _tourTimer = null;
    _tourRunning = false;
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

  static List<TaskbarEntry> _jumpListEntries() {
    return desktopShortcuts
        .map(
          (DesktopShortcut shortcut) => TaskbarEntry(
            id: shortcut.id,
            label: shortcut.label,
            arguments: shortcut.arguments,
          ),
        )
        .toList(growable: false);
  }

  static Future<void> _publishThumbnailToolbar() async {
    final List<TaskbarToolbarButton> buttons = <TaskbarToolbarButton>[];
    for (final DesktopShortcut shortcut in desktopShortcuts) {
      buttons.add(
        TaskbarToolbarButton(
          id: shortcut.id,
          label: shortcut.label,
          arguments: shortcut.arguments,
          icon: await _renderToolbarIcon(shortcut.icon),
          enabled: shortcut.pageIndex != _currentPage,
        ),
      );
    }
    await TaskbarIntegration.setThumbnailToolbar(
      buttons,
      activeId: _pageShortcut(_currentPage).id,
    );
  }

  /// Renders a Material glyph into premultiplied RGBA pixels.
  static Future<TaskbarIcon> _renderToolbarIcon(
    IconData icon, {
    int size = 32,
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
          fontSize: size * 0.72,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: _toolbarGlyphColor(),
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
      return TaskbarIcon(width: 1, height: 1, rgba: Uint8List(4));
    }
    return TaskbarIcon(
      width: size,
      height: size,
      rgba: data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
  }

  /// Glyph colour that stays visible on both taskbar themes.
  static Color _toolbarGlyphColor() {
    return ui.PlatformDispatcher.instance.platformBrightness == Brightness.dark
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF1F1F1F);
  }

  static Future<void> _startMprisBridge() async {
    _artUrl ??= await _writeNowPlayingArt();
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
      player.onPlay = () => setTourRunning(true);
      player.onPause = () => setTourRunning(false);
      player.onPlayPause = () => setTourRunning(!_tourRunning);
      player.onStop = () async {
        await setTourRunning(false);
        _enqueueDesktopRequest(
          _pageShortcut(0),
          origin: DesktopRequestOrigin.mpris,
        );
      };
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
    return NowPlayingState(
      title: desktopPageLabels[_currentPage],
      artUrl: _artUrl,
      length: pageDuration,
      position: _tourPosition,
      isPlaying: _tourRunning,
    );
  }

  static void _advanceTour() {
    if (!_tourRunning) {
      return;
    }
    _tourPosition += _tourTick;
    if (_tourPosition >= pageDuration) {
      _tourPosition = Duration.zero;
      _enqueueDesktopRequest(_pageShortcut(_currentPage + 1));
    }
    unawaited(_publishNowPlaying());
  }

  static DesktopShortcut _pageShortcut(int index) {
    return desktopShortcuts[_wrapPage(index)];
  }

  /// Wraps a page index into `0 .. desktopPageCount - 1`.
  static int _wrapPage(int index) {
    return ((index % desktopPageCount) + desktopPageCount) % desktopPageCount;
  }

  /// Writes the app logo to a temporary file so MPRIS can publish `artUrl`.
  static Future<String?> _writeNowPlayingArt() async {
    try {
      final ByteData data =
          await rootBundle.load('assets/images/logo-icon-favicon.png');
      final Directory directory =
          Directory('${Directory.systemTemp.path}/dart-flutter-demo');
      await directory.create(recursive: true);
      final File file = File('${directory.path}/now-playing.png');
      await file.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
      return Uri.file(file.path).toString();
    } catch (_) {
      return null;
    }
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
