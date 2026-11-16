import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/format.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import '../../data/library_store.dart';
import '../../player/player_controller.dart';
import '../../recommendations/recommendation_service.dart';
import '../navigation.dart';
import '../widgets/common.dart';
import '../widgets/track_tile.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forYou = ref.watch(forYouProvider);
    final recent = ref.watch(libraryProvider.select((s) => s.recentlyPlayed.take(8).toList()));
    final hasHistory = recent.isNotEmpty;

    return RefreshIndicator(
      color: VybeColors.accent,
      onRefresh: () => ref.refresh(forYouProvider.future),
      child: ListView(
        key: const Key('home-list'),
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
        children: [
          _Hero(
            onPlayMix: () {
              final list = forYou.value;
              if (list != null && list.isNotEmpty) ref.read(playerProvider.notifier).playQueue(list);
            },
            onShuffle: () {
              final list = [...?forYou.value]..shuffle();
              if (list.isNotEmpty) ref.read(playerProvider.notifier).playQueue(list);
            },
          ),
          const SizedBox(height: 28),
          const SectionHeader('Сделано для вас'),
          const _MixGrid(),
          const SizedBox(height: 28),
          SectionHeader(
            hasHistory ? 'Рекомендации' : 'Популярное сейчас',
            action: 'Обновить',
            onAction: () => ref.invalidate(forYouProvider),
          ),
          forYou.when(
            data: (list) => list.isEmpty
                ? const EmptyState(
                    icon: Icons.wifi_off_rounded,
                    title: 'Пока нечего рекомендовать',
                    subtitle: 'Проверьте подключение к интернету или найдите трек в поиске',
                  )
                : _TwoColumnTracks(tracks: list.take(10).toList()),
            loading: () => const _ListSkeleton(),
            error: (e, _) => EmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Не удалось загрузить рекомендации',
              subtitle: '$e',
              action: FilledButton(onPressed: () => ref.invalidate(forYouProvider), child: const Text('Повторить')),
            ),
          ),
          if (hasHistory) ...[
            const SizedBox(height: 28),
            SectionHeader(
              'Недавно слушали',
              action: 'Все',
              onAction: () => ref.read(navProvider.notifier).selectTab(AppTab.library),
            ),
            _TwoColumnTracks(tracks: recent),
          ],
        ],
      ),
    );
  }
}

class _Slide {
  const _Slide({
    required this.image,
    required this.subtitle,
    this.title,
    this.mixId,
    this.alignment = Alignment.center,
  });

  final String image;

  /// Null → the personal greeting.
  final String? title;
  final String subtitle;

  /// Null → plays "For you"; otherwise plays that mix.
  final String? mixId;
  final Alignment alignment;
}

const _slides = [
  _Slide(
    image: 'assets/banners/city.jpg',
    subtitle: 'Давайте найдём что-нибудь под настроение…',
    alignment: Alignment(0.4, -0.2),
  ),
  _Slide(
    image: 'assets/banners/moon.jpg',
    title: 'Late Night',
    subtitle: 'Тихие треки для поздних часов',
    mixId: 'late',
    alignment: Alignment(0.6, -0.4),
  ),
  _Slide(
    image: 'assets/banners/concert.jpg',
    title: 'Громче!',
    subtitle: 'Энергия для тренировки и драйва',
    mixId: 'workout',
    alignment: Alignment(0.3, -0.3),
  ),
  _Slide(
    image: 'assets/banners/vinyl.jpg',
    title: 'Chill Vibes',
    subtitle: 'Расслабься — мы подобрали спокойный микс',
    mixId: 'chill',
    alignment: Alignment(0.5, 0),
  ),
];

/// Hero carousel with atmospheric photos (CC0, tinted into the brand palette).
class _Hero extends ConsumerStatefulWidget {
  const _Hero({required this.onPlayMix, required this.onShuffle});

  final VoidCallback onPlayMix;
  final VoidCallback onShuffle;

  @override
  ConsumerState<_Hero> createState() => _HeroState();
}

class _HeroState extends ConsumerState<_Hero> {
  final _pages = PageController();
  int _index = 0;
  Timer? _auto;

  @override
  void initState() {
    super.initState();
    _restartAuto();
  }

  void _restartAuto() {
    _auto?.cancel();
    _auto = Timer.periodic(const Duration(seconds: 9), (_) => _go(_index + 1));
  }

  void _go(int i) {
    if (!_pages.hasClients) return;
    final target = i % _slides.length;
    _pages.animateToPage(target, duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final s in _slides) {
      precacheImage(AssetImage(s.image), context);
    }
  }

  @override
  void dispose() {
    _auto?.cancel();
    _pages.dispose();
    super.dispose();
  }

  Future<void> _play(_Slide slide, {bool shuffle = false}) async {
    if (slide.mixId == null) {
      shuffle ? widget.onShuffle() : widget.onPlayMix();
      return;
    }
    final list = [...await ref.read(mixProvider(slide.mixId!).future)];
    if (shuffle) list.shuffle();
    if (list.isNotEmpty) ref.read(playerProvider.notifier).playQueue(list);
  }

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 720;
    return SizedBox(
      height: narrow ? 240 : 300,
      child: GlassSurface(
        // Rim lights up on the photo side, like the concept's banner.
        accents: const GlassAccents(glowCorner: Alignment.topRight, cornerGlow: false),
        child: _carousel(narrow),
      ),
    );
  }

  Widget _carousel(bool narrow) {
    return Stack(
      children: [
        PageView.builder(
          controller: _pages,
          itemCount: _slides.length,
          onPageChanged: (i) {
            setState(() => _index = i);
            _restartAuto();
          },
          itemBuilder: (_, i) => _SlideView(
            slide: _slides[i],
            narrow: narrow,
            onPlay: () => _play(_slides[i]),
            onShuffle: () => _play(_slides[i], shuffle: true),
          ),
        ),
        Positioned(
          right: narrow ? 12 : 20,
          bottom: narrow ? 10 : 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(VybeRadius.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Назад',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _go(_index - 1 + _slides.length),
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Text('${_index + 1} / ${_slides.length}', style: Theme.of(context).textTheme.bodyMedium),
                IconButton(
                  tooltip: 'Вперёд',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _go(_index + 1),
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SlideView extends ConsumerWidget {
  const _SlideView({required this.slide, required this.narrow, required this.onPlay, required this.onShuffle});

  final _Slide slide;
  final bool narrow;
  final VoidCallback onPlay;
  final VoidCallback onShuffle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final name = ref.watch(libraryProvider.select((s) => s.settings.userName));
    final greeting = greetingFor(DateTime.now());
    final title = slide.title ?? (name.isEmpty ? '$greeting!' : '$greeting,\n$name');

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(slide.image, fit: BoxFit.cover, alignment: slide.alignment),
        // Keep text readable: dark on the left, photo shows through on the right.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                VybeColors.background.withValues(alpha: 0.92),
                VybeColors.background.withValues(alpha: narrow ? 0.6 : 0.45),
                VybeColors.background.withValues(alpha: 0.0),
              ],
              stops: const [0.0, 0.45, 0.85],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.center,
              colors: [VybeColors.background.withValues(alpha: 0.55), Colors.transparent],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(narrow ? 22 : 44, 20, narrow ? 22 : 44, narrow ? 20 : 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: (narrow ? t.headlineSmall : t.displaySmall)?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  EqualizerIcon(size: narrow ? 20 : 28),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                slide.subtitle,
                maxLines: 2,
                style: t.bodyLarge?.copyWith(color: VybeColors.text.withValues(alpha: 0.85)),
              ),
              SizedBox(height: narrow ? 16 : 24),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: onPlay,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(slide.mixId == null ? 'Слушать микс' : 'Слушать'),
                    style: FilledButton.styleFrom(
                      backgroundColor: VybeColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                      shape: const StadiumBorder(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filledTonal(
                    tooltip: 'Перемешать',
                    onPressed: onShuffle,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.12),
                      foregroundColor: VybeColors.text,
                    ),
                    icon: const Icon(Icons.shuffle_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MixGrid extends StatelessWidget {
  const _MixGrid();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final columns = c.maxWidth >= 900 ? 4 : 2;
        const gap = 16.0;
        final w = (c.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final m in mixes)
              SizedBox(
                width: w,
                height: w * 0.72,
                child: MixCard(mix: m),
              ),
          ],
        );
      },
    );
  }
}

class MixCard extends ConsumerWidget {
  const MixCard({super.key, required this.mix});

  final Mix mix;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    return CustomPaint(
      foregroundPainter: const GlassRimPainter(
        accents: GlassAccents(glowCorner: Alignment.topLeft, rimStrength: 0.8),
        radius: VybeRadius.lg,
      ),
      child: Material(
        borderRadius: BorderRadius.circular(VybeRadius.lg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => ref.read(navProvider.notifier).push(MixDestination(mix.id)),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: mix.colors),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -10,
                  top: -6,
                  child: Icon(mix.icon, size: 110, color: Colors.white.withValues(alpha: 0.18)),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.55)],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 12,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mix.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              mix.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: t.bodySmall?.copyWith(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filled(
                        tooltip: 'Слушать',
                        onPressed: () async {
                          final list = await ref.read(mixProvider(mix.id).future);
                          if (list.isNotEmpty) ref.read(playerProvider.notifier).playQueue(list);
                        },
                        style: IconButton.styleFrom(backgroundColor: Colors.black.withValues(alpha: 0.45)),
                        icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Two columns of numbered tracks on wide screens, one on phones (as in the concept's "Trending Now").
class _TwoColumnTracks extends StatelessWidget {
  const _TwoColumnTracks({required this.tracks});

  final List<Track> tracks;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, c) {
        final twoCols = c.maxWidth >= 820;
        Widget tile(int i) => TrackTile(track: tracks[i], queue: tracks, index: i, number: i + 1);
        if (!twoCols) return Column(children: [for (var i = 0; i < tracks.length; i++) tile(i)]);
        final half = (tracks.length / 2).ceil();
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Column(children: [for (var i = 0; i < half; i++) tile(i)])),
            const SizedBox(width: 24),
            Expanded(child: Column(children: [for (var i = half; i < tracks.length; i++) tile(i)])),
          ],
        );
      },
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < 4; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: VybeColors.surface2,
                    borderRadius: BorderRadius.circular(VybeRadius.sm),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 12, width: 180, color: VybeColors.surface2),
                      const SizedBox(height: 8),
                      Container(height: 10, width: 110, color: VybeColors.surface2),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
