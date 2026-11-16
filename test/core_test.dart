import 'package:flutter_test/flutter_test.dart';
import 'package:vybe/core/format.dart';
import 'package:vybe/core/models.dart';
import 'package:vybe/recommendations/recommendation_service.dart';
import 'package:vybe/sources/local_source.dart';
import 'package:vybe/sources/youtube_source.dart';

Track yt(String id, String artist, [String? title]) =>
    Track(id: id, title: title ?? 'Song $id', artist: artist, source: SourceKind.youtube);

void main() {
  group('YouTubeSource.parseTitle', () {
    test('splits "Artist - Title" and strips noise', () {
      expect(
        YouTubeSource.parseTitle('Teddy Swims - Lose Control (Official Music Video)', 'TeddySwimsVEVO'),
        ('Teddy Swims', 'Lose Control'),
      );
      expect(
        YouTubeSource.parseTitle('Hozier – Too Sweet [Official Audio] | New 2024', 'Hozier'),
        ('Hozier', 'Too Sweet'),
      );
    });

    test('falls back to channel name without " - Topic" / VEVO', () {
      expect(YouTubeSource.parseTitle('Beautiful Things', 'Benson Boone - Topic'), ('Benson Boone', 'Beautiful Things'));
      expect(YouTubeSource.parseTitle('Lose Control (Lyrics)', 'TeddySwimsVEVO'), ('TeddySwims', 'Lose Control'));
    });
  });

  test('LocalSource.trackFromPath parses "Artist - Title.ext"', () {
    final t = LocalSource.trackFromPath('/music/Hozier - Too Sweet.mp3');
    expect(t.artist, 'Hozier');
    expect(t.title, 'Too Sweet');
    expect(t.source, SourceKind.local);
    expect(LocalSource.trackFromPath('/music/untitled.flac').title, 'untitled');
  });

  test('Track JSON round-trip, including lazy tracks', () {
    const lazy = Track(id: '', title: 'Too Sweet', artist: 'Hozier', source: SourceKind.youtube, query: 'Hozier - Too Sweet');
    final full = yt('abc', 'Hozier').copyWith(duration: const Duration(seconds: 251), artworkUrl: 'https://x/y.jpg');
    for (final t in [lazy, full]) {
      final back = Track.fromJson(t.toJson());
      expect(back.key, t.key);
      expect(back.duration, t.duration);
      expect(back.artworkUrl, t.artworkUrl);
    }
    expect(lazy.isLazy, isTrue);
  });

  group('RecommendationService.rank', () {
    test('tracks suggested by several seeds rank first', () {
      final a = yt('a', 'A'), b = yt('b', 'B'), c = yt('c', 'C');
      final ranked = RecommendationService.rank([
        [a, b],
        [c, b],
      ]);
      expect(ranked.first, b);
      expect(ranked.toSet(), {a, b, c});
    });

    test('drops excluded (recently played) tracks', () {
      final a = yt('a', 'A'), b = yt('b', 'B');
      expect(RecommendationService.rank([[a, b]], exclude: {a.key}), [b]);
    });

    test('caps tracks per artist and avoids the same artist twice in a row', () {
      final list = [yt('1', 'X'), yt('2', 'X'), yt('3', 'X'), yt('4', 'Y'), yt('5', 'Z')];
      final ranked = RecommendationService.rank([list], perArtist: 2);
      expect(ranked.where((t) => t.artist == 'X').length, 2);
      for (var i = 1; i < ranked.length; i++) {
        expect(ranked[i].artist == ranked[i - 1].artist, isFalse, reason: '$ranked');
      }
    });

    test('merges a lazy Last.fm track with the concrete YouTube one', () {
      const lazy = Track(id: '', title: 'Too Sweet', artist: 'Hozier', source: SourceKind.youtube, query: 'Hozier - Too Sweet');
      final concrete = yt('vid', 'Hozier', 'Too Sweet');
      final ranked = RecommendationService.rank([
        [lazy],
        [concrete],
      ]);
      expect(ranked, hasLength(1));
      expect(ranked.single.isLazy, isFalse);
    });
  });

  test('YouTubeSource.parseDuration', () {
    expect(YouTubeSource.parseDuration('4:09'), const Duration(minutes: 4, seconds: 9));
    expect(YouTubeSource.parseDuration('1:02:03'), const Duration(hours: 1, minutes: 2, seconds: 3));
    expect(YouTubeSource.parseDuration('LIVE'), isNull);
    expect(YouTubeSource.parseDuration(''), isNull);
  });

  test('formatDuration', () {
    expect(formatDuration(const Duration(minutes: 3, seconds: 5)), '3:05');
    expect(formatDuration(const Duration(hours: 1, minutes: 2, seconds: 3)), '1:02:03');
  });
}
