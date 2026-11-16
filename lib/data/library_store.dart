import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/models.dart';

/// Overridden in `main()` once SharedPreferences is loaded.
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPrefsProvider must be overridden'),
);

class LibraryState {
  const LibraryState({
    this.liked = const [],
    this.history = const [],
    this.localTracks = const [],
    this.settings = const AppSettings(),
  });

  final List<Track> liked;
  final List<PlayEvent> history; // newest first
  final List<Track> localTracks;
  final AppSettings settings;

  bool isLiked(Track t) => liked.any((l) => l.key == t.key);

  /// Distinct tracks from history, newest first.
  List<Track> get recentlyPlayed {
    final seen = <String>{};
    return [
      for (final e in history)
        if (seen.add(e.track.key)) e.track,
    ];
  }

  /// Artists ranked by plays, weighting recent plays higher.
  List<String> topArtists({int limit = 5}) {
    final score = <String, double>{};
    for (var i = 0; i < history.length; i++) {
      final a = history[i].track.artist;
      if (a.isEmpty) continue;
      score[a] = (score[a] ?? 0) + 1 / (1 + i / 25);
    }
    for (final t in liked) {
      score[t.artist] = (score[t.artist] ?? 0) + 2;
    }
    final sorted = score.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).map((e) => e.key).toList();
  }

  LibraryState copyWith({
    List<Track>? liked,
    List<PlayEvent>? history,
    List<Track>? localTracks,
    AppSettings? settings,
  }) => LibraryState(
    liked: liked ?? this.liked,
    history: history ?? this.history,
    localTracks: localTracks ?? this.localTracks,
    settings: settings ?? this.settings,
  );
}

class AppSettings {
  const AppSettings({
    this.userName = '',
    this.autoRadio = true,
    this.lastFmApiKey = '',
    this.locale = '',
    this.disabledSources = const {},
    this.yandexToken = '',
    this.vkToken = '',
    this.vkUserAgent = '',
    this.soundcloudClientId = '',
    this.autoDownloadLiked = true,
  });

  final String userName;
  final bool autoRadio;
  final String lastFmApiKey;

  /// '' = follow the system, otherwise a language code ('en', 'ru').
  final String locale;

  /// Sources the user switched off. Everything else is searched by default.
  final Set<SourceKind> disabledSources;

  /// Credentials of the user's own accounts. Stored only on this device.
  final String yandexToken;
  final String vkToken;
  final String vkUserAgent;
  final String soundcloudClientId;

  /// Download liked tracks for offline listening.
  final bool autoDownloadLiked;

  bool isEnabled(SourceKind k) => !disabledSources.contains(k);

  AppSettings copyWith({
    String? userName,
    bool? autoRadio,
    String? lastFmApiKey,
    String? locale,
    Set<SourceKind>? disabledSources,
    String? yandexToken,
    String? vkToken,
    String? vkUserAgent,
    String? soundcloudClientId,
    bool? autoDownloadLiked,
  }) => AppSettings(
    userName: userName ?? this.userName,
    autoRadio: autoRadio ?? this.autoRadio,
    lastFmApiKey: lastFmApiKey ?? this.lastFmApiKey,
    locale: locale ?? this.locale,
    disabledSources: disabledSources ?? this.disabledSources,
    yandexToken: yandexToken ?? this.yandexToken,
    vkToken: vkToken ?? this.vkToken,
    vkUserAgent: vkUserAgent ?? this.vkUserAgent,
    soundcloudClientId: soundcloudClientId ?? this.soundcloudClientId,
    autoDownloadLiked: autoDownloadLiked ?? this.autoDownloadLiked,
  );

  Map<String, dynamic> toJson() => {
    'name': userName,
    'radio': autoRadio,
    'lfm': lastFmApiKey,
    'locale': locale,
    'off': [for (final k in disabledSources) k.name],
    'ym': yandexToken,
    'vk': vkToken,
    'vkUa': vkUserAgent,
    'sc': soundcloudClientId,
    'dlLiked': autoDownloadLiked,
  };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
    userName: j['name'] as String? ?? '',
    autoRadio: j['radio'] as bool? ?? true,
    lastFmApiKey: j['lfm'] as String? ?? '',
    locale: j['locale'] as String? ?? '',
    disabledSources: {for (final n in (j['off'] as List?) ?? const []) SourceKind.parse(n as String)},
    yandexToken: j['ym'] as String? ?? '',
    vkToken: j['vk'] as String? ?? '',
    vkUserAgent: j['vkUa'] as String? ?? '',
    soundcloudClientId: j['sc'] as String? ?? '',
    autoDownloadLiked: j['dlLiked'] as bool? ?? true,
  );
}

/// Everything VYBE remembers about the user. Stored only on the device.
class LibraryStore extends Notifier<LibraryState> {
  static const _kLiked = 'vybe.liked';
  static const _kHistory = 'vybe.history';
  static const _kLocal = 'vybe.local';
  static const _kSettings = 'vybe.settings';
  static const maxHistory = 500;

  SharedPreferences get _prefs => ref.read(sharedPrefsProvider);

  @override
  LibraryState build() {
    List<T> readList<T>(String key, T Function(Map<String, dynamic>) f) {
      final raw = _prefs.getString(key);
      if (raw == null) return [];
      try {
        return (jsonDecode(raw) as List).cast<Map<String, dynamic>>().map(f).toList();
      } catch (_) {
        return [];
      }
    }

    AppSettings settings = const AppSettings();
    final rawSettings = _prefs.getString(_kSettings);
    if (rawSettings != null) {
      try {
        settings = AppSettings.fromJson(jsonDecode(rawSettings) as Map<String, dynamic>);
      } catch (_) {}
    }

    return LibraryState(
      liked: readList(_kLiked, Track.fromJson),
      history: readList(_kHistory, PlayEvent.fromJson),
      localTracks: readList(_kLocal, Track.fromJson),
      settings: settings,
    );
  }

  void toggleLike(Track t) {
    final liked = state.isLiked(t) ? state.liked.where((l) => l.key != t.key).toList() : [t, ...state.liked];
    state = state.copyWith(liked: liked);
    _save(_kLiked, liked.map((e) => e.toJson()).toList());
  }

  void recordPlay(Track t) {
    final history = [PlayEvent(t, DateTime.now()), ...state.history].take(maxHistory).toList();
    state = state.copyWith(history: history);
    _save(_kHistory, history.map((e) => e.toJson()).toList());
  }

  void clearHistory() {
    state = state.copyWith(history: []);
    _save(_kHistory, []);
  }

  void addLocalTracks(Iterable<Track> tracks) {
    final byKey = {for (final t in state.localTracks) t.key: t};
    for (final t in tracks) {
      byKey[t.key] = t;
    }
    final list = byKey.values.toList();
    state = state.copyWith(localTracks: list);
    _save(_kLocal, list.map((e) => e.toJson()).toList());
  }

  void removeLocalTrack(Track t) {
    final list = state.localTracks.where((l) => l.key != t.key).toList();
    state = state.copyWith(localTracks: list);
    _save(_kLocal, list.map((e) => e.toJson()).toList());
  }

  void updateSettings(AppSettings s) {
    state = state.copyWith(settings: s);
    _prefs.setString(_kSettings, jsonEncode(s.toJson()));
  }

  void _save(String key, List<Map<String, dynamic>> data) => _prefs.setString(key, jsonEncode(data));
}

final libraryProvider = NotifierProvider<LibraryStore, LibraryState>(LibraryStore.new);
