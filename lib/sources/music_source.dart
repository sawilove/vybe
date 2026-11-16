import '../core/models.dart';

/// A pluggable provider of music.
///
/// To add a new source (SoundCloud, Jamendo, Subsonic, ...) implement this
/// interface and register it in `SourceRegistry`. The UI and player never
/// talk to a concrete source directly.
abstract interface class MusicSource {
  SourceKind get kind;

  /// Free-text search ("write the name, get the track").
  Future<List<Track>> search(String query);

  /// Returns something `just_audio` can play: an http(s) URL or a file URI.
  /// Lazy tracks (see [Track.isLazy]) are matched here first.
  Future<ResolvedStream> resolveStream(Track track);

  /// Tracks similar to [track]; used for radio and recommendations.
  Future<List<Track>> related(Track track);
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
