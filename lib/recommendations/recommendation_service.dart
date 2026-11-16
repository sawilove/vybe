import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/models.dart';
import '../data/library_store.dart';
import '../sources/source_registry.dart';
import 'lastfm_client.dart';

/// A "Made for You" mood mix shown on Home.
class Mix {
  const Mix({required this.id, required this.title, required this.query, required this.icon, required this.colors});

  final String id;
  final String title;
  final String query;
  final IconData icon;
  final List<Color> colors;
}

const mixes = [
  Mix(
    id: 'chill',
    title: 'Chill Vibes',
    query: 'chill vibes songs',
    icon: Icons.nights_stay_rounded,
    colors: [Color(0xFF3B2A7A), Color(0xFFDB5C9A)],
  ),
  Mix(
    id: 'gaming',
    title: 'Gaming Mix',
    query: 'gaming music mix songs',
    icon: Icons.sports_esports_rounded,
    colors: [Color(0xFF1F1B4D), Color(0xFF6D3BF5)],
  ),
  Mix(
    id: 'late',
    title: 'Late Night',
    query: 'late night songs',
    icon: Icons.bedtime_rounded,
    colors: [Color(0xFF16163A), Color(0xFF5B4BB7)],
  ),
  Mix(
    id: 'workout',
    title: 'Workout',
    query: 'workout motivation songs',
    icon: Icons.fitness_center_rounded,
    colors: [Color(0xFF2B1638), Color(0xFFE0533D)],
  ),
];

/// Recommendations computed entirely on the device.
class RecommendationService {
  RecommendationService(this._registry, this._readLibrary, this._lastFm);

  final SourceRegistry _registry;
  final LibraryState Function() _readLibrary;
  final LastFmClient? _lastFm;

  LibraryState get _library => _readLibrary();

  /// "Made for You": related tracks of recent and liked tracks, ranked.
  Future<List<Track>> forYou({int limit = 30}) async {
    final seeds = <Track>{..._library.recentlyPlayed.take(4), ..._library.liked.take(2)}.toList();
    if (seeds.isEmpty) return discover();

    final candidates = await Future.wait(seeds.map(_similarSafe));
    final recent = _library.recentlyPlayed.take(40).map((t) => t.key).toSet();
    return rank(candidates, exclude: recent, limit: limit);
  }

  /// Radio queue that continues after [seed].
  Future<List<Track>> radio(Track seed, {Set<String> exclude = const {}, int limit = 20}) async {
    final candidates = await _similarSafe(seed);
    return rank([candidates], exclude: {...exclude, seed.key}, limit: limit);
  }

  /// A mood mix, personalised with the user's top artist when there is one.
  Future<List<Track>> mix(Mix mix) async {
    final top = _library.topArtists(limit: 2);
    final queries = [mix.query, for (final a in top) '${mix.query} like $a'];
    final lists = await Future.wait(
      queries.map((q) async {
        try {
          return await _registry.of(SourceKind.youtube).search(q);
        } catch (_) {
          return <Track>[];
        }
      }),
    );
    return rank(lists, limit: 25);
  }

  /// For new users with no history yet.
  Future<List<Track>> discover() async {
    final year = DateTime.now().year;
    final yt = _registry.of(SourceKind.youtube);
    final lists = await Future.wait(
      ['top songs $year', 'new music $year official audio', 'top 50 $year'].map((q) async {
        try {
          return await yt.search(q);
        } catch (_) {
          return <Track>[];
        }
      }),
    );
    return rank(lists, limit: 20);
  }

  Future<List<Track>> _similarSafe(Track seed) async {
    final out = <Track>[];
    try {
      out.addAll(await _registry.of(seed.source).related(seed));
    } catch (e) {
      debugPrint('related() failed for $seed: $e');
    }
    final lastFm = _lastFm;
    if (lastFm != null) {
      try {
        out.addAll(await lastFm.similarTracks(seed));
      } catch (e) {
        debugPrint('Last.fm failed for $seed: $e');
      }
    }
    return out;
  }

  /// Merges several candidate lists:
  /// * tracks suggested by more seeds and higher in their list win;
  /// * [exclude]d keys (recently played) are dropped;
  /// * at most [perArtist] tracks per artist, never two in a row.
  @visibleForTesting
  static List<Track> rank(
    List<List<Track>> lists, {
    Set<String> exclude = const {},
    int limit = 30,
    int perArtist = 2,
  }) {
    final score = <String, double>{};
    final byKey = <String, Track>{};
    final titleKeys = <String, String>{}; // "artist|title" -> key, to merge YouTube & Last.fm dupes
    for (final list in lists) {
      for (var i = 0; i < list.length; i++) {
        final t = list[i];
        if (exclude.contains(t.key)) continue;
        final norm = '${t.artist.toLowerCase()}|${t.title.toLowerCase()}';
        final key = titleKeys.putIfAbsent(norm, () => t.key);
        // Prefer concrete tracks over lazy ones.
        if (!byKey.containsKey(key) || (byKey[key]!.isLazy && !t.isLazy)) byKey[key] = t;
        score[key] = (score[key] ?? 0) + 1 / (1 + i / 5);
      }
    }
    final sorted = byKey.keys.toList()..sort((a, b) => score[b]!.compareTo(score[a]!));

    final out = <Track>[];
    final artistCount = <String, int>{};
    final deferred = <Track>[];
    for (final key in sorted) {
      final t = byKey[key]!;
      final a = t.artist.toLowerCase();
      if ((artistCount[a] ?? 0) >= perArtist) continue;
      if (out.isNotEmpty && out.last.artist.toLowerCase() == a) {
        deferred.add(t);
        continue;
      }
      out.add(t);
      artistCount[a] = (artistCount[a] ?? 0) + 1;
      // Try to place a deferred track now that the artist changed.
      for (final d in [...deferred]) {
        final da = d.artist.toLowerCase();
        if (out.last.artist.toLowerCase() != da && (artistCount[da] ?? 0) < perArtist) {
          out.add(d);
          artistCount[da] = (artistCount[da] ?? 0) + 1;
          deferred.remove(d);
        }
      }
      if (out.length >= limit) break;
    }
    return out.take(limit).toList();
  }
}

final recommendationServiceProvider = Provider<RecommendationService>((ref) {
  final key = ref.watch(libraryProvider.select((s) => s.settings.lastFmApiKey));
  return RecommendationService(
    ref.watch(sourceRegistryProvider),
    () => ref.read(libraryProvider),
    key.isEmpty ? null : LastFmClient(key),
  );
});

/// Recomputed when the user opens Home or explicitly refreshes it, not on
/// every play (that would hammer YouTube).
final forYouProvider = FutureProvider<List<Track>>((ref) => ref.watch(recommendationServiceProvider).forYou());

final mixProvider = FutureProvider.family<List<Track>, String>((ref, id) {
  final mix = mixes.firstWhere((m) => m.id == id);
  return ref.watch(recommendationServiceProvider).mix(mix);
});
