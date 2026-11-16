/// Where a track comes from. Every [SourceKind] has a matching `MusicSource`.
enum SourceKind {
  youtube('YouTube'),
  local('Local');

  const SourceKind(this.label);
  final String label;

  static SourceKind parse(String? name) =>
      SourceKind.values.firstWhere((k) => k.name == name, orElse: () => SourceKind.youtube);
}

/// A playable (or lazily resolvable) track.
///
/// A track with an empty [id] and a non-null [query] is *lazy*: it is only
/// metadata (e.g. from Last.fm), and the source finds the best match when the
/// track is about to play.
class Track {
  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.source,
    this.duration,
    this.artworkUrl,
    this.query,
  });

  /// Source-specific id: YouTube video id, or absolute file path for local.
  final String id;
  final String title;
  final String artist;
  final SourceKind source;
  final Duration? duration;
  final String? artworkUrl;
  final String? query;

  bool get isLazy => id.isEmpty && query != null;

  /// Stable key used for likes, history and de-duplication.
  String get key => isLazy
      ? 'q:${query!.toLowerCase()}'
      : '${source.name}:$id';

  Track copyWith({String? id, String? title, String? artist, Duration? duration, String? artworkUrl}) => Track(
        id: id ?? this.id,
        title: title ?? this.title,
        artist: artist ?? this.artist,
        source: source,
        duration: duration ?? this.duration,
        artworkUrl: artworkUrl ?? this.artworkUrl,
        query: query,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'source': source.name,
        if (duration != null) 'ms': duration!.inMilliseconds,
        if (artworkUrl != null) 'art': artworkUrl,
        if (query != null) 'q': query,
      };

  factory Track.fromJson(Map<String, dynamic> j) => Track(
        id: j['id'] as String? ?? '',
        title: j['title'] as String? ?? '',
        artist: j['artist'] as String? ?? '',
        source: SourceKind.parse(j['source'] as String?),
        duration: j['ms'] == null ? null : Duration(milliseconds: j['ms'] as int),
        artworkUrl: j['art'] as String?,
        query: j['q'] as String?,
      );

  @override
  bool operator ==(Object other) => other is Track && other.key == key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => '$artist — $title';
}

/// One entry of listening history.
class PlayEvent {
  const PlayEvent(this.track, this.at);
  final Track track;
  final DateTime at;

  Map<String, dynamic> toJson() => {'t': track.toJson(), 'at': at.millisecondsSinceEpoch};

  factory PlayEvent.fromJson(Map<String, dynamic> j) => PlayEvent(
        Track.fromJson(j['t'] as Map<String, dynamic>),
        DateTime.fromMillisecondsSinceEpoch(j['at'] as int),
      );
}
