import 'package:dbus/dbus.dart';

/// Bus name of the freedesktop desktop notification service.
const String notificationBusName = 'org.freedesktop.Notifications';

/// Object path that serves [notificationInterfaceName].
const String notificationObjectPath = '/org/freedesktop/Notifications';

/// Interface of the freedesktop desktop notification service.
const String notificationInterfaceName = 'org.freedesktop.Notifications';

/// Publishes desktop notifications through the freedesktop notification service.
///
/// Both target desktops implement the same specification: Plasma draws the
/// banner in the corner of its notification applet and GNOME Shell draws it at
/// the top centre of the primary monitor, so a single `Notify` call covers the
/// Linux desktops this application ships for.
class DesktopNotifier {
  DesktopNotifier({
    DBusClient? client,
    this.desktopEntry = 'io.github.vincentzyuapps.dartflutterdemo',
  }) : _injectedClient = client;

  /// Desktop entry basename used to attribute the notification.
  final String desktopEntry;

  final DBusClient? _injectedClient;

  DBusClient? _bus;
  bool _closed = false;
  int _replacesId = 0;

  /// True once a notification reached the desktop environment.
  ///
  /// Never throws: a desktop without a notification service simply returns
  /// false and the caller keeps its in-window feedback.
  Future<bool> notify({
    required String summary,
    String body = '',
    String? iconPath,
    int timeoutMs = 5000,
    bool replaceExisting = true,
  }) async {
    if (_closed) {
      return false;
    }
    try {
      final DBusClient bus = _injectedClient ?? (_bus ??= DBusClient.session());
      final DBusMethodSuccessResponse response = await bus.callMethod(
        destination: notificationBusName,
        path: DBusObjectPath(notificationObjectPath),
        interface: notificationInterfaceName,
        name: 'Notify',
        values: <DBusValue>[
          DBusString(desktopEntry),
          DBusUint32(replaceExisting ? _replacesId : 0),
          DBusString(iconPath ?? ''),
          DBusString(summary),
          DBusString(body),
          DBusArray.string(const <String>[]),
          DBusDict.stringVariant(<String, DBusValue>{
            'desktop-entry': DBusString(desktopEntry),
          }),
          DBusInt32(timeoutMs),
        ],
      );
      for (final DBusValue value in response.returnValues) {
        if (value is DBusUint32) {
          // A fresh notification still becomes the replacement target of a
          // subsequent burst, without suppressing the next distinct action.
          _replacesId = value.value;
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Closes the session bus connection owned by this notifier.
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    final DBusClient? bus = _bus;
    _bus = null;
    if (bus != null) {
      try {
        await bus.close();
      } catch (_) {
        // Closing an already closed bus is not an error for callers.
      }
    }
  }
}
