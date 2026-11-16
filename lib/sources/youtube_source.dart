import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;

import '../core/models.dart';
import 'music_source.dart';

/// YouTube / YouTube Music source, built on `youtube_explode_dart`.
///
/// NOTE: playing YouTube in a third-party client is against YouTube's Terms of
/// Service. See docs/ARCHITECTURE.md ("Про YouTube") for the consequences.
class YouTubeSource implements MusicSource {
  YouTubeSource({yt.YoutubeExplode? client}) : _yt = client ?? yt.YoutubeExplode();

  final yt.YoutubeExplode _yt;

  /// Stream URLs expire after a few hours; cache them for a shorter time.
  final _streamCache = <String, (Uri, DateTime)>{};
  static const _streamTtl = Duration(hours: 2);

  @override
  SourceKind get kind => SourceKind.youtube;

  @override
  Future<List<Track>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    // `search.search()` crashes on results like "Streamed 2 days ago", so use
    // the raw results and map them ourselves.
    final results = await _yt.search.searchContent(q, filter: yt.TypeFilters.video);
    return [
      for (final v in results.whereType<yt.SearchVideo>())
        if (!v.isLive && _isSongLength(parseDuration(v.duration)))
          _toTrack(v.id.value, v.title, v.author, parseDuration(v.duration)),
    ];
  }

  @override
  Future<ResolvedStream> resolveStream(Track track) async {
    var t = track;
    if (t.isLazy) {
      final matches = await search(t.query!);
      if (matches.isEmpty) throw SourceException('Не нашли «${t.query}» на YouTube');
      t = matches.first;
    }

    try {
      return await _resolveVideo(t);
    } on yt.YoutubeExplodeException catch (e) {
      // Some uploads are region-locked or restricted. Like a Telegram music
      // bot, fall back to another upload of the same song (lyric video,
      // "Topic" audio, ...) with a similar length.
      debugPrint('YouTube: ${t.id} unplayable ($e), looking for another upload');
      final alternatives = (await search('${t.artist} ${t.title}'))
          .where((a) => a.id != t.id && _similarLength(a.duration, t.duration))
          .take(3);
      for (final alt in alternatives) {
        try {
          return await _resolveVideo(alt);
        } on yt.YoutubeExplodeException {
          continue;
        }
      }
      throw SourceException('YouTube не отдаёт этот трек: $t');
    }
  }

  Future<ResolvedStream> _resolveVideo(Track t) async {
    final cached = _streamCache[t.id];
    if (cached != null && DateTime.now().difference(cached.$2) < _streamTtl) {
      return ResolvedStream(cached.$1, track: t);
    }

    final manifest = await _yt.videos.streams.getManifest(
      t.id,
      ytClients: [yt.YoutubeApiClient.ios, yt.YoutubeApiClient.androidVr],
    );
    final audio = manifest.audioOnly;
    if (audio.isEmpty) throw SourceException('У этого видео нет аудиопотока');

    // AVPlayer (iOS/macOS) can't play WebM/Opus; prefer MP4/AAC there.
    final preferMp4 = !kIsWeb && (Platform.isIOS || Platform.isMacOS);
    final mp4 = audio.where((s) => s.container == yt.StreamContainer.mp4).toList();
    final chosen = (preferMp4 && mp4.isNotEmpty ? mp4 : audio.toList()).withHighestBitrate();

    _streamCache[t.id] = (chosen.url, DateTime.now());
    return ResolvedStream(chosen.url, track: t);
  }

  @override
  Future<List<Track>> related(Track track) async {
    if (track.isLazy) return search('${track.artist} ${track.title}');
    yt.RelatedVideosList? list;
    try {
      final video = await _yt.videos.get(track.id);
      list = await _yt.videos.getRelatedVideos(video);
    } catch (e) {
      // The library's related parser chokes on some upload dates; a search
      // for the artist is a decent stand-in.
      debugPrint('YouTube related() failed ($e), falling back to search');
    }
    if (list == null || list.isEmpty) {
      final byArtist = await search('${track.artist} songs');
      return byArtist.where((t) => t.id != track.id).toList();
    }
    return [
      for (final v in list)
        if (_isSongLength(v.duration)) _toTrack(v.id.value, v.title, v.author, v.duration),
    ];
  }

  void dispose() => _yt.close();

  /// Filters out live streams, shorts and hour-long compilations.
  static bool _isSongLength(Duration? d) =>
      d != null && d >= const Duration(seconds: 45) && d <= const Duration(minutes: 20);

  static bool _similarLength(Duration? a, Duration? b) =>
      a == null || b == null || (a - b).abs() <= const Duration(seconds: 20);

  /// Parses YouTube's "4:09" / "1:02:03".
  @visibleForTesting
  static Duration? parseDuration(String raw) {
    final parts = raw.trim().split(':').map(int.tryParse).toList();
    if (parts.isEmpty || parts.length > 3 || parts.contains(null)) return null;
    var seconds = 0;
    for (final p in parts) {
      seconds = seconds * 60 + p!;
    }
    return Duration(seconds: seconds);
  }

  static Track _toTrack(String id, String rawTitle, String channel, Duration? duration) {
    final (artist, title) = parseTitle(rawTitle, channel);
    return Track(
      id: id,
      title: title,
      artist: artist,
      source: SourceKind.youtube,
      duration: duration,
      artworkUrl: 'https://i.ytimg.com/vi/$id/hqdefault.jpg',
    );
  }

  static final _noise = RegExp(
    r'\s*[\(\[](official\s*(music\s*)?(video|audio|lyric[s]?\s*video|visualizer)|lyrics?|audio|video|hd|hq|4k|mv|clip|клип|премьера[^\)\]]*)[\)\]]',
    caseSensitive: false,
  );

  /// Splits "Artist - Title (Official Video)" into (artist, title).
  /// Falls back to the channel name with " - Topic" / "VEVO" stripped.
  @visibleForTesting
  static (String, String) parseTitle(String raw, String channel) {
    var title = raw.replaceAll(_noise, '').trim();
    title = title.split(' | ').first.trim();

    final dash = RegExp(r'\s+[-–—]\s+').firstMatch(title);
    if (dash != null) {
      final artist = title.substring(0, dash.start).trim();
      final rest = title.substring(dash.end).trim();
      if (artist.isNotEmpty && rest.isNotEmpty) return (artist, rest);
    }

    final artist = channel
        .replaceAll(RegExp(r'\s*-\s*Topic$', caseSensitive: false), '')
        .replaceAll(RegExp(r'VEVO$'), '')
        .trim();
    return (artist.isEmpty ? channel : artist, title);
  }
}
