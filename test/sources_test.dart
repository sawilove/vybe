import 'package:flutter_test/flutter_test.dart';
import 'package:vybe/core/models.dart';
import 'package:vybe/sources/audius_source.dart';
import 'package:vybe/sources/soundcloud_source.dart';
import 'package:vybe/sources/source_registry.dart';
import 'package:vybe/sources/vk_source.dart';
import 'package:vybe/sources/yandex_source.dart';

Track t(SourceKind k, String id) => Track(id: id, title: 't$id', artist: 'a', source: k);

void main() {
  test('Audius parser skips non-streamable and overly long tracks', () {
    final tracks = AudiusSource.parseTracks({
      'data': [
        {
          'id': 'a1',
          'title': 'Stars ',
          'user': {'name': 'Lofi'},
          'duration': 180,
          'is_streamable': true,
          'artwork': {'480x480': 'https://x/art.jpg'},
        },
        {
          'id': 'a2',
          'title': 'Nope',
          'user': {'name': 'X'},
          'duration': 180,
          'is_streamable': false,
        },
        {
          'id': 'a3',
          'title': 'Mix',
          'user': {'name': 'X'},
          'duration': 4000,
          'is_streamable': true,
        },
      ],
    });
    expect(tracks.map((e) => e.id), ['a1']);
    expect(tracks.single.title, 'Stars');
    expect(tracks.single.artist, 'Lofi');
    expect(tracks.single.artworkUrl, 'https://x/art.jpg');
  });

  test('Yandex parser joins artists and builds cover URLs', () {
    final tracks = YandexSource.parseTracks([
      {
        'id': 123,
        'title': 'Too Sweet',
        'artists': [
          {'name': 'Hozier'},
          {'name': 'Guest'},
        ],
        'durationMs': 251000,
        'coverUri': 'avatars.yandex.net/get-music-content/x/%%',
      },
      {'id': 124, 'title': 'Gone', 'artists': [], 'available': false},
    ]);
    expect(tracks, hasLength(1));
    expect(tracks.single.id, '123');
    expect(tracks.single.artist, 'Hozier, Guest');
    expect(tracks.single.duration, const Duration(seconds: 251));
    expect(tracks.single.artworkUrl, 'https://avatars.yandex.net/get-music-content/x/400x400');
  });

  test('VK parser uses owner_id_id addressing', () {
    final tracks = VkSource.parseTracks([
      {
        'id': 456,
        'owner_id': -2001,
        'artist': 'Artist',
        'title': 'Song',
        'duration': 200,
        'album': {
          'thumb': {'photo_300': 'https://vk/300.jpg'},
        },
      },
    ]);
    expect(tracks.single.id, '-2001_456');
    expect(tracks.single.artworkUrl, 'https://vk/300.jpg');
  });

  test('VK source is inactive without a token', () {
    expect(VkSource(() => '', () => '').isConfigured, isFalse);
    expect(VkSource(() => 'tok', () => '').isConfigured, isTrue);
  });

  test('SoundCloud parser prefers publisher artist and large artwork', () {
    final tracks = SoundCloudSource.parseTracks([
      {
        'kind': 'track',
        'id': 9,
        'title': 'Remix',
        'duration': 180000,
        'user': {'username': 'uploader'},
        'publisher_metadata': {'artist': 'Real Artist'},
        'artwork_url': 'https://i1.sndcdn.com/artworks-x-large.jpg',
      },
      {'kind': 'playlist', 'id': 10},
    ]);
    expect(tracks.single.artist, 'Real Artist');
    expect(tracks.single.artworkUrl, 'https://i1.sndcdn.com/artworks-x-t500x500.jpg');
  });

  test('SearchResults.all puts local first and interleaves the rest', () {
    final r = SearchResults({
      SourceKind.youtube: [t(SourceKind.youtube, 'y1'), t(SourceKind.youtube, 'y2')],
      SourceKind.audius: [t(SourceKind.audius, 'a1')],
      SourceKind.local: [t(SourceKind.local, 'l1')],
    }, const {});
    expect(r.all.map((e) => e.id), ['l1', 'y1', 'a1', 'y2']);
  });
}
