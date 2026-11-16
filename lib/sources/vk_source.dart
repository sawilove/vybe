import '../core/models.dart';
import 'music_source.dart';

/// VK music via the audio API, with the user's own access token.
///
/// VK closed its audio API to third-party apps, so an audio-capable token has
/// to be issued for one of VK's whitelisted clients (see docs/SOURCES.md).
/// VYBE never asks for the VK password; the user pastes a token they obtained
/// themselves, plus the User-Agent of the client the token belongs to.
class VkSource extends MusicSource {
  VkSource(this.token, this.userAgent, {JsonApi? api}) : _api = api ?? JsonApi();

  final String Function() token;
  final String Function() userAgent;
  final JsonApi _api;

  static const _version = '5.131';

  /// A Kate Mobile User-Agent, the most common client for audio tokens.
  static const defaultUserAgent =
      'KateMobileAndroid/56 lite-460 (Android 4.4.2; SDK 19; x86; unknown Android SDK built for x86; en)';

  @override
  SourceKind get kind => SourceKind.vk;

  @override
  bool get isConfigured => token().isNotEmpty;

  Future<dynamic> _call(String method, Map<String, String> params) async {
    final ua = userAgent().isEmpty ? defaultUserAgent : userAgent();
    final data = await _api.get(
      Uri.https('api.vk.com', '/method/$method', {...params, 'access_token': token(), 'v': _version}),
      headers: {'User-Agent': ua},
    ) as Map;
    final error = data['error'] as Map?;
    if (error != null) throw SourceException('VK: ${error['error_msg']}');
    return data['response'];
  }

  @override
  Future<List<Track>> search(String query) async {
    if (!isConfigured || query.trim().isEmpty) return const [];
    final r = await _call('audio.search', {'q': query.trim(), 'count': '30', 'auto_complete': '1'});
    return parseTracks((r as Map)['items'] as List? ?? const []);
  }

  @override
  Future<ResolvedStream> resolveStream(Track track) async {
    var t = track;
    if (t.isLazy) {
      final hits = await search(t.query!);
      if (hits.isEmpty) throw SourceException('Not found on VK: ${t.query}');
      t = hits.first;
    }
    final r = await _call('audio.getById', {'audios': t.id});
    final items = parseRaw(r as List? ?? const []);
    final url = items.firstOrNull?['url'] as String? ?? '';
    if (url.isEmpty) throw SourceException('VK did not return a link for $t');
    return ResolvedStream(Uri.parse(url), track: t);
  }

  @override
  Future<List<Track>> related(Track track) async {
    if (track.isLazy) return search(track.query!);
    final r = await _call('audio.getRecommendations', {'target_audio': track.id, 'count': '30'});
    return parseTracks((r as Map)['items'] as List? ?? const []);
  }

  static List<Map<String, dynamic>> parseRaw(List<dynamic> items) => items.cast<Map<String, dynamic>>();

  static List<Track> parseTracks(List<dynamic> items) => [
    for (final a in parseRaw(items))
      Track(
        // VK addresses audios as "<owner_id>_<id>".
        id: '${a['owner_id']}_${a['id']}',
        title: (a['title'] as String? ?? '').trim(),
        artist: (a['artist'] as String? ?? '').trim(),
        source: SourceKind.vk,
        duration: a['duration'] == null ? null : Duration(seconds: a['duration'] as int),
        artworkUrl: ((a['album'] as Map?)?['thumb'] as Map?)?['photo_300'] as String?,
      ),
  ];
}
