import 'package:dbus/dbus.dart';
import 'package:flutter/services.dart';
import 'package:linux_desktop_integration_vincentzyu/linux_desktop_integration_vincentzyu.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DesktopActivationClient window methods', () {
    const channel = MethodChannel(desktopIntegrationMethodChannel);
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    tearDown(() {
      messenger.setMockMethodCallHandler(channel, null);
    });

    test('forwards a minimize request to the Linux plugin', () async {
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(channel, (MethodCall call) async {
        calls.add(call);
        return true;
      });

      final client = DesktopActivationClient();

      expect(await client.minimizeWindow(), isTrue);
      expect(calls, hasLength(1));
      expect(calls.single.method, 'minimizeWindow');
      expect(calls.single.arguments, isNull);
      await client.close();
    });

    test('treats a missing native window plugin as a failed request', () async {
      final client = DesktopActivationClient();

      expect(await client.minimizeWindow(), isFalse);
      await client.close();
    });
  });

  group('ActivationObject', () {
    test('forwards the launch arguments and the activation token', () async {
      final forwarded = <DesktopActivation>[];
      final object = ActivationObject(
        DBusObjectPath(defaultActivationObjectPath),
        onActivation: forwarded.add,
      );

      final response = await object.handleMethodCall(
        DBusMethodCall(
          sender: ':1.9',
          interface: activationInterfaceName,
          name: 'Activate',
          values: <DBusValue>[
            DBusArray.string(<String>['--tab=grid']),
            DBusString('token-42'),
          ],
        ),
      );

      expect(response, isA<DBusMethodSuccessResponse>());
      expect(forwarded, hasLength(1));
      expect(forwarded.single.arguments, <String>['--tab=grid']);
      expect(forwarded.single.activationToken, 'token-42');
    });

    test('reports an empty activation token as absent', () async {
      final forwarded = <DesktopActivation>[];
      final object = ActivationObject(
        DBusObjectPath(defaultActivationObjectPath),
        onActivation: forwarded.add,
      );

      await object.handleMethodCall(
        DBusMethodCall(
          sender: ':1.9',
          interface: activationInterfaceName,
          name: 'Activate',
          values: <DBusValue>[
            DBusArray.string(<String>['--action=about']),
            DBusString(''),
          ],
        ),
      );

      expect(forwarded.single.arguments, <String>['--action=about']);
      expect(forwarded.single.activationToken, isNull);
    });

    test('rejects calls on other interfaces and malformed payloads', () async {
      final object = ActivationObject(
        DBusObjectPath(defaultActivationObjectPath),
        onActivation: (_) {},
      );

      final unknownInterface = await object.handleMethodCall(
        const DBusMethodCall(
          sender: ':1.9',
          interface: 'com.example.Unknown',
          name: 'Activate',
        ),
      );
      final invalidArgs = await object.handleMethodCall(
        const DBusMethodCall(
          sender: ':1.9',
          interface: activationInterfaceName,
          name: 'Activate',
        ),
      );

      expect(
        (unknownInterface as DBusMethodErrorResponse).errorName,
        'org.freedesktop.DBus.Error.UnknownInterface',
      );
      expect(
        (invalidArgs as DBusMethodErrorResponse).errorName,
        'org.freedesktop.DBus.Error.InvalidArgs',
      );
    });

    test('introspection describes the Activate method', () {
      final object = ActivationObject(
        DBusObjectPath(defaultActivationObjectPath),
        onActivation: (_) {},
      );

      final interfaces = object.introspect();

      expect(interfaces.single.name, activationInterfaceName);
      expect(interfaces.single.methods.single.name, 'Activate');
      expect(interfaces.single.methods.single.args, hasLength(2));
    });
  });

  group('activationTokenFromEnvironment', () {
    test('prefers the Wayland token and falls back to the X11 startup id', () {
      expect(
        activationTokenFromEnvironment(<String, String>{
          'XDG_ACTIVATION_TOKEN': 'wayland-token',
          'DESKTOP_STARTUP_ID': 'demo_TIME1234',
        }),
        'wayland-token',
      );
      expect(
        activationTokenFromEnvironment(<String, String>{
          'DESKTOP_STARTUP_ID': 'demo_TIME1234',
        }),
        'demo_TIME1234',
      );
    });

    test('reports no token for a plain invocation', () {
      expect(activationTokenFromEnvironment(<String, String>{}), isNull);
      expect(
        activationTokenFromEnvironment(<String, String>{
          'XDG_ACTIVATION_TOKEN': '',
        }),
        isNull,
      );
    });
  });

  group('isKdeWaylandSession', () {
    test('requires both a KDE desktop and Wayland', () {
      expect(
        isKdeWaylandSession(<String, String>{
          'XDG_CURRENT_DESKTOP': 'KDE',
          'WAYLAND_DISPLAY': 'wayland-0',
        }),
        isTrue,
      );
      expect(
        isKdeWaylandSession(<String, String>{
          'XDG_CURRENT_DESKTOP': 'GNOME',
          'WAYLAND_DISPLAY': 'wayland-0',
        }),
        isFalse,
      );
      expect(
        isKdeWaylandSession(<String, String>{
          'XDG_CURRENT_DESKTOP': 'KDE',
        }),
        isFalse,
      );
    });
  });
}
