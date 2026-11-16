import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/models.dart';

/// Optional Last.fm integration. The user pastes their own free API key in
/// Settings (https://www.last.fm/api/account/create), so VYBE ships no secrets.
class LastFmClient {
  LastFmClient(this.apiKey, {http.Client? client}) : _http = client ?? http.Client();

  final String apiKey;
  final http.Client _http;

  /// Similar tracks as *lazy* tracks: metadata only, resolved on play.
  Future<List<Track>> similarTracks(Track seed, {int limit = 20}) async {
    final data = await _call({
      'method': 'track.getsimilar',
      'artist': seed.artist,
      'track': seed.title,
      'autocorrect': '1',
      'limit': '$limit',
    });
    final list = (data['similartracks']?['track'] as List?) ?? const [];
    return [
      for (final t in list.cast<Map<String, dynamic>>())
        _lazy(t['artist']?['name'] as String? ?? '', t['name'] as String? ?? ''),
    ].where((t) => t.title.isNotEmpty).toList();
  }

  Future<List<Track>> topTracksOfArtist(String artist, {int limit = 10}) async {
    final data = await _call({
      'method': 'artist.gettoptracks',
      'artist': artist,
      'autocorrect': '1',
      'limit': '$limit',
    });
    final list = (data['toptracks']?['track'] as List?) ?? const [];
    return [for (final t in list.cast<Map<String, dynamic>>()) _lazy(artist, t['name'] as String? ?? '')]
        .where((t) => t.title.isNotEmpty)
        .toList();
  }

  static Track _lazy(String artist, String title) =>
      Track(id: '', title: title, artist: artist, source: SourceKind.youtube, query: '$artist - $title');

  Future<Map<String, dynamic>> _call(Map<String, String> params) async {
    final uri = Uri.https('ws.audioscrobbler.com', '/2.0/', {...params, 'api_key': apiKey, 'format': 'json'});
    final res = await _http.get(uri);
    if (res.statusCode != 200) throw Exception('Last.fm ${res.statusCode}');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}
