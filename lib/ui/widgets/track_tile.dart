import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/l10n.dart';

import '../../core/format.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../data/download_manager.dart';
import '../../data/library_store.dart';
import '../../player/player_controller.dart';
import 'common.dart';

/// A row in any track list. Tapping plays [queue] from [index].
class TrackTile extends ConsumerWidget {
  const TrackTile({
    super.key,
    required this.track,
    this.queue,
    this.index,
    this.number,
    this.dense = false,
    this.onTap,
    this.trailing,
  });

  final Track track;
  final List<Track>? queue;
  final int? index;
  final int? number;
  final bool dense;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(playerProvider.select((s) => s.current));
    final playing = ref.watch(playerProvider.select((s) => s.playing));
    final isCurrent = current?.key == track.key;
    final downloaded = ref.watch(downloadsProvider.select((d) => d.isDownloaded(track)));
    final queued = ref.watch(downloadsProvider.select((d) => d.isQueued(track)));
    final t = Theme.of(context).textTheme;

    return Material(
      color: isCurrent ? VybeColors.surface2 : Colors.transparent,
      borderRadius: BorderRadius.circular(VybeRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(VybeRadius.md),
        onTap:
            onTap ??
            () {
              final q = queue ?? [track];
              ref.read(playerProvider.notifier).playQueue(q, startIndex: index ?? q.indexOf(track).clamp(0, q.length));
            },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: dense ? 6 : 8),
          child: Row(
            children: [
              if (number != null)
                SizedBox(
                  width: 32,
                  child: Text('$number', style: t.bodyLarge?.copyWith(color: VybeColors.textMuted)),
                ),
              Artwork(track: track, size: dense ? 40 : 46),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: isCurrent ? VybeColors.accentLight : VybeColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (track.source == SourceKind.local || downloaded) ...[
                          const Icon(Icons.download_done_rounded, size: 14, color: VybeColors.accentLight),
                          const SizedBox(width: 4),
                        ] else if (queued) ...[
                          const SizedBox.square(dimension: 12, child: CircularProgressIndicator(strokeWidth: 1.5)),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            track.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.bodySmall?.copyWith(color: VybeColors.textMuted),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isCurrent) ...[EqualizerIcon(animate: playing), const SizedBox(width: 12)],
              if (track.duration != null && !dense)
                Padding(
                  padding: const EdgeInsets.only(left: 8, right: 4),
                  child: Text(
                    formatDuration(track.duration),
                    style: t.bodyMedium?.copyWith(color: VybeColors.textMuted),
                  ),
                ),
              trailing ?? TrackMenu(track: track),
            ],
          ),
        ),
      ),
    );
  }
}

class TrackMenu extends ConsumerWidget {
  const TrackMenu({super.key, required this.track});

  final Track track;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liked = ref.watch(libraryProvider.select((s) => s.isLiked(track)));
    final downloaded = ref.watch(downloadsProvider.select((d) => d.isDownloaded(track)));
    void toast(String m) =>
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), duration: const Duration(seconds: 2)));

    return PopupMenuButton<String>(
      tooltip: context.l10n.more,
      icon: const Icon(Icons.more_vert_rounded, color: VybeColors.textMuted, size: 20),
      color: VybeColors.surface2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VybeRadius.md)),
      onSelected: (v) {
        final player = ref.read(playerProvider.notifier);
        switch (v) {
          case 'next':
            player.playNext(track);
            toast(context.l10n.willPlayNext);
          case 'queue':
            player.addToQueue(track);
            toast(context.l10n.addedToQueue);
          case 'like':
            ref.read(libraryProvider.notifier).toggleLike(track);
          case 'radio':
            player.playTrack(track);
          case 'download':
            ref.read(downloadsProvider.notifier).enqueue(track);
          case 'undownload':
            ref.read(downloadsProvider.notifier).remove(track);
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(value: 'next', child: _MenuRow(Icons.playlist_play_rounded, context.l10n.playNext)),
        PopupMenuItem(value: 'queue', child: _MenuRow(Icons.queue_music_rounded, context.l10n.addToQueue)),
        PopupMenuItem(
          value: 'like',
          child: _MenuRow(
            liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            liked ? context.l10n.unlike : context.l10n.like,
          ),
        ),
        PopupMenuItem(value: 'radio', child: _MenuRow(Icons.radio_rounded, context.l10n.trackRadio)),
        if (track.source != SourceKind.local)
          downloaded
              ? PopupMenuItem(
                  value: 'undownload',
                  child: _MenuRow(Icons.delete_outline_rounded, context.l10n.removeDownload),
                )
              : PopupMenuItem(value: 'download', child: _MenuRow(Icons.download_rounded, context.l10n.download)),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(children: [Icon(icon, size: 18), const SizedBox(width: 12), Text(label)]);
}

class LikeButton extends ConsumerWidget {
  const LikeButton({super.key, required this.track, this.size = 22});

  final Track track;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liked = ref.watch(libraryProvider.select((s) => s.isLiked(track)));
    return IconButton(
      tooltip: liked ? context.l10n.unlike : context.l10n.like,
      onPressed: () => ref.read(libraryProvider.notifier).toggleLike(track),
      icon: Icon(
        liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        color: liked ? VybeColors.accentLight : VybeColors.textMuted,
        size: size,
      ),
    );
  }
}
