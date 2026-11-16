import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/models.dart';
import '../../core/theme.dart';
import '../../data/library_store.dart';
import '../../player/player_controller.dart';
import '../../recommendations/recommendation_service.dart';
import '../../sources/local_source.dart';
import '../navigation.dart';
import '../widgets/common.dart';
import '../widgets/track_tile.dart';

/// Header with title, count and "play all" / "shuffle".
class _ListHeader extends ConsumerWidget {
  const _ListHeader({required this.title, required this.tracks, this.subtitle, this.extra});

  final String title;
  final String? subtitle;
  final List<Track> tracks;
  final Widget? extra;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final player = ref.read(playerProvider.notifier);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              Text(subtitle ?? '${tracks.length} треков', style: t.bodyMedium?.copyWith(color: VybeColors.textMuted)),
            ],
          ),
          const SizedBox(width: 12),
          PlayButton(playing: false, size: 46, onPressed: tracks.isEmpty ? null : () => player.playQueue(tracks)),
          IconButton(
            tooltip: 'Перемешать',
            onPressed: tracks.isEmpty
                ? null
                : () => player.playQueue([...tracks]..shuffle()),
            icon: const Icon(Icons.shuffle_rounded),
          ),
          ?extra,
        ],
      ),
    );
  }
}

class _TrackList extends StatelessWidget {
  const _TrackList({required this.tracks, this.trailingBuilder});

  final List<Track> tracks;
  final Widget Function(Track)? trailingBuilder;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: tracks.length,
      itemBuilder: (_, i) => TrackTile(
        track: tracks[i],
        queue: tracks,
        index: i,
        number: i + 1,
        trailing: trailingBuilder?.call(tracks[i]),
      ),
    );
  }
}

class LikedScreen extends ConsumerWidget {
  const LikedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liked = ref.watch(libraryProvider.select((s) => s.liked));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ListHeader(title: 'Любимые треки', tracks: liked),
        Expanded(
          child: liked.isEmpty
              ? const EmptyState(
                  icon: Icons.favorite_border_rounded,
                  title: 'Здесь будут ваши любимые треки',
                  subtitle: 'Нажмите ♥ у любого трека. Лайки помогают точнее подбирать рекомендации',
                )
              : _TrackList(tracks: liked),
        ),
      ],
    );
  }
}

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> with SingleTickerProviderStateMixin {
  late final _tabs = TabController(length: 2, vsync: this);
  bool _importing = false;

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _import() async {
    setState(() => _importing = true);
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: LocalSource.audioExtensions,
      );
      final paths = files.map((f) => f.path).whereType<String>();
      final tracks = <Track>[];
      for (final p in paths) {
        tracks.add(LocalSource.trackFromPath(await LocalSource.persistPickedFile(p)));
      }
      ref.read(libraryProvider.notifier).addLocalTracks(tracks);
      if (mounted && tracks.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Добавлено файлов: ${tracks.length}')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Не удалось импортировать: $e')));
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lib = ref.watch(libraryProvider);
    final history = lib.recentlyPlayed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: VybeColors.accent,
          labelColor: VybeColors.text,
          unselectedLabelColor: VybeColors.textMuted,
          dividerColor: Colors.transparent,
          tabs: const [Tab(text: 'Мои файлы'), Tab(text: 'История')],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ListHeader(
                    title: 'Мои файлы',
                    tracks: lib.localTracks,
                    extra: FilledButton.tonalIcon(
                      onPressed: _importing ? null : _import,
                      icon: _importing
                          ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.add_rounded),
                      label: const Text('Добавить'),
                    ),
                  ),
                  Expanded(
                    child: lib.localTracks.isEmpty
                        ? EmptyState(
                            icon: Icons.folder_open_rounded,
                            title: 'Добавьте музыку с устройства',
                            subtitle: 'MP3, M4A, FLAC, OGG, OPUS, WAV. Название берётся из имени файла «Артист - Трек»',
                            action: FilledButton.icon(onPressed: _import, icon: const Icon(Icons.add_rounded), label: const Text('Выбрать файлы')),
                          )
                        : _TrackList(
                            tracks: lib.localTracks,
                            trailingBuilder: (t) => IconButton(
                              tooltip: 'Убрать из медиатеки',
                              onPressed: () => ref.read(libraryProvider.notifier).removeLocalTrack(t),
                              icon: const Icon(Icons.remove_circle_outline_rounded, size: 20, color: VybeColors.textMuted),
                            ),
                          ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ListHeader(
                    title: 'История',
                    tracks: history,
                    extra: TextButton(
                      onPressed: history.isEmpty ? null : ref.read(libraryProvider.notifier).clearHistory,
                      child: const Text('Очистить'),
                    ),
                  ),
                  Expanded(
                    child: history.isEmpty
                        ? const EmptyState(icon: Icons.history_rounded, title: 'Вы ещё ничего не слушали')
                        : _TrackList(tracks: history),
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

class MixScreen extends ConsumerWidget {
  const MixScreen({super.key, required this.mixId});

  final String mixId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mix = mixes.firstWhere((m) => m.id == mixId);
    final tracks = ref.watch(mixProvider(mixId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          IconButton(onPressed: ref.read(navProvider.notifier).pop, icon: const Icon(Icons.arrow_back_rounded)),
          const SizedBox(width: 8),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(gradient: LinearGradient(colors: mix.colors), borderRadius: BorderRadius.circular(VybeRadius.md)),
            child: Icon(mix.icon, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(child: _ListHeader(title: mix.title, subtitle: mix.subtitle, tracks: tracks.value ?? const [])),
        ]),
        Expanded(
          child: tracks.when(
            data: (list) => list.isEmpty
                ? const EmptyState(icon: Icons.wifi_off_rounded, title: 'Не удалось собрать микс')
                : _TrackList(tracks: list),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => EmptyState(icon: Icons.error_outline_rounded, title: 'Ошибка', subtitle: '$e'),
          ),
        ),
      ],
    );
  }
}

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final _name = TextEditingController(text: ref.read(libraryProvider).settings.userName);
  late final _lfm = TextEditingController(text: ref.read(libraryProvider).settings.lastFmApiKey);

  @override
  void dispose() {
    _name.dispose();
    _lfm.dispose();
    super.dispose();
  }

  void _update(AppSettings Function(AppSettings) f) {
    final store = ref.read(libraryProvider.notifier);
    store.updateSettings(f(ref.read(libraryProvider).settings));
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(libraryProvider.select((l) => l.settings));
    final t = Theme.of(context).textTheme;
    Widget section(String title, List<Widget> children) => Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Panel(
            accents: const GlassAccents(glowCorner: Alignment.topLeft, rimStrength: 0.7),
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 14),
              ...children,
            ]),
          ),
        );

    return ListView(
      children: [
        Text('Настройки', style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 20),
        section('Профиль', [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Как к вам обращаться?'),
            onChanged: (v) => _update((s) => s.copyWith(userName: v.trim())),
          ),
        ]),
        section('Воспроизведение', [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: s.autoRadio,
            onChanged: (v) => _update((s) => s.copyWith(autoRadio: v)),
            title: const Text('Авто-радио'),
            subtitle: const Text('Когда очередь закончится, VYBE продолжит похожими треками'),
          ),
        ]),
        section('Рекомендации', [
          Text(
            'Рекомендации считаются прямо на устройстве по вашей истории и лайкам. '
            'Чтобы улучшить их, можно подключить бесплатный ключ Last.fm API.',
            style: t.bodyMedium?.copyWith(color: VybeColors.textMuted),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _lfm,
            decoration: const InputDecoration(labelText: 'Last.fm API key (необязательно)', hintText: 'last.fm/api/account/create'),
            onSubmitted: (v) {
              _update((s) => s.copyWith(lastFmApiKey: v.trim()));
              ref.invalidate(forYouProvider);
            },
          ),
        ]),
        section('О приложении', [
          const VybeLogo(size: 36, showTagline: true),
          const SizedBox(height: 12),
          Text(
            'Your sound. Your freedom.\n'
            'VYBE — open-source клиент для стриминга музыки (MIT). '
            'Все данные хранятся только на этом устройстве.',
            style: t.bodyMedium?.copyWith(color: VybeColors.textMuted),
          ),
        ]),
      ],
    );
  }
}
