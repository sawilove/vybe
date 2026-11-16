import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/models.dart';

/// A pluggable provider of music.
///
/// To add a new source implement this class and register it in
/// `SourceRegistry`. The UI and player never talk to a concrete source.
abstract class MusicSource {
  SourceKind get kind;

  /// False when the source needs credentials the user hasn't provided yet.
  /// Unconfigured sources are skipped by search instead of failing it.
  bool get isConfigured => true;

  /// Free-text search ("type the name, get the track").
  Future<List<Track>> search(String query);

  /// Returns something `just_audio` can play: an http(s) URL or a file URI.
  /// Lazy tracks (see [Track.isLazy]) are matched here first.
  Future<ResolvedStream> resolveStream(Track track);

  /// Tracks similar to [track]; used for radio and recommendations.
  Future<List<Track>> related(Track track);

  /// Saves the audio of [track] next to [basePath] (the extension is added
  /// here, as only the source knows the format). Lazy tracks get resolved.
  Future<DownloadResult> download(Track track, String basePath, {http.Client? client}) async {
    final resolved = await resolveStream(track);
    if (resolved.uri.path.endsWith('.m3u8')) {
      throw SourceException('${kind.label}: this track is only available as a live stream');
    }
    final c = client ?? http.Client();
    final file = File('$basePath.mp3');
    try {
      final req = http.Request('GET', resolved.uri)..headers.addAll(resolved.headers ?? const {});
      final res = await c.send(req);
      if (res.statusCode >= 400) throw SourceException('HTTP ${res.statusCode}');
      await res.stream.pipe(file.openWrite());
    } finally {
      if (client == null) c.close();
    }
    return DownloadResult(resolved.track, file.path);
  }
}

class DownloadResult {
  const DownloadResult(this.track, this.path);
  final Track track;
  final String path;
}

class ResolvedStream {
  const ResolvedStream(this.uri, {required this.track, this.headers});

  final Uri uri;

  /// The track, possibly enriched (a lazy track becomes a concrete one).
  final Track track;
  final Map<String, String>? headers;
}

class SourceException implements Exception {
  SourceException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Small JSON-over-HTTP helper shared by the API-based sources.
class JsonApi {
  JsonApi({http.Client? client}) : _http = client ?? http.Client();

  final http.Client _http;

  Future<dynamic> get(Uri uri, {Map<String, String>? headers}) async {
    final res = await _http.get(uri, headers: headers).timeout(const Duration(seconds: 20));
    if (res.statusCode >= 400) {
      throw SourceException('${uri.host}: HTTP ${res.statusCode}');
    }
    return jsonDecode(utf8.decode(res.bodyBytes));
  }

  void close() => _http.close();
}
