import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../core/models.dart';
import 'music_source.dart';

/// Music files the user imported from their device.
///
/// The imported list itself lives in `LibraryStore`; this source gets it via
/// [tracksProvider] so search and radio work over the user's files.
class LocalSource extends MusicSource {
  LocalSource(this.tracksProvider);

  final List<Track> Function() tracksProvider;

  static const audioExtensions = ['mp3', 'm4a', 'aac', 'flac', 'ogg', 'opus', 'wav'];

  @override
  SourceKind get kind => SourceKind.local;

  @override
  Future<List<Track>> search(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final words = q.split(RegExp(r'\s+'));
    return tracksProvider().where((t) {
      final hay = '${t.artist} ${t.title}'.toLowerCase();
      return words.every(hay.contains);
    }).toList();
  }

  @override
  Future<ResolvedStream> resolveStream(Track track) async {
    final file = File(track.id);
    if (!await file.exists()) {
      throw SourceException('File not found: ${track.id}');
    }
    return ResolvedStream(Uri.file(file.path), track: track);
  }

  @override
  Future<List<Track>> related(Track track) async {
    final all = tracksProvider();
    final sameArtist = all.where((t) => t.artist == track.artist && t != track);
    final others = all.where((t) => t.artist != track.artist).toList()..shuffle();
    return [...sameArtist, ...others.take(10)];
  }

  /// Builds a track from a file path. Until tag reading lands (see ROADMAP),
  /// metadata is parsed from "Artist - Title.ext".
  static Track trackFromPath(String path) {
    final name = path.split(Platform.pathSeparator).last;
    final base = name.contains('.') ? name.substring(0, name.lastIndexOf('.')) : name;
    final parts = base.split(RegExp(r'\s+[-–—]\s+'));
    final (artist, title) = parts.length >= 2
        ? (parts.first.trim(), parts.sublist(1).join(' - ').trim())
        : ('Unknown artist', base.trim());
    return Track(id: path, title: title, artist: artist, source: SourceKind.local);
  }

  /// On mobile the picker hands back temporary copies; move them somewhere
  /// that survives app restarts.
  static Future<String> persistPickedFile(String path) async {
    if (!(Platform.isAndroid || Platform.isIOS)) return path;
    final dir = Directory('${(await getApplicationDocumentsDirectory()).path}/music');
    await dir.create(recursive: true);
    final target = '${dir.path}/${path.split(Platform.pathSeparator).last}';
    if (path != target) await File(path).copy(target);
    return target;
  }
}
