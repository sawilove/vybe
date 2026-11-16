import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../core/models.dart';
import '../sources/source_registry.dart';
import 'library_store.dart';

@immutable
class DownloadsState {
  const DownloadsState({this.files = const {}, this.tracks = const {}, this.queued = const [], this.failed = const {}});

  /// Track key → audio file on disk.
  final Map<String, String> files;

  /// Track key → metadata of the downloaded track (for the Downloads list).
  final Map<String, Track> tracks;

  /// Waiting or in progress, in order. The first one is being downloaded.
  final List<Track> queued;

  /// Track key → last error.
  final Map<String, String> failed;

  bool isDownloaded(Track t) => files.containsKey(t.key);
  bool isQueued(Track t) => queued.any((q) => q.key == t.key);
  String? pathFor(Track t) => files[t.key];
  List<Track> get downloaded => tracks.values.toList();

  DownloadsState copyWith({
    Map<String, String>? files,
    Map<String, Track>? tracks,
    List<Track>? queued,
    Map<String, String>? failed,
  }) => DownloadsState(
    files: files ?? this.files,
    tracks: tracks ?? this.tracks,
    queued: queued ?? this.queued,
    failed: failed ?? this.failed,
  );
}

/// Offline cache: downloads tracks one at a time into the app's support
/// directory and remembers where they are. Liked tracks are downloaded
/// automatically when "Auto-download liked tracks" is on.
class DownloadManager extends Notifier<DownloadsState> {
  static const _kIndex = 'vybe.downloads';
  bool _working = false;

  /// Overridable for tests.
  @visibleForTesting
  static Future<Directory> Function() directory = () async {
    final base = await getApplicationSupportDirectory();
    return Directory('${base.path}${Platform.pathSeparator}offline');
  };

  @override
  DownloadsState build() {
    final prefs = ref.read(sharedPrefsProvider);
    final files = <String, String>{};
    final tracks = <String, Track>{};
    try {
      for (final e in (jsonDecode(prefs.getString(_kIndex) ?? '[]') as List).cast<Map<String, dynamic>>()) {
        final t = Track.fromJson(e['t'] as Map<String, dynamic>);
        files[t.key] = e['p'] as String;
        tracks[t.key] = t;
      }
    } catch (_) {}

    // Auto-download newly liked tracks.
    ref.listen(libraryProvider.select((s) => s.liked), (prev, next) {
      if (!ref.read(libraryProvider).settings.autoDownloadLiked) return;
      final before = {for (final t in prev ?? const <Track>[]) t.key};
      for (final t in next) {
        if (!before.contains(t.key)) enqueue(t);
      }
    });
    // Turning the setting on catches up with everything already liked.
    ref.listen(libraryProvider.select((s) => s.settings.autoDownloadLiked), (prev, on) {
      if (on && prev == false) ref.read(libraryProvider).liked.forEach(enqueue);
    });

    return DownloadsState(files: files, tracks: tracks);
  }

  void enqueue(Track t) {
    if (t.source == SourceKind.local || state.isDownloaded(t) || state.isQueued(t)) return;
    state = state.copyWith(queued: [...state.queued, t], failed: {...state.failed}..remove(t.key));
    unawaited(_pump());
  }

  void cancel(Track t) {
    if (state.queued.isNotEmpty && state.queued.first.key == t.key && _working) return; // already running
    state = state.copyWith(queued: state.queued.where((q) => q.key != t.key).toList());
  }

  Future<void> remove(Track t) async {
    final path = state.files[t.key];
    if (path != null) {
      try {
        await File(path).delete();
      } catch (_) {}
    }
    state = state.copyWith(files: {...state.files}..remove(t.key), tracks: {...state.tracks}..remove(t.key));
    _save();
  }

  Future<void> clear() async {
    for (final t in state.downloaded) {
      await remove(t);
    }
  }

  Future<int> sizeInBytes() async {
    var total = 0;
    for (final p in state.files.values) {
      try {
        total += await File(p).length();
      } catch (_) {}
    }
    return total;
  }

  Future<void> _pump() async {
    if (_working) return;
    _working = true;
    try {
      while (state.queued.isNotEmpty && ref.mounted) {
        final t = state.queued.first;
        try {
          final dir = await directory();
          await dir.create(recursive: true);
          final base = '${dir.path}${Platform.pathSeparator}${_safeName(t.key)}';
          final result = await ref.read(sourceRegistryProvider).of(t.source).download(t, base);
          if (!ref.mounted) return;
          // Store under the original key (likes and queue use it) and the resolved one.
          final files = {...state.files, t.key: result.path, result.track.key: result.path};
          final tracks = {...state.tracks, t.key: result.track};
          state = state.copyWith(files: files, tracks: tracks);
          _save();
        } catch (e) {
          debugPrint('Download failed for $t: $e');
          if (!ref.mounted) return;
          state = state.copyWith(failed: {...state.failed, t.key: '$e'});
        }
        state = state.copyWith(queued: state.queued.where((q) => q.key != t.key).toList());
      }
    } finally {
      _working = false;
    }
  }

  void _save() {
    final entries = [
      for (final e in state.tracks.entries)
        if (state.files[e.key] != null) {'t': e.value.toJson(), 'p': state.files[e.key]},
    ];
    ref.read(sharedPrefsProvider).setString(_kIndex, jsonEncode(entries));
  }

  static String _safeName(String key) => key.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');
}

final downloadsProvider = NotifierProvider<DownloadManager, DownloadsState>(DownloadManager.new);
