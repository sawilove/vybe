import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models.dart';
import '../data/library_store.dart';
import 'audius_source.dart';
import 'local_source.dart';
import 'music_source.dart';
import 'soundcloud_source.dart';
import 'vk_source.dart';
import 'yandex_source.dart';
import 'youtube_source.dart';

/// All music sources. Add new sources here.
class SourceRegistry {
  SourceRegistry(this.sources, {this.isEnabled = _all});

  final List<MusicSource> sources;

  /// Whether the user has a source switched on (Settings → Sources).
  final bool Function(SourceKind) isEnabled;

  static bool _all(SourceKind _) => true;

  MusicSource of(SourceKind kind) => sources.firstWhere((s) => s.kind == kind);

  /// Sources that take part in search: enabled and configured.
  List<MusicSource> get active => [
    for (final s in sources)
      if (isEnabled(s.kind) && s.isConfigured) s,
  ];

  /// Searches every active source at once. A failing source doesn't break search.
  Future<SearchResults> searchAll(String query) async {
    final results = await Future.wait(
      active.map((s) async {
        try {
          return (s.kind, await s.search(query), null as Object?);
        } catch (e) {
          return (s.kind, const <Track>[], e as Object?);
        }
      }),
    );
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

  /// Local files first (if you have the file, that's what you want), then the
  /// other sources interleaved so the best hit of every service is near the top.
  List<Track> get all {
    final remote = [
      for (final k in SourceKind.values)
        if (k != SourceKind.local && (bySource[k]?.isNotEmpty ?? false)) bySource[k]!,
    ];
    final out = <Track>[...?bySource[SourceKind.local]];
    final longest = remote.fold(0, (m, l) => l.length > m ? l.length : m);
    for (var i = 0; i < longest; i++) {
      for (final l in remote) {
        if (i < l.length) out.add(l[i]);
      }
    }
    return out;
  }
}

final youTubeSourceProvider = Provider<YouTubeSource>((ref) {
  final source = YouTubeSource();
  ref.onDispose(source.dispose);
  return source;
});

final sourceRegistryProvider = Provider<SourceRegistry>((ref) {
  // Credentials are read lazily, so changing them doesn't rebuild the registry.
  AppSettings settings() => ref.read(libraryProvider).settings;
  final disabled = ref.watch(libraryProvider.select((s) => s.settings.disabledSources));
  return SourceRegistry([
    LocalSource(() => ref.read(libraryProvider).localTracks),
    ref.watch(youTubeSourceProvider),
    YandexSource(() => settings().yandexToken),
    VkSource(() => settings().vkToken, () => settings().vkUserAgent),
    SoundCloudSource(() => settings().soundcloudClientId),
    AudiusSource(),
  ], isEnabled: (k) => !disabled.contains(k));
});
