import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../player/player_controller.dart';
import 'common.dart';
import 'track_tile.dart';

/// Progress slider with a local drag value so it doesn't jump while seeking.
class SeekBar extends ConsumerStatefulWidget {
  const SeekBar({super.key, this.showTimes = true, this.inlineTimes = false});

  final bool showTimes;

  /// Desktop bar style: "1:24 / 3:30" to the right of the slider.
  final bool inlineTimes;

  @override
  ConsumerState<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends ConsumerState<SeekBar> {
  double? _drag;

  @override
  Widget build(BuildContext context) {
    final pos = ref.watch(positionProvider).value ?? Duration.zero;
    final current = ref.watch(playerProvider.select((s) => s.current));
    final dur = ref.watch(durationProvider).value ?? current?.duration ?? Duration.zero;
    final max = dur.inMilliseconds.toDouble();
    final value = (_drag ?? pos.inMilliseconds.toDouble()).clamp(0.0, max <= 0 ? 0.0 : max);
    final shown = Duration(milliseconds: value.round());
    final muted = Theme.of(context).textTheme.bodySmall?.copyWith(color: VybeColors.textMuted);

    final slider = Slider(
      value: value,
      max: max <= 0 ? 1 : max,
      onChanged: max <= 0 ? null : (v) => setState(() => _drag = v),
      onChangeEnd: (v) {
        ref.read(playerProvider.notifier).seek(Duration(milliseconds: v.round()));
        setState(() => _drag = null);
      },
    );

    if (widget.inlineTimes) {
      return Row(
        children: [
          Expanded(child: slider),
          const SizedBox(width: 8),
          Text('${formatDuration(shown)} / ${formatDuration(dur)}', style: muted),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 28, child: slider),
        if (widget.showTimes)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text(formatDuration(shown), style: muted), Text(formatDuration(dur), style: muted)],
            ),
          ),
      ],
    );
  }
}

/// prev / play-pause / next, optionally with shuffle and repeat.
class TransportControls extends ConsumerWidget {
  const TransportControls({super.key, this.withModes = true, this.size = 52});

  final bool withModes;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(playerProvider);
    final c = ref.read(playerProvider.notifier);
    final iconSize = size * 0.55;
    Color modeColor(bool on) => on ? VybeColors.accentLight : VybeColors.textMuted;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (withModes)
          IconButton(
            tooltip: 'Перемешать',
            onPressed: c.toggleShuffle,
            icon: Icon(Icons.shuffle_rounded, color: modeColor(s.shuffle)),
          ),
        IconButton(
          tooltip: 'Предыдущий',
          onPressed: s.current == null ? null : c.previous,
          icon: Icon(Icons.skip_previous_rounded, size: iconSize),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: PlayButton(
            playing: s.playing,
            loading: s.loading,
            size: size,
            onPressed: s.current == null ? null : c.togglePlay,
          ),
        ),
        IconButton(
          tooltip: 'Следующий',
          onPressed: s.hasNext ? c.next : null,
          icon: Icon(Icons.skip_next_rounded, size: iconSize),
        ),
        if (withModes)
          IconButton(
            tooltip: switch (s.repeat) {
              RepeatPolicy.off => 'Повтор выключен',
              RepeatPolicy.all => 'Повтор очереди',
              RepeatPolicy.one => 'Повтор трека',
            },
            onPressed: c.cycleRepeat,
            icon: Icon(
              s.repeat == RepeatPolicy.one ? Icons.repeat_one_rounded : Icons.repeat_rounded,
              color: modeColor(s.repeat != RepeatPolicy.off),
            ),
          ),
      ],
    );
  }
}

class VolumeControl extends ConsumerWidget {
  const VolumeControl({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = ref.watch(playerProvider.select((s) => s.volume));
    final c = ref.read(playerProvider.notifier);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: v == 0 ? 'Включить звук' : 'Выключить звук',
          onPressed: () => c.setVolume(v == 0 ? 0.8 : 0),
          icon: Icon(
            v == 0 ? Icons.volume_off_rounded : (v < 0.5 ? Icons.volume_down_rounded : Icons.volume_up_rounded),
            color: VybeColors.textMuted,
          ),
        ),
        SizedBox(width: 130, child: Slider(value: v, onChanged: c.setVolume)),
      ],
    );
  }
}

/// Desktop/tablet bottom bar.
class PlayerBar extends ConsumerWidget {
  const PlayerBar({super.key, this.onToggleQueue});

  final VoidCallback? onToggleQueue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = ref.watch(playerProvider.select((s) => s.current));
    final t = Theme.of(context).textTheme;
    final compact = MediaQuery.sizeOf(context).width < 1200;
    return Container(
      height: 84,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: VybeColors.surface,
        border: Border(top: BorderSide(color: VybeColors.border)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: compact ? 220 : 260,
            child: Row(
              children: [
                Artwork(track: track, size: 54),
                const SizedBox(width: 14),
                Expanded(
                  child: track == null
                      ? Text('Ничего не играет', style: t.bodyMedium?.copyWith(color: VybeColors.textMuted))
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.bodyLarge),
                            Text(track.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.bodySmall?.copyWith(color: VybeColors.textMuted)),
                          ],
                        ),
                ),
                if (track != null) LikeButton(track: track, size: 20),
              ],
            ),
          ),
          const Expanded(child: Center(child: FittedBox(child: TransportControls(size: 50)))),
          SizedBox(width: compact ? 220 : 280, child: const SeekBar(inlineTimes: true)),
          if (!compact) const VolumeControl(),
          if (onToggleQueue != null)
            IconButton(tooltip: 'Очередь', onPressed: onToggleQueue, icon: const Icon(Icons.queue_music_rounded, color: VybeColors.textMuted)),
        ],
      ),
    );
  }
}

/// Phone mini-player above the bottom navigation. Tap opens [NowPlayingScreen].
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(playerProvider);
    final track = s.current;
    if (track == null) return const SizedBox.shrink();
    final t = Theme.of(context).textTheme;
    final pos = ref.watch(positionProvider).value ?? Duration.zero;
    final dur = ref.watch(durationProvider).value ?? track.duration ?? Duration.zero;
    final progress = dur.inMilliseconds == 0 ? 0.0 : (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
      child: Material(
        color: VybeColors.surface2,
        borderRadius: BorderRadius.circular(VybeRadius.md),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(NowPlayingScreen.route()),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
                child: Row(
                  children: [
                    Hero(tag: 'artwork', child: Artwork(track: track, size: 42)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                          Text(track.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: t.bodySmall?.copyWith(color: VybeColors.textMuted)),
                        ],
                      ),
                    ),
                    LikeButton(track: track, size: 20),
                    IconButton(
                      onPressed: ref.read(playerProvider.notifier).togglePlay,
                      icon: s.loading
                          ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(s.playing ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 30),
                    ),
                  ],
                ),
              ),
              LinearProgressIndicator(value: progress, minHeight: 2, color: VybeColors.accent, backgroundColor: Colors.transparent),
            ],
          ),
        ),
      ),
    );
  }
}

/// Up-next list, used by the desktop side panel and the phone player.
class QueueList extends ConsumerWidget {
  const QueueList({super.key, this.shrinkWrap = false});

  final bool shrinkWrap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(playerProvider);
    final c = ref.read(playerProvider.notifier);
    final t = Theme.of(context).textTheme;
    if (s.queue.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Очередь пуста', style: t.bodyMedium?.copyWith(color: VybeColors.textMuted)),
      );
    }
    final items = [for (var i = s.index; i < s.queue.length; i++) i];
    return ListView.builder(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: items.length + (s.radioLoading ? 1 : 0),
      itemBuilder: (_, k) {
        if (k == items.length) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Row(children: [
              SizedBox.square(dimension: 14, child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 10),
              Text('Подбираем похожие треки…', style: TextStyle(color: VybeColors.textMuted)),
            ]),
          );
        }
        final i = items[k];
        final track = s.queue[i];
        return TrackTile(
          key: ValueKey('q$i${track.key}'),
          track: track,
          dense: true,
          onTap: () => c.jumpTo(i),
          trailing: i == s.index
              ? const SizedBox(width: 8)
              : IconButton(
                  tooltip: 'Убрать из очереди',
                  onPressed: () => c.removeAt(i),
                  icon: const Icon(Icons.close_rounded, size: 18, color: VybeColors.textMuted),
                ),
        );
      },
    );
  }
}

/// Right-hand "now playing" panel on wide screens, as in the concept.
class NowPlayingPanel extends ConsumerWidget {
  const NowPlayingPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = ref.watch(playerProvider.select((s) => s.current));
    final t = Theme.of(context).textTheme;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Column(
              children: [
                AspectRatio(aspectRatio: 1, child: LayoutBuilder(builder: (_, c) => Artwork(track: track, size: c.maxWidth, radius: VybeRadius.lg))),
                const SizedBox(height: 16),
                Text(track?.title ?? 'Ничего не играет', maxLines: 1, overflow: TextOverflow.ellipsis, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(track?.artist ?? 'Найдите трек в поиске', maxLines: 1, overflow: TextOverflow.ellipsis, style: t.bodyMedium?.copyWith(color: VybeColors.textMuted)),
                const SizedBox(height: 12),
                const SeekBar(),
                const SizedBox(height: 4),
                const TransportControls(withModes: false, size: 52),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 8, 4),
            child: Row(
              children: [
                Expanded(child: Text('Очередь', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w600))),
                TextButton(
                  onPressed: ref.read(playerProvider.notifier).clearUpNext,
                  style: TextButton.styleFrom(foregroundColor: VybeColors.textMuted),
                  child: const Text('Очистить'),
                ),
              ],
            ),
          ),
          const Expanded(child: QueueList()),
        ],
      ),
    );
  }
}

/// Full-screen player for phones.
class NowPlayingScreen extends ConsumerWidget {
  const NowPlayingScreen({super.key});

  static Route<void> route() => PageRouteBuilder(
        pageBuilder: (_, _, _) => const NowPlayingScreen(),
        transitionsBuilder: (_, a, _, child) => SlideTransition(
          position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
          child: child,
        ),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = ref.watch(playerProvider.select((s) => s.current));
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2A1B57), VybeColors.background],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                  child: Row(
                    children: [
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32)),
                      Expanded(child: Text('Сейчас играет', textAlign: TextAlign.center, style: t.titleSmall)),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    children: [
                      LayoutBuilder(
                        builder: (_, c) => Hero(tag: 'artwork', child: Artwork(track: track, size: c.maxWidth, radius: VybeRadius.lg)),
                      ),
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(track?.title ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: t.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                                Text(track?.artist ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: t.bodyLarge?.copyWith(color: VybeColors.textMuted)),
                              ],
                            ),
                          ),
                          if (track != null) LikeButton(track: track, size: 26),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const SeekBar(),
                      const SizedBox(height: 8),
                      const FittedBox(child: TransportControls(size: 68)),
                      const SizedBox(height: 28),
                      Align(alignment: Alignment.centerLeft, child: Text('Далее', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600))),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: QueueList(shrinkWrap: true)),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }
}
