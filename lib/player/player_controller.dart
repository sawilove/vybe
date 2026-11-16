import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../core/models.dart';
import '../data/download_manager.dart';
import '../data/library_store.dart';
import '../recommendations/recommendation_service.dart';
import '../sources/music_source.dart';
import '../sources/source_registry.dart';

enum RepeatPolicy { off, all, one }

@immutable
class PlayerSnapshot {
  const PlayerSnapshot({
    this.queue = const [],
    this.index = -1,
    this.playing = false,
    this.loading = false,
    this.shuffle = false,
    this.repeat = RepeatPolicy.off,
    this.volume = 0.8,
    this.error,
    this.radioLoading = false,
  });

  final List<Track> queue;
  final int index;
  final bool playing;
  final bool loading;
  final bool shuffle;
  final RepeatPolicy repeat;
  final double volume;
  final String? error;
  final bool radioLoading;

  Track? get current => index >= 0 && index < queue.length ? queue[index] : null;
  List<Track> get upNext => index < 0 ? queue : queue.sublist(min(index + 1, queue.length));
  bool get hasNext => index < queue.length - 1 || repeat == RepeatPolicy.all;

  PlayerSnapshot copyWith({
    List<Track>? queue,
    int? index,
    bool? playing,
    bool? loading,
    bool? shuffle,
    RepeatPolicy? repeat,
    double? volume,
    String? error,
    bool clearError = false,
    bool? radioLoading,
  }) => PlayerSnapshot(
    queue: queue ?? this.queue,
    index: index ?? this.index,
    playing: playing ?? this.playing,
    loading: loading ?? this.loading,
    shuffle: shuffle ?? this.shuffle,
    repeat: repeat ?? this.repeat,
    volume: volume ?? this.volume,
    error: clearError ? null : (error ?? this.error),
    radioLoading: radioLoading ?? this.radioLoading,
  );
}

final audioPlayerProvider = Provider<AudioPlayer>((ref) {
  final player = AudioPlayer();
  ref.onDispose(player.dispose);
  return player;
});

final positionProvider = StreamProvider<Duration>((ref) => ref.watch(audioPlayerProvider).positionStream);

final durationProvider = StreamProvider<Duration?>((ref) => ref.watch(audioPlayerProvider).durationStream);

/// Owns the queue and drives `just_audio`.
///
/// Streams are resolved right before playing because YouTube URLs expire.
class PlayerController extends Notifier<PlayerSnapshot> {
  AudioPlayer get _player => ref.read(audioPlayerProvider);

  int _loadToken = 0;
  int _consecutiveErrors = 0;
  List<Track>? _unshuffledQueue;
  String? _radioSeedKey;
  final _subs = <StreamSubscription<dynamic>>[];

  @override
  PlayerSnapshot build() {
    final player = ref.watch(audioPlayerProvider);
    _subs.add(
      player.playerStateStream.listen((s) {
        if (!ref.mounted) return;
        if (s.processingState == ProcessingState.completed) {
          _onCompleted();
        } else if (s.playing != state.playing) {
          state = state.copyWith(playing: s.playing);
        }
      }),
    );
    ref.onDispose(() {
      for (final s in _subs) {
        s.cancel();
      }
    });
    return const PlayerSnapshot();
  }

  /// Plays [queue] starting at [startIndex]. Use for "tap a track in a list".
  Future<void> playQueue(List<Track> queue, {int startIndex = 0}) async {
    if (queue.isEmpty) return;
    _unshuffledQueue = null;
    _radioSeedKey = null;
    state = state.copyWith(queue: List.of(queue), index: startIndex, shuffle: false);
    await _loadCurrent();
  }

  /// Plays a single track and lets radio fill the rest.
  Future<void> playTrack(Track track) => playQueue([track]);

  void addToQueue(Track track) {
    if (state.current == null) {
      playTrack(track);
      return;
    }
    state = state.copyWith(queue: [...state.queue, track]);
  }

  void playNext(Track track) {
    if (state.current == null) {
      playTrack(track);
      return;
    }
    final q = [...state.queue]..insert(state.index + 1, track);
    state = state.copyWith(queue: q);
  }

  void removeAt(int i) {
    if (i == state.index || i < 0 || i >= state.queue.length) return;
    final q = [...state.queue]..removeAt(i);
    state = state.copyWith(queue: q, index: i < state.index ? state.index - 1 : state.index);
  }

  void clearUpNext() {
    if (state.current == null) return;
    state = state.copyWith(queue: state.queue.sublist(0, state.index + 1));
  }

  Future<void> jumpTo(int i) async {
    if (i < 0 || i >= state.queue.length) return;
    state = state.copyWith(index: i);
    await _loadCurrent();
  }

  Future<void> togglePlay() async {
    if (state.current == null) return;
    if (_player.playing) {
      await _player.pause();
    } else {
      if (_player.processingState == ProcessingState.idle) {
        await _loadCurrent();
      } else {
        unawaited(_player.play());
      }
    }
  }

  Future<void> next() async {
    if (state.index < state.queue.length - 1) {
      state = state.copyWith(index: state.index + 1);
    } else if (state.repeat == RepeatPolicy.all && state.queue.isNotEmpty) {
      state = state.copyWith(index: 0);
    } else {
      return;
    }
    await _loadCurrent();
  }

  Future<void> previous() async {
    // Like most players: restart the track unless we're at its very start.
    if (_player.position > const Duration(seconds: 3) || state.index <= 0) {
      await _player.seek(Duration.zero);
      return;
    }
    state = state.copyWith(index: state.index - 1);
    await _loadCurrent();
  }

  Future<void> seek(Duration d) => _player.seek(d);

  Future<void> setVolume(double v) async {
    state = state.copyWith(volume: v);
    await _player.setVolume(v);
  }

  void cycleRepeat() {
    final next = RepeatPolicy.values[(state.repeat.index + 1) % RepeatPolicy.values.length];
    state = state.copyWith(repeat: next);
  }

  void toggleShuffle() {
    final current = state.current;
    if (current == null) {
      state = state.copyWith(shuffle: !state.shuffle);
      return;
    }
    if (!state.shuffle) {
      _unshuffledQueue = state.queue;
      final rest = [...state.queue]
        ..removeAt(state.index)
        ..shuffle();
      state = state.copyWith(queue: [current, ...rest], index: 0, shuffle: true);
    } else {
      final original = _unshuffledQueue ?? state.queue;
      final extra = state.queue.where((t) => !original.contains(t));
      final q = [...original, ...extra];
      state = state.copyWith(queue: q, index: max(0, q.indexOf(current)), shuffle: false);
      _unshuffledQueue = null;
    }
  }

  Future<void> _onCompleted() async {
    if (state.repeat == RepeatPolicy.one) {
      await _player.seek(Duration.zero);
      unawaited(_player.play());
      return;
    }
    if (state.hasNext) {
      await next();
    } else {
      state = state.copyWith(playing: false);
    }
  }

  Future<void> _loadCurrent() async {
    final track = state.current;
    if (track == null) return;
    final token = ++_loadToken;
    state = state.copyWith(loading: true, clearError: true);
    try {
      await _player.stop();
      // Offline copy first: no network, no expiring links.
      final offline = ref.read(downloadsProvider).pathFor(track);
      final resolved = offline != null && File(offline).existsSync()
          ? ResolvedStream(Uri.file(offline), track: ref.read(downloadsProvider).tracks[track.key] ?? track)
          : await ref.read(sourceRegistryProvider).of(track.source).resolveStream(track);
      if (token != _loadToken || !ref.mounted) return;

      // A lazy track (e.g. from Last.fm) becomes the concrete match.
      if (resolved.track.key != track.key) {
        final q = [...state.queue]..[state.index] = resolved.track;
        state = state.copyWith(queue: q);
      }
      // Start fetching radio in parallel with buffering the audio.
      unawaited(_maybeExtendWithRadio());

      await _player.setVolume(state.volume);
      final t = resolved.track;
      await _player.setAudioSource(
        AudioSource.uri(
          resolved.uri,
          headers: resolved.headers,
          // Shown on the lock screen / in the notification (just_audio_background).
          tag: MediaItem(
            id: t.key,
            title: t.title,
            artist: t.artist,
            duration: t.duration,
            artUri: t.artworkUrl == null ? null : Uri.tryParse(t.artworkUrl!),
          ),
        ),
      );
      if (token != _loadToken || !ref.mounted) return;
      unawaited(_player.play());
      _consecutiveErrors = 0;
      state = state.copyWith(loading: false, playing: true);
      ref.read(libraryProvider.notifier).recordPlay(resolved.track);
    } catch (e) {
      if (token != _loadToken || !ref.mounted) return;
      debugPrint('Playback failed for $track: $e');
      state = state.copyWith(loading: false, playing: false, error: '$track');
      // Skip broken tracks, but don't loop forever if the network is down.
      if (++_consecutiveErrors < 3 && state.index < state.queue.length - 1) {
        await Future<void>.delayed(const Duration(milliseconds: 800));
        if (token == _loadToken) await next();
      }
    }
  }

  /// When the last queued track starts, append similar tracks (like YT Music).
  Future<void> _maybeExtendWithRadio() async {
    final lib = ref.read(libraryProvider);
    final current = state.current;
    if (!lib.settings.autoRadio || current == null) return;
    if (state.index < state.queue.length - 1 || state.repeat != RepeatPolicy.off) return;
    if (_radioSeedKey == current.key) return;
    _radioSeedKey = current.key;

    state = state.copyWith(radioLoading: true);
    try {
      final more = await ref
          .read(recommendationServiceProvider)
          .radio(current, exclude: state.queue.map((t) => t.key).toSet());
      if (!ref.mounted) return;
      state = state.copyWith(queue: [...state.queue, ...more], radioLoading: false);
    } catch (e) {
      if (ref.mounted) state = state.copyWith(radioLoading: false);
    }
  }
}

final playerProvider = NotifierProvider<PlayerController, PlayerSnapshot>(PlayerController.new);
