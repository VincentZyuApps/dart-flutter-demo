import 'dart:async';

import 'package:dbus/dbus.dart';

/// Session bus name owned by the primary instance of the application.
const String defaultActivationBusName = 'io.github.vincentzyuapps.dartflutterdemo';

/// Object path that serves [activationInterfaceName].
const String defaultActivationObjectPath =
    '/io/github/vincentzyuapps/DartFlutterDemo';

/// Interface used to forward launch arguments to the primary instance.
const String activationInterfaceName =
    'io.github.vincentzyuapps.DartFlutterDemo.Activation';

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
  final StreamController<List<String>> _activations =
      StreamController<List<String>>.broadcast();

  DBusClient? _bus;
  bool _ownsBusName = false;
  bool _closed = false;

  /// Arguments forwarded by later launches. Empty for the initial launch.
  Stream<List<String>> get activations => _activations.stream;

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
              onArguments: _activations.add,
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
        values: <DBusValue>[DBusArray.string(arguments)],
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

/// Serves `Activate(as)` on the session bus.
class ActivationObject extends DBusObject {
  ActivationObject(super.path, {required this.onArguments});

  /// Callback invoked with the arguments of a later launch.
  final void Function(List<String> arguments) onArguments;

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
    if (methodCall.values.length != 1) {
      return DBusMethodErrorResponse.invalidArgs('Expected one argument array.');
    }
    onArguments(
      methodCall.values.single.asStringArray().toList(growable: false),
    );
    return DBusMethodSuccessResponse();
  }
}
