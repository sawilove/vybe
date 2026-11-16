import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models.dart';
import '../data/library_store.dart';
import 'local_source.dart';
import 'music_source.dart';
import 'youtube_source.dart';

/// All enabled music sources. Add new sources here.
class SourceRegistry {
  SourceRegistry(this.sources);

  final List<MusicSource> sources;

  MusicSource of(SourceKind kind) => sources.firstWhere((s) => s.kind == kind);

  /// Searches every source at once. Local hits come first: if the user has
  /// the file, that's what they want. A failing source doesn't break search.
  Future<SearchResults> searchAll(String query) async {
    final futures = sources.map((s) async {
      try {
        return (s.kind, await s.search(query), null as Object?);
      } catch (e) {
        return (s.kind, const <Track>[], e as Object?);
      }
    });
    final results = await Future.wait(futures);
    final bySource = <SourceKind, List<Track>>{};
    final errors = <SourceKind, Object>{};
    for (final (kind, tracks, error) in results) {
      bySource[kind] = tracks;
      if (error != null) errors[kind] = error;
    }
    return SearchResults(bySource, errors);
  }
}

class SearchResults {
  const SearchResults(this.bySource, this.errors);

  final Map<SourceKind, List<Track>> bySource;
  final Map<SourceKind, Object> errors;

  List<Track> get all => [
        ...?bySource[SourceKind.local],
        for (final e in bySource.entries)
          if (e.key != SourceKind.local) ...e.value,
      ];
}

final youTubeSourceProvider = Provider<YouTubeSource>((ref) {
  final source = YouTubeSource();
  ref.onDispose(source.dispose);
  return source;
});

final sourceRegistryProvider = Provider<SourceRegistry>((ref) {
  return SourceRegistry([
    LocalSource(() => ref.read(libraryProvider).localTracks),
    ref.watch(youTubeSourceProvider),
  ]);
});
