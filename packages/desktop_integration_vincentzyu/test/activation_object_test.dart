import 'package:dbus/dbus.dart';
import 'package:desktop_integration_vincentzyu/desktop_integration_vincentzyu.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ActivationObject', () {
    test('forwards launch arguments to the callback', () async {
      final forwarded = <List<String>>[];
      final object = ActivationObject(
        DBusObjectPath(defaultActivationObjectPath),
        onArguments: forwarded.add,
      );

      final response = await object.handleMethodCall(
        DBusMethodCall(
          sender: ':1.9',
          interface: activationInterfaceName,
          name: 'Activate',
          values: <DBusValue>[
            DBusArray.string(<String>['--tab=grid']),
          ],
        ),
      );

      expect(response, isA<DBusMethodSuccessResponse>());
      expect(forwarded, <List<String>>[
        <String>['--tab=grid'],
      ]);
    });

    test('rejects calls on other interfaces and malformed payloads', () async {
      final object = ActivationObject(
        DBusObjectPath(defaultActivationObjectPath),
        onArguments: (_) {},
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
        onArguments: (_) {},
      );

      final interfaces = object.introspect();

      expect(interfaces.single.name, activationInterfaceName);
      expect(interfaces.single.methods.single.name, 'Activate');
    });
  });
}
