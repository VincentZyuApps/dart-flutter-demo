import 'package:dbus/dbus.dart';
import 'package:desktop_integration_vincentzyu/desktop_integration_vincentzyu.dart';
import 'package:flutter_test/flutter_test.dart';

DBusMethodCall _call(String interface, String name, [List<DBusValue> values = const []]) {
  return DBusMethodCall(
    sender: ':1.7',
    interface: interface,
    name: name,
    values: values,
  );
}

Future<DBusValue> _readProperty(
  MprisMediaPlayerObject player,
  String interface,
  String name,
) async {
  final response =
      await player.getProperty(interface, name) as DBusGetPropertyResponse;
  return response.values.single.asVariant();
}

String _errorName(DBusMethodResponse response) =>
    (response as DBusMethodErrorResponse).errorName;

void main() {
  const rootInterface = MprisMediaPlayerObject.rootInterface;
  const playerInterface = MprisMediaPlayerObject.playerInterface;

  group('MprisMediaPlayerObject properties', () {
    test('publishes identity, desktop entry, and playback state', () async {
      final player = MprisMediaPlayerObject(
        desktopEntry: 'io.github.vincentzyuapps.dartflutterdemo',
      );

      expect(
        (await _readProperty(player, rootInterface, 'Identity')).asString(),
        'Dart + Flutter Demo',
      );
      expect(
        (await _readProperty(player, rootInterface, 'DesktopEntry')).asString(),
        'io.github.vincentzyuapps.dartflutterdemo',
      );
      expect(
        (await _readProperty(player, rootInterface, 'CanQuit')).asBoolean(),
        isFalse,
      );
      expect(
        (await _readProperty(player, playerInterface, 'PlaybackStatus'))
            .asString(),
        'Paused',
      );
      expect(
        (await _readProperty(player, playerInterface, 'CanSeek')).asBoolean(),
        isFalse,
      );
      expect(
        (await _readProperty(player, playerInterface, 'CanGoNext')).asBoolean(),
        isTrue,
      );
    });

    test('exposes metadata for the current page', () async {
      final player = MprisMediaPlayerObject(
        state: const NowPlayingState(title: '4. Controls', isPlaying: true),
      );

      final metadata = (await _readProperty(player, playerInterface, 'Metadata'))
          .asStringVariantDict();
      final status =
          (await _readProperty(player, playerInterface, 'PlaybackStatus'))
              .asString();

      expect(metadata['xesam:title']!.asString(), '4. Controls');
      expect(status, 'Playing');
    });

    test('reports unknown interfaces and properties', () async {
      final player = MprisMediaPlayerObject();

      expect(
        _errorName(await player.getProperty('com.example.Unknown', 'Identity')),
        'org.freedesktop.DBus.Error.UnknownInterface',
      );
      expect(
        _errorName(await player.getProperty(rootInterface, 'Missing')),
        'org.freedesktop.DBus.Error.UnknownProperty',
      );
      expect(
        _errorName(
          await player.setProperty(
            rootInterface,
            'CanQuit',
            const DBusBoolean(true),
          ),
        ),
        'org.freedesktop.DBus.Error.PropertyReadOnly',
      );
    });

    test('accepts writable player properties', () async {
      final player = MprisMediaPlayerObject();

      final volume = await player.setProperty(
        playerInterface,
        'Volume',
        const DBusDouble(0.25),
      );
      final playback = await player.setProperty(
        playerInterface,
        'PlaybackStatus',
        const DBusString('Playing'),
      );

      expect(volume, isA<DBusMethodSuccessResponse>());
      expect(
        _errorName(playback),
        'org.freedesktop.DBus.Error.PropertyReadOnly',
      );
    });

    test('returns every property through GetAll', () async {
      final player = MprisMediaPlayerObject();

      final root = await player.getAllProperties(rootInterface)
          as DBusGetAllPropertiesResponse;
      final playerProperties = await player.getAllProperties(playerInterface)
          as DBusGetAllPropertiesResponse;

      final rootValues = root.values.single.asStringVariantDict();
      final playerValues = playerProperties.values.single.asStringVariantDict();

      expect(rootValues.keys, contains('DesktopEntry'));
      expect(playerValues.keys, contains('CanControl'));
      expect(playerValues.keys, contains('Metadata'));
    });
  });

  group('MprisMediaPlayerObject methods', () {
    test('routes transport calls to handlers', () async {
      final player = MprisMediaPlayerObject();
      final calls = <String>[];
      player.onNext = () async => calls.add('next');
      player.onPrevious = () async => calls.add('previous');
      player.onPlayPause = () async => calls.add('playPause');
      player.onPlay = () async => calls.add('play');
      player.onPause = () async => calls.add('pause');
      player.onStop = () async => calls.add('stop');
      player.onRaise = () async => calls.add('raise');

      expect(
        await player.handleMethodCall(_call(playerInterface, 'Next')),
        isA<DBusMethodSuccessResponse>(),
      );
      await player.handleMethodCall(_call(playerInterface, 'Previous'));
      await player.handleMethodCall(_call(playerInterface, 'PlayPause'));
      await player.handleMethodCall(_call(playerInterface, 'Play'));
      await player.handleMethodCall(_call(playerInterface, 'Pause'));
      await player.handleMethodCall(_call(playerInterface, 'Stop'));
      await player.handleMethodCall(_call(rootInterface, 'Raise'));

      expect(calls, <String>[
        'next',
        'previous',
        'playPause',
        'play',
        'pause',
        'stop',
        'raise',
      ]);
    });

    test('rejects unsupported and unknown calls', () async {
      final player = MprisMediaPlayerObject();

      expect(
        _errorName(await player.handleMethodCall(_call(rootInterface, 'Quit'))),
        'org.freedesktop.DBus.Error.NotSupported',
      );
      expect(
        _errorName(
          await player.handleMethodCall(
            _call(playerInterface, 'OpenUri', <DBusValue>[
              const DBusString('file:///tmp/page.png'),
            ]),
          ),
        ),
        'org.freedesktop.DBus.Error.NotSupported',
      );
      expect(
        _errorName(
          await player.handleMethodCall(_call(playerInterface, 'Missing')),
        ),
        'org.freedesktop.DBus.Error.UnknownMethod',
      );
      expect(
        _errorName(
          await player.handleMethodCall(_call('com.example.Unknown', 'Next')),
        ),
        'org.freedesktop.DBus.Error.UnknownInterface',
      );
    });

    test('introspection covers both MPRIS interfaces', () {
      final player = MprisMediaPlayerObject();
      final interfaces = player.introspect().map((i) => i.name).toList();

      expect(interfaces, <String>[rootInterface, playerInterface]);
    });
  });
}
