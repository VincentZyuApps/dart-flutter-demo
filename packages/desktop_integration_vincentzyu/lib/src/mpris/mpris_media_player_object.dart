import 'package:dbus/dbus.dart';

import 'now_playing_state.dart';

/// MPRIS object exposed at `/org/mpris/MediaPlayer2`.
///
/// KDE Plasma reads these properties to render the taskbar hover tooltip
/// (cover art, title, transport buttons) and GNOME Shell lists them in its media
/// controls. This object is the only supported way for a non-native toolkit to
/// put content into a desktop environment hover preview.
class MprisMediaPlayerObject extends DBusObject {
  MprisMediaPlayerObject({
    this.identity = 'Dart + Flutter Demo',
    this.desktopEntry = 'io.github.vincentzyuapps.dartflutterdemo',
    this.canRaise = true,
    NowPlayingState? state,
  })  : _state = state ?? const NowPlayingState(title: 'Dart + Flutter Demo'),
        super(DBusObjectPath('/org/mpris/MediaPlayer2'));

  /// Object path that desktop environments probe for MPRIS players.
  static const String objectPath = '/org/mpris/MediaPlayer2';

  /// Root MPRIS interface.
  static const String rootInterface = 'org.mpris.MediaPlayer2';

  /// Player MPRIS interface.
  static const String playerInterface = 'org.mpris.MediaPlayer2.Player';

  /// Human readable player name.
  final String identity;

  /// Desktop entry basename, used by desktop environments to match this player
  /// with the application window and its taskbar button.
  final String desktopEntry;

  /// Whether the desktop environment may raise the application.
  final bool canRaise;

  /// Invoked when the desktop environment asks for the next page.
  Future<void> Function()? onNext;

  /// Invoked when the desktop environment asks for the previous page.
  Future<void> Function()? onPrevious;

  /// Invoked when the desktop environment toggles between play and pause.
  Future<void> Function()? onPlayPause;

  /// Invoked when the desktop environment starts playing.
  Future<void> Function()? onPlay;

  /// Invoked when the desktop environment pauses.
  Future<void> Function()? onPause;

  /// Invoked when the desktop environment stops playback.
  Future<void> Function()? onStop;

  /// Invoked when the desktop environment raises the application.
  Future<void> Function()? onRaise;

  NowPlayingState _state;
  String _loopStatus = 'None';
  bool _shuffle = false;
  double _volume = 1;

  /// Currently published state.
  NowPlayingState get state => _state;

  /// Replaces the published state and emits `PropertiesChanged`.
  Future<void> updateState(NowPlayingState state) async {
    _state = state;
    await emitPropertiesChanged(
      playerInterface,
      changedProperties: <String, DBusValue>{
        'Metadata': _metadata(),
        'PlaybackStatus': DBusString(_state.playbackStatus),
      },
    );
  }

  /// Emits the MPRIS `Seeked` signal.
  Future<void> emitSeeked(Duration position) async {
    await emitSignal(playerInterface, 'Seeked', <DBusValue>[
      DBusInt64(position.inMicroseconds),
    ]);
  }

  @override
  List<DBusIntrospectInterface> introspect() {
    return <DBusIntrospectInterface>[
      DBusIntrospectInterface(
        rootInterface,
        methods: <DBusIntrospectMethod>[
          DBusIntrospectMethod('Raise'),
          DBusIntrospectMethod('Quit'),
        ],
        properties: <DBusIntrospectProperty>[
          _property('CanQuit', 'b', DBusPropertyAccess.read),
          _property('CanRaise', 'b', DBusPropertyAccess.read),
          _property('HasTrackList', 'b', DBusPropertyAccess.read),
          _property('Identity', 's', DBusPropertyAccess.read),
          _property('DesktopEntry', 's', DBusPropertyAccess.read),
          _property('SupportedUriSchemes', 'as', DBusPropertyAccess.read),
          _property('SupportedMimeTypes', 'as', DBusPropertyAccess.read),
        ],
      ),
      DBusIntrospectInterface(
        playerInterface,
        methods: <DBusIntrospectMethod>[
          DBusIntrospectMethod('Next'),
          DBusIntrospectMethod('Previous'),
          DBusIntrospectMethod('Pause'),
          DBusIntrospectMethod('PlayPause'),
          DBusIntrospectMethod('Stop'),
          DBusIntrospectMethod('Play'),
          DBusIntrospectMethod('Seek', args: <DBusIntrospectArgument>[
            DBusIntrospectArgument(
              DBusSignature('x'),
              DBusArgumentDirection.in_,
              name: 'Offset',
            ),
          ]),
          DBusIntrospectMethod('SetPosition', args: <DBusIntrospectArgument>[
            DBusIntrospectArgument(
              DBusSignature('o'),
              DBusArgumentDirection.in_,
              name: 'TrackId',
            ),
            DBusIntrospectArgument(
              DBusSignature('x'),
              DBusArgumentDirection.in_,
              name: 'Position',
            ),
          ]),
          DBusIntrospectMethod('OpenUri', args: <DBusIntrospectArgument>[
            DBusIntrospectArgument(
              DBusSignature('s'),
              DBusArgumentDirection.in_,
              name: 'Uri',
            ),
          ]),
        ],
        signals: <DBusIntrospectSignal>[
          DBusIntrospectSignal('Seeked', args: <DBusIntrospectArgument>[
            DBusIntrospectArgument(
              DBusSignature('x'),
              DBusArgumentDirection.out,
              name: 'Position',
            ),
          ]),
        ],
        properties: <DBusIntrospectProperty>[
          _property('PlaybackStatus', 's', DBusPropertyAccess.read),
          _property('LoopStatus', 's', DBusPropertyAccess.readwrite),
          _property('Rate', 'd', DBusPropertyAccess.readwrite),
          _property('Shuffle', 'b', DBusPropertyAccess.readwrite),
          _property('Metadata', 'a{sv}', DBusPropertyAccess.read),
          _property('Volume', 'd', DBusPropertyAccess.readwrite),
          _property('Position', 'x', DBusPropertyAccess.read),
          _property('MinimumRate', 'd', DBusPropertyAccess.read),
          _property('MaximumRate', 'd', DBusPropertyAccess.read),
          _property('CanGoNext', 'b', DBusPropertyAccess.read),
          _property('CanGoPrevious', 'b', DBusPropertyAccess.read),
          _property('CanPlay', 'b', DBusPropertyAccess.read),
          _property('CanPause', 'b', DBusPropertyAccess.read),
          _property('CanSeek', 'b', DBusPropertyAccess.read),
          _property('CanControl', 'b', DBusPropertyAccess.read),
        ],
      ),
    ];
  }

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    if (methodCall.interface == rootInterface) {
      switch (methodCall.name) {
        case 'Raise':
          await onRaise?.call();
          return DBusMethodSuccessResponse();
        case 'Quit':
          return DBusMethodErrorResponse.notSupported(
            'Quit is not supported; close the window instead.',
          );
      }
      return DBusMethodErrorResponse.unknownMethod();
    }

    if (methodCall.interface == playerInterface) {
      switch (methodCall.name) {
        case 'Next':
          await onNext?.call();
          return DBusMethodSuccessResponse();
        case 'Previous':
          await onPrevious?.call();
          return DBusMethodSuccessResponse();
        case 'Play':
          await onPlay?.call();
          return DBusMethodSuccessResponse();
        case 'Pause':
          await onPause?.call();
          return DBusMethodSuccessResponse();
        case 'PlayPause':
          await onPlayPause?.call();
          return DBusMethodSuccessResponse();
        case 'Stop':
          await onStop?.call();
          return DBusMethodSuccessResponse();
        case 'Seek':
        case 'SetPosition':
        case 'OpenUri':
          return DBusMethodErrorResponse.notSupported(
            'This player only maps pages, not media streams.',
          );
      }
      return DBusMethodErrorResponse.unknownMethod();
    }

    return DBusMethodErrorResponse.unknownInterface();
  }

  @override
  Future<DBusMethodResponse> getProperty(String interface, String name) async {
    if (!_isKnownInterface(interface)) {
      return DBusMethodErrorResponse.unknownInterface();
    }
    final DBusValue? value = _propertyValue(interface, name);
    if (value == null) {
      return DBusMethodErrorResponse.unknownProperty();
    }
    return DBusGetPropertyResponse(DBusVariant(value));
  }

  @override
  Future<DBusMethodResponse> setProperty(
    String interface,
    String name,
    DBusValue value,
  ) async {
    if (!_isKnownInterface(interface)) {
      return DBusMethodErrorResponse.unknownInterface();
    }
    if (interface != playerInterface) {
      return DBusMethodErrorResponse.propertyReadOnly();
    }
    switch (name) {
      case 'Volume':
        _volume = value.asDouble();
        return DBusMethodSuccessResponse();
      case 'LoopStatus':
        _loopStatus = value.asString();
        return DBusMethodSuccessResponse();
      case 'Shuffle':
        _shuffle = value.asBoolean();
        return DBusMethodSuccessResponse();
    }
    return DBusMethodErrorResponse.propertyReadOnly();
  }

  @override
  Future<DBusMethodResponse> getAllProperties(String interface) async {
    if (!_isKnownInterface(interface)) {
      return DBusMethodErrorResponse.unknownInterface();
    }
    return DBusGetAllPropertiesResponse(
      interface == rootInterface ? _rootProperties() : _playerProperties(),
    );
  }

  static DBusIntrospectProperty _property(
    String name,
    String type,
    DBusPropertyAccess access,
  ) {
    return DBusIntrospectProperty(name, DBusSignature(type), access: access);
  }

  bool _isKnownInterface(String interface) =>
      interface == rootInterface || interface == playerInterface;

  DBusValue? _propertyValue(String interface, String name) {
    if (interface == rootInterface) {
      return _rootProperties()[name];
    }
    return _playerProperties()[name];
  }

  Map<String, DBusValue> _rootProperties() {
    return <String, DBusValue>{
      'CanQuit': DBusBoolean(false),
      'CanRaise': DBusBoolean(canRaise),
      'HasTrackList': DBusBoolean(false),
      'Identity': DBusString(identity),
      'DesktopEntry': DBusString(desktopEntry),
      'SupportedUriSchemes': DBusArray.string(const <String>[]),
      'SupportedMimeTypes': DBusArray.string(const <String>[]),
    };
  }

  Map<String, DBusValue> _playerProperties() {
    return <String, DBusValue>{
      'PlaybackStatus': DBusString(_state.playbackStatus),
      'LoopStatus': DBusString(_loopStatus),
      'Rate': const DBusDouble(1),
      'Shuffle': DBusBoolean(_shuffle),
      'Metadata': _metadata(),
      'Volume': DBusDouble(_volume),
      'Position': DBusInt64(_state.position.inMicroseconds),
      'MinimumRate': const DBusDouble(1),
      'MaximumRate': const DBusDouble(1),
      'CanGoNext': DBusBoolean(true),
      'CanGoPrevious': DBusBoolean(true),
      'CanPlay': DBusBoolean(true),
      'CanPause': DBusBoolean(true),
      'CanSeek': DBusBoolean(false),
      'CanControl': DBusBoolean(true),
    };
  }

  DBusValue _metadata() => DBusDict.stringVariant(_state.toMetadata());
}
