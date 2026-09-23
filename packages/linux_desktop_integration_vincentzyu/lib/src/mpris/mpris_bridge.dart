import 'package:dbus/dbus.dart';

import 'mpris_media_player_object.dart';
import 'now_playing_state.dart';

/// Session bus name used for the MPRIS player.
const String defaultMprisBusName = 'org.mpris.MediaPlayer2.dartflutterdemo';

/// Publishes MPRIS state for desktop media controls.
class MprisBridge {
  MprisBridge({
    DBusClient? client,
    this.busName = defaultMprisBusName,
    this.identity = 'Dart + Flutter Demo',
    this.desktopEntry = 'io.github.vincentzyuapps.dartflutterdemo',
  }) : _injectedClient = client;

  /// Bus name for this player.
  final String busName;

  /// Player name shown by desktop environments.
  final String identity;

  /// Desktop entry basename used to match the player with the window.
  final String desktopEntry;

  final DBusClient? _injectedClient;

  DBusClient? _bus;
  MprisMediaPlayerObject? _player;
  bool _running = false;

  /// True when the player object is registered on the session bus.
  bool get isRunning => _running;

  /// The registered MPRIS object, or null before [start] succeeds.
  MprisMediaPlayerObject? get player => _player;

  /// Claims [busName] and registers the MPRIS object.
  ///
  /// Returns false when the name is taken or no session bus is reachable. The
  /// caller should keep running either way.
  Future<bool> start({NowPlayingState? initialState}) async {
    try {
      final DBusClient bus = _injectedClient ?? DBusClient.session();
      _bus = bus;
      final DBusRequestNameReply reply = await bus.requestName(busName);
      if (reply != DBusRequestNameReply.primaryOwner &&
          reply != DBusRequestNameReply.alreadyOwner) {
        return false;
      }
      final MprisMediaPlayerObject player = MprisMediaPlayerObject(
        identity: identity,
        desktopEntry: desktopEntry,
        state: initialState,
      );
      await bus.registerObject(player);
      _player = player;
      _running = true;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Publishes [state] to the desktop environment.
  Future<void> update(NowPlayingState state) async {
    await _player?.updateState(state);
  }

  /// Releases the bus name and closes the connection.
  Future<void> close() async {
    if (!_running) {
      return;
    }
    _running = false;
    final DBusClient? bus = _bus;
    _player = null;
    if (bus != null) {
      try {
        await bus.close();
      } catch (_) {
        // Ignore: the session bus may already be gone.
      }
    }
  }
}
