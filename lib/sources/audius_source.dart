import '../core/models.dart';
import 'music_source.dart';

/// Audius: an open, artist-owned catalogue with a free public API.
/// Full tracks, no account needed. https://docs.audius.org
class AudiusSource extends MusicSource {
  AudiusSource({JsonApi? api}) : _api = api ?? JsonApi();

  final JsonApi _api;
  static const _host = 'api.audius.co';
  static const _app = 'VYBE';

  @override
  SourceKind get kind => SourceKind.audius;

  Uri _uri(String path, [Map<String, String> q = const {}]) => Uri.https(_host, '/v1$path', {...q, 'app_name': _app});

  @override
  Future<List<Track>> search(String query) async {
    if (query.trim().isEmpty) return const [];
    final data = await _api.get(_uri('/tracks/search', {'query': query.trim()}));
    return parseTracks(data);
  }

  @override
  Future<ResolvedStream> resolveStream(Track track) async {
    var t = track;
    if (t.isLazy) {
      final hits = await search(t.query!);
      if (hits.isEmpty) throw SourceException('Not found on Audius: ${t.query}');
      t = hits.first;
    }
    // The API redirects to a signed URL on a content node.
    return ResolvedStream(_uri('/tracks/${t.id}/stream'), track: t);
  }

  @override
  Future<List<Track>> related(Track track) async {
    // Audius has no "related" endpoint: mix the artist's other tracks with search.
    final byArtist = await search(track.artist);
    return byArtist.where((t) => t.id != track.id).toList();
  }

  static List<Track> parseTracks(dynamic data) {
    final list = (data is Map ? data['data'] : null) as List? ?? const [];
    return [
      for (final t in list.cast<Map<String, dynamic>>())
        if (t['is_streamable'] != false && (t['duration'] as num? ?? 0) > 30 && (t['duration'] as num? ?? 0) < 1200)
          Track(
            id: t['id'] as String,
            title: (t['title'] as String? ?? '').trim(),
            artist: ((t['user'] as Map?)?['name'] as String? ?? '').trim(),
            source: SourceKind.audius,
            duration: Duration(seconds: (t['duration'] as num).round()),
            artworkUrl: (t['artwork'] as Map?)?['480x480'] as String?,
          ),
    ];
  }
}
