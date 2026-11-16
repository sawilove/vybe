import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../core/models.dart';
import 'music_source.dart';

/// Yandex Music via its (unofficial) mobile API, with the user's own OAuth token.
///
/// * Search works without a token where Yandex Music is available.
/// * Streaming needs the user's token; full tracks need a Yandex Plus
///   subscription, otherwise Yandex serves 30-second previews.
///
/// The protocol follows the open-source `yandex-music-api` library
/// (https://github.com/MarshalX/yandex-music-api). Unofficial: it may break.
class YandexSource extends MusicSource {
  YandexSource(this.token, {JsonApi? api}) : _api = api ?? JsonApi();

  /// Reads the current token from settings.
  final String Function() token;
  final JsonApi _api;

  static const _host = 'api.music.yandex.net';

  /// Salt used by Yandex Music clients to sign download links (public, see the library above).
  static const _signSalt = 'XGRlBW9FXlekgbPrRHuSiA';

  @override
  SourceKind get kind => SourceKind.yandex;

  // Search is attempted even without a token; resolve needs one.
  @override
  bool get isConfigured => true;

  Map<String, String> get _headers => {
    if (token().isNotEmpty) 'Authorization': 'OAuth ${token()}',
    'X-Yandex-Music-Client': 'YandexMusicAndroid/24023621',
  };

  @override
  Future<List<Track>> search(String query) async {
    if (query.trim().isEmpty) return const [];
    final data = await _api.get(
      Uri.https(_host, '/search', {'text': query.trim(), 'type': 'track', 'page': '0'}),
      headers: _headers,
    );
    final results = (((data as Map)['result'] as Map?)?['tracks'] as Map?)?['results'] as List? ?? const [];
    return parseTracks(results);
  }

  @override
  Future<ResolvedStream> resolveStream(Track track) async {
    if (token().isEmpty) {
      throw SourceException('Yandex Music needs your token (Settings → Sources)');
    }
    var t = track;
    if (t.isLazy) {
      final hits = await search(t.query!);
      if (hits.isEmpty) throw SourceException('Not found on Yandex Music: ${t.query}');
      t = hits.first;
    }
    final info = await _api.get(Uri.https(_host, '/tracks/${t.id}/download-info'), headers: _headers);
    final options = ((info as Map)['result'] as List? ?? const []).cast<Map<String, dynamic>>()
      ..sort((a, b) => (b['bitrateInKbps'] as int? ?? 0).compareTo(a['bitrateInKbps'] as int? ?? 0));
    final mp3 = options.where((o) => o['codec'] == 'mp3').toList();
    final best = (mp3.isNotEmpty ? mp3 : options).firstOrNull;
    if (best == null) throw SourceException('Yandex Music: no stream for $t');

    final dl = await _api.get(Uri.parse('${best['downloadInfoUrl']}&format=json'), headers: _headers) as Map;
    final path = dl['path'] as String;
    final sign = md5.convert(utf8.encode('$_signSalt${path.substring(1)}${dl['s']}')).toString();
    return ResolvedStream(Uri.parse('https://${dl['host']}/get-mp3/$sign/${dl['ts']}$path'), track: t);
  }

  @override
  Future<List<Track>> related(Track track) async {
    if (track.isLazy) return search(track.query!);
    final data = await _api.get(Uri.https(_host, '/tracks/${track.id}/similar'), headers: _headers);
    final list = (((data as Map)['result'] as Map?)?['similarTracks'] as List?) ?? const [];
    return parseTracks(list);
  }

  static List<Track> parseTracks(List<dynamic> list) => [
    for (final t in list.cast<Map<String, dynamic>>())
      if (t['available'] != false)
        Track(
          id: '${t['id']}',
          title: (t['title'] as String? ?? '').trim(),
          artist: [for (final a in (t['artists'] as List? ?? const [])) (a as Map)['name']].join(', '),
          source: SourceKind.yandex,
          duration: t['durationMs'] == null ? null : Duration(milliseconds: t['durationMs'] as int),
          artworkUrl: t['coverUri'] == null ? null : 'https://${(t['coverUri'] as String).replaceAll('%%', '400x400')}',
        ),
  ];
}
