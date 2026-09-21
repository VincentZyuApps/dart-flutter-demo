import 'package:dbus/dbus.dart';

/// Track shown by desktop environments for the current application page.
class NowPlayingState {
  const NowPlayingState({
    required this.title,
    this.artist = 'Dart + Flutter Demo',
    this.album = 'Pages',
    this.artUrl,
    this.length = const Duration(seconds: 4),
    this.position = Duration.zero,
    this.isPlaying = false,
    this.trackId = defaultTrackId,
  });

  /// Object path prefix of every track this application publishes.
  ///
  /// Desktops cache the cover art of a track object, so an application that
  /// swaps the artwork has to name the new item with a new path.
  static const String trackIdPrefix =
      '/io/github/vincentzyuapps/DartFlutterDemo/track';

  /// Stable MPRIS track object path used when the item never changes.
  static const String defaultTrackId = '$trackIdPrefix/current';

  /// Track title, mapped from the current page name.
  final String title;

  /// Artist line, defaults to the application name.
  final String artist;

  /// Album line, defaults to the page collection name.
  final String album;

  /// `file://` or `http(s)://` URL of the cover art, if any.
  final String? artUrl;

  /// Track length, used by the desktop hover tooltip progress bar.
  final Duration length;

  /// Current position inside [length].
  final Duration position;

  /// Whether the application is "playing", that is auto advancing pages.
  final bool isPlaying;

  /// MPRIS track object path.
  final String trackId;

  /// `PlaybackStatus` value required by MPRIS.
  String get playbackStatus => isPlaying ? 'Playing' : 'Paused';

  /// Builds the MPRIS `Metadata` dictionary.
  Map<String, DBusValue> toMetadata() {
    return <String, DBusValue>{
      'mpris:trackid': DBusObjectPath(trackId),
      'mpris:length': DBusInt64(length.inMicroseconds),
      'xesam:title': DBusString(title),
      'xesam:artist': DBusArray.string(<String>[artist]),
      'xesam:album': DBusString(album),
      if (artUrl != null) 'mpris:artUrl': DBusString(artUrl!),
    };
  }

  /// Returns a copy with the given fields replaced.
  NowPlayingState copyWith({
    String? title,
    String? artist,
    String? album,
    String? artUrl,
    Duration? length,
    Duration? position,
    bool? isPlaying,
    String? trackId,
  }) {
    return NowPlayingState(
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      artUrl: artUrl ?? this.artUrl,
      length: length ?? this.length,
      position: position ?? this.position,
      isPlaying: isPlaying ?? this.isPlaying,
      trackId: trackId ?? this.trackId,
    );
  }
}
