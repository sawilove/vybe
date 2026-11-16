import '../core/models.dart';
import 'music_source.dart';

/// SoundCloud via its v2 API, with a client ID the user provides
/// (see docs/SOURCES.md). VYBE does not ship or scrape a client ID.
class SoundCloudSource extends MusicSource {
  SoundCloudSource(this.clientId, {JsonApi? api}) : _api = api ?? JsonApi();

  final String Function() clientId;
  final JsonApi _api;
  static const _host = 'api-v2.soundcloud.com';

  @override
  SourceKind get kind => SourceKind.soundcloud;

  @override
  bool get isConfigured => clientId().isNotEmpty;

  Uri _uri(String path, [Map<String, String> q = const {}]) => Uri.https(_host, path, {...q, 'client_id': clientId()});

  @override
  Future<List<Track>> search(String query) async {
    if (!isConfigured || query.trim().isEmpty) return const [];
    final data = await _api.get(_uri('/search/tracks', {'q': query.trim(), 'limit': '30'}));
    return parseTracks((data as Map)['collection'] as List? ?? const []);
  }

  @override
  Future<ResolvedStream> resolveStream(Track track) async {
    var t = track;
    if (t.isLazy) {
      final hits = await search(t.query!);
      if (hits.isEmpty) throw SourceException('Not found on SoundCloud: ${t.query}');
      t = hits.first;
    }
    final info = await _api.get(_uri('/tracks/${t.id}')) as Map;
    final transcodings = ((info['media'] as Map?)?['transcodings'] as List? ?? const []).cast<Map<String, dynamic>>();
    // Prefer progressive MP3 (plays everywhere and can be cached), fall back to HLS.
    Map<String, dynamic>? pick(String protocol) =>
        transcodings.where((x) => (x['format'] as Map?)?['protocol'] == protocol && x['snipped'] != true).firstOrNull;
    final chosen = pick('progressive') ?? pick('hls');
    if (chosen == null) throw SourceException('SoundCloud: no stream for $t');
    final auth = info['track_authorization'] as String?;
    final res = await _api.get(
      Uri.parse(chosen['url'] as String)
          .replace(queryParameters: {'client_id': clientId(), 'track_authorization': ?auth}),
    ) as Map;
    return ResolvedStream(Uri.parse(res['url'] as String), track: t);
  }

  @override
  Future<List<Track>> related(Track track) async {
    if (track.isLazy) return search(track.query!);
    final data = await _api.get(_uri('/tracks/${track.id}/related', {'limit': '30'}));
    return parseTracks((data as Map)['collection'] as List? ?? const []);
  }

  static List<Track> parseTracks(List<dynamic> list) => [
    for (final t in list.cast<Map<String, dynamic>>())
      if (t['kind'] == null || t['kind'] == 'track')
        Track(
          id: '${t['id']}',
          title: (t['title'] as String? ?? '').trim(),
          artist:
              (((t['publisher_metadata'] as Map?)?['artist'] as String?) ??
                      ((t['user'] as Map?)?['username'] as String?) ??
                      '')
                  .trim(),
          source: SourceKind.soundcloud,
          duration: t['duration'] == null ? null : Duration(milliseconds: t['duration'] as int),
          artworkUrl: (t['artwork_url'] as String?)?.replaceAll('-large.', '-t500x500.'),
        ),
  ];
}
