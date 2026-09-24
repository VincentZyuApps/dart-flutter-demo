import 'dart:async';
import 'dart:io';

import 'package:dbus/dbus.dart';
import 'package:flutter/services.dart';

/// Session bus name owned by the primary instance of the application.
const String defaultActivationBusName =
    'io.github.vincentzyuapps.dartflutterdemo';

/// Object path that serves [activationInterfaceName].
const String defaultActivationObjectPath =
    '/io/github/vincentzyuapps/DartFlutterDemo';

/// Interface used to forward launch arguments to the primary instance.
const String activationInterfaceName =
    'io.github.vincentzyuapps.DartFlutterDemo.Activation';

/// Method channel served by the Linux plugin of this package.
const String desktopIntegrationMethodChannel =
    'linux_desktop_integration_vincentzyu/methods';

const String _kWinBusName = 'org.kde.KWin';
const String _kWinScriptingPath = '/Scripting';
const String _kWinScriptingInterface = 'org.kde.kwin.Scripting';
/// Environment variables a desktop shell uses to hand out an activation token.
///
/// Wayland launchers export `XDG_ACTIVATION_TOKEN`, while X11 startup
/// notification keeps the X server timestamp in `DESKTOP_STARTUP_ID`.
const List<String> activationTokenVariables = <String>[
  'XDG_ACTIVATION_TOKEN',
  'DESKTOP_STARTUP_ID',
];

/// Reads the activation token a desktop shell passed to this launch.
///
/// Returns null when the launch carried no token, which is the case for a plain
/// terminal invocation.
String? activationTokenFromEnvironment([Map<String, String>? environment]) {
  final Map<String, String> values = environment ?? Platform.environment;
  for (final String name in activationTokenVariables) {
    final String? value = values[name];
    if (value != null && value.isNotEmpty) {
      return value;
    }
  }
  return null;
}

/// Whether [environment] describes a KDE Plasma Wayland session.
///
/// This deliberately requires both parts: an X11 session and GNOME's Wayland
/// session must keep using their native activation behaviour.
bool isKdeWaylandSession([Map<String, String>? environment]) {
  final Map<String, String> values = environment ?? Platform.environment;
  final String desktop = (values['XDG_CURRENT_DESKTOP'] ?? '').toLowerCase();
  return values['WAYLAND_DISPLAY']?.isNotEmpty == true &&
      (desktop.contains('kde') || desktop.contains('plasma'));
}

/// One desktop request delivered by a later launch of the application.
class DesktopActivation {
  const DesktopActivation({required this.arguments, this.activationToken});

  /// Command line of the launch that asked for this activation.
  final List<String> arguments;

  /// Token the desktop shell handed to that launch, if it handed out one.
  ///
  /// Only the process that owns the window can replay the token, which is why it
  /// travels over the session bus together with the arguments.
  final String? activationToken;
}

/// Outcome of the single instance handshake.
enum DesktopActivationRole {
  /// This process owns the activation bus name and should keep running.
  primary,

  /// Another process owns the bus name and already received our arguments.
  secondary,

  /// No usable session bus was found, so the caller should run as usual.
  unavailable,
}

/// Coordinates single instance activation through the session bus.
///
/// Desktop entry actions and jump lists normally start a new process. The first
/// process keeps [busName] and serves `Activate(as)`; every later process sends
/// its own arguments to that method and exits, so the running window handles the
/// request in place.
class DesktopActivationClient {
  DesktopActivationClient({
    DBusClient? client,
    this.busName = defaultActivationBusName,
    this.objectPath = defaultActivationObjectPath,
  }) : _injectedClient = client;

  /// Bus name claimed by the primary instance.
  final String busName;

  /// Object path that serves [activationInterfaceName].
  final String objectPath;

  final DBusClient? _injectedClient;
  final StreamController<DesktopActivation> _activations =
      StreamController<DesktopActivation>.broadcast();

  static const MethodChannel _methods = MethodChannel(
    desktopIntegrationMethodChannel,
  );

  DBusClient? _bus;
  bool _ownsBusName = false;
  bool _closed = false;

  /// Arguments forwarded by later launches. Empty for the initial launch.
  Stream<DesktopActivation> get activations => _activations.stream;

  /// True when this process owns [busName].
  bool get ownsBusName => _ownsBusName;

  /// Claims [busName], or forwards [arguments] to the process that owns it.
  ///
  /// Never throws: when the session bus is missing the result is
  /// [DesktopActivationRole.unavailable] and the caller keeps running.
  Future<DesktopActivationRole> acquireSingleInstance({
    List<String> arguments = const <String>[],
  }) async {
    try {
      final DBusClient bus = _injectedClient ?? DBusClient.session();
      _bus = bus;
      final DBusRequestNameReply reply = await bus.requestName(busName);
      switch (reply) {
        case DBusRequestNameReply.primaryOwner:
        case DBusRequestNameReply.alreadyOwner:
          _ownsBusName = true;
          await bus.registerObject(
            ActivationObject(
              DBusObjectPath(objectPath),
              onActivation: _activations.add,
            ),
          );
          return DesktopActivationRole.primary;
        case DBusRequestNameReply.inQueue:
        case DBusRequestNameReply.exists:
          await _handOver(bus, arguments);
          return DesktopActivationRole.secondary;
      }
    } catch (_) {
      return DesktopActivationRole.unavailable;
    }
  }

  Future<void> _handOver(DBusClient bus, List<String> arguments) async {
    try {
      await bus.callMethod(
        destination: busName,
        path: DBusObjectPath(objectPath),
        interface: activationInterfaceName,
        name: 'Activate',
        values: <DBusValue>[
          DBusArray.string(arguments),
          DBusString(activationTokenFromEnvironment() ?? ''),
        ],
      );
    } catch (_) {
      // The primary instance may be shutting down; exiting is still correct.
    }
    try {
      await bus.releaseName(busName);
    } catch (_) {
      // Releasing a queued name can fail when the owner already exited.
    }
    await close();
  }

  /// Asks the desktop environment to raise the window of this process.
  ///
  /// [activationToken] is the token of the request that is being applied, which
  /// lets the window manager verify that the raise answers a user action.
  /// Returns false when no Linux plugin is registered or the raise was refused.
  Future<bool> activateWindow({String? activationToken}) async {
    if (_closed) {
      return false;
    }
    try {
      final bool? raised = await _methods.invokeMethod<bool>(
        'activateWindow',
        <String, Object?>{'startupNotificationId': activationToken},
      );
      return raised ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  /// Asks the desktop environment to minimize this process window.
  ///
  /// Returns false when no Linux plugin is registered or the window manager
  /// declines the request.
  Future<bool> minimizeWindow() async {
    if (_closed) {
      return false;
    }
    try {
      final bool? minimized = await _methods.invokeMethod<bool>(
        'minimizeWindow',
      );
      return minimized ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  /// Uses a short-lived KWin script to activate this application's window.
  ///
  /// KWin normally rejects focus requests without an activation token. This is
  /// therefore not called by default: the app layer exposes it only behind an
  /// explicit `--kde-wayland-focus` opt-in. It is unavailable outside KDE
  /// Wayland and safely returns false when KWin Scripting is disabled.
  Future<bool> focusWindowWithKWin() async {
    if (_closed || !isKdeWaylandSession() || _bus == null) {
      return false;
    }
    final String? runtimeRoot = Platform.environment['XDG_RUNTIME_DIR'];
    if (runtimeRoot == null || runtimeRoot.isEmpty) {
      return false;
    }
    final Directory scriptDirectory = Directory(
      '$runtimeRoot${Platform.pathSeparator}dart_flutter_demo',
    );
    final String suffix = DateTime.now().microsecondsSinceEpoch.toString();
    final String scriptName = 'dart_flutter_demo_focus_$suffix';
    final File script = File(
      '${scriptDirectory.path}${Platform.pathSeparator}$scriptName.js',
    );
    var scriptLoaded = false;
    try {
      await scriptDirectory.create(recursive: true);
      await script.writeAsString(_kWinFocusScript, flush: true);
      final ProcessResult permission = await Process.run(
        'chmod',
        <String>['600', script.path],
      );
      if (permission.exitCode != 0) {
        return false;
      }
      final DBusMethodSuccessResponse loaded = await _bus!.callMethod(
        destination: _kWinBusName,
        path: DBusObjectPath(_kWinScriptingPath),
        interface: _kWinScriptingInterface,
        name: 'loadScript',
        values: <DBusValue>[DBusString(script.path), DBusString(scriptName)],
      );
      if (loaded.returnValues.length != 1) {
        return false;
      }
      final DBusValue value = loaded.returnValues.single;
      if (value is! DBusInt32 || value.value < 0) {
        return false;
      }
      scriptLoaded = true;
      await _bus!.callMethod(
        destination: _kWinBusName,
        path: DBusObjectPath(_kWinScriptingPath),
        interface: _kWinScriptingInterface,
        name: 'start',
        values: const <DBusValue>[],
      );
      return true;
    } catch (_) {
      return false;
    } finally {
      if (scriptLoaded) {
        try {
          await _bus!.callMethod(
            destination: _kWinBusName,
            path: DBusObjectPath(_kWinScriptingPath),
            interface: _kWinScriptingInterface,
            name: 'unloadScript',
            values: <DBusValue>[DBusString(scriptName)],
          );
        } catch (_) {
          // The one-shot script may already be gone when KWin disconnects.
        }
      }
      try {
        await script.delete();
      } on FileSystemException {
        // A failed cleanup must not turn an optional focus request into an app
        // failure. The runtime directory is removed at logout in any case.
      }
    }
  }

  /// Releases the bus name and closes the session bus connection.
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    await _activations.close();
    final DBusClient? bus = _bus;
    if (bus != null) {
      try {
        await bus.close();
      } catch (_) {
        // Closing an already closed bus is not an error for callers.
      }
    }
  }
}

const String _kWinFocusScript = '''
const targetIds = [
  'io.github.vincentzyuapps.dartflutterdemo',
  'dart_flutter_demo',
  'dart-flutter-demo',
];
const target = workspace.windowList().find((window) =>
  targetIds.includes(window.resourceClass) || targetIds.includes(window.resourceName)
);
if (target) {
  workspace.activeWindow = target;
}
''';

/// Serves `Activate(as, s)` on the session bus.
class ActivationObject extends DBusObject {
  ActivationObject(super.path, {required this.onActivation});

  /// Callback invoked with the request of a later launch.
  final void Function(DesktopActivation activation) onActivation;

  @override
  List<DBusIntrospectInterface> introspect() {
    return <DBusIntrospectInterface>[
      DBusIntrospectInterface(
        activationInterfaceName,
        methods: <DBusIntrospectMethod>[
          DBusIntrospectMethod(
            'Activate',
            args: <DBusIntrospectArgument>[
              DBusIntrospectArgument(
                DBusSignature('as'),
                DBusArgumentDirection.in_,
                name: 'arguments',
              ),
              DBusIntrospectArgument(
                DBusSignature('s'),
                DBusArgumentDirection.in_,
                name: 'activationToken',
              ),
            ],
          ),
        ],
      ),
    ];
  }

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    if (methodCall.interface != activationInterfaceName) {
      return DBusMethodErrorResponse.unknownInterface();
    }
    if (methodCall.name != 'Activate') {
      return DBusMethodErrorResponse.unknownMethod();
    }
    if (methodCall.values.length != 2) {
      return DBusMethodErrorResponse.invalidArgs(
        'Expected an argument array and an activation token.',
      );
    }
    final String token = methodCall.values[1].asString();
    onActivation(
      DesktopActivation(
        arguments: methodCall.values[0].asStringArray().toList(growable: false),
        activationToken: token.isEmpty ? null : token,
      ),
    );
    return DBusMethodSuccessResponse();
  }
}
