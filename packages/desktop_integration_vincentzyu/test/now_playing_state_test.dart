import 'package:desktop_integration_vincentzyu/desktop_integration_vincentzyu.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NowPlayingState', () {
    test('maps a page to MPRIS metadata', () {
      const state = NowPlayingState(
        title: '3. Adaptive Grid',
        artUrl: 'file:///tmp/page.png',
        length: Duration(seconds: 5),
        position: Duration(milliseconds: 2500),
        isPlaying: true,
      );

      final metadata = state.toMetadata();

      expect(metadata['xesam:title']!.asString(), '3. Adaptive Grid');
      expect(metadata['xesam:album']!.asString(), 'Pages');
      expect(metadata['xesam:artist']!.asStringArray(), <String>[
        'Dart + Flutter Demo',
      ]);
      expect(metadata['mpris:length']!.asInt64(), 5000000);
      expect(metadata['mpris:artUrl']!.asString(), 'file:///tmp/page.png');
      expect(
        metadata['mpris:trackid']!.asObjectPath().value,
        NowPlayingState.defaultTrackId,
      );
      expect(state.playbackStatus, 'Playing');
    });

    test('omits cover art and stays paused without a page preview', () {
      const state = NowPlayingState(title: 'Idle');

      expect(state.toMetadata().containsKey('mpris:artUrl'), isFalse);
      expect(state.playbackStatus, 'Paused');
    });

    test('copyWith keeps untouched fields', () {
      const state = NowPlayingState(title: 'System Info', isPlaying: true);

      final copy = state.copyWith(title: 'Dialog Lab');

      expect(copy.title, 'Dialog Lab');
      expect(copy.isPlaying, isTrue);
      expect(copy.artist, state.artist);
      expect(copy.album, state.album);
    });
  });
}
