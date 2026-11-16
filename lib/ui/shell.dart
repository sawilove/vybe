import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/theme.dart';
import '../l10n/l10n.dart';
import '../data/download_manager.dart';
import '../data/library_store.dart';
import '../player/player_controller.dart';
import '../recommendations/recommendation_service.dart';
import 'navigation.dart';
import 'screens/home_screen.dart';
import 'screens/library_screens.dart';
import 'screens/search_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/common.dart';
import 'widgets/player_widgets.dart';

/// Breakpoints from docs/ARCHITECTURE.md.
const kWideBreakpoint = 1200.0;
const kPhoneBreakpoint = 720.0;

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  final _searchFocus = FocusNode();
  bool _queueOpen = true;

  @override
  void dispose() {
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final phone = width < kPhoneBreakpoint;
    final wide = width >= kWideBreakpoint;

    // Keeps the download manager alive so liked tracks get downloaded in the background.
    ref.listen(downloadsProvider.select((s) => s.failed), (prev, next) {
      final fresh = next.entries.where((e) => !(prev?.containsKey(e.key) ?? false));
      for (final e in fresh.take(1)) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.downloadFailed(e.value))));
      }
    });
    ref.listen(playerProvider.select((s) => s.error), (_, err) {
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.playbackFailed(err))));
      }
    });

    final shortcuts = <ShortcutActivator, VoidCallback>{
      const SingleActivator(LogicalKeyboardKey.slash): () => _searchFocus.requestFocus(),
      const SingleActivator(LogicalKeyboardKey.space, control: true): () =>
          ref.read(playerProvider.notifier).togglePlay(),
      const SingleActivator(LogicalKeyboardKey.arrowRight, control: true): () =>
          ref.read(playerProvider.notifier).next(),
      const SingleActivator(LogicalKeyboardKey.arrowLeft, control: true): () =>
          ref.read(playerProvider.notifier).previous(),
    };

    final body = phone ? _phone() : _desktop(wide);
    return AmbientBackground(
      child: CallbackShortcuts(
        bindings: shortcuts,
        child: Focus(autofocus: true, child: body),
      ),
    );
  }

  Widget _content({required bool phone}) {
    final nav = ref.watch(navProvider);
    final page = switch (nav.top) {
      MixDestination(:final mixId) => MixScreen(mixId: mixId),
      TabDestination(:final tab) => switch (tab) {
        AppTab.home => const HomeScreen(),
        AppTab.search => SearchScreen(showField: phone),
        AppTab.library => const LibraryScreen(),
        AppTab.liked => const LikedScreen(),
        AppTab.settings => const SettingsScreen(),
      },
    };
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: KeyedSubtree(key: ValueKey(nav.top.runtimeType.toString() + nav.tab.name), child: page),
    );
  }

  Widget _desktop(bool wide) {
    final showPanel = wide && _queueOpen;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(width: 240, child: _Sidebar()),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            if (ref.watch(navProvider).canPop)
                              IconButton(
                                onPressed: ref.read(navProvider.notifier).pop,
                                icon: const Icon(Icons.arrow_back_rounded),
                              ),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 520),
                              child: SearchField(focusNode: _searchFocus),
                            ),
                            const Spacer(),
                            const _UserChip(),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Expanded(child: _content(phone: false)),
                      ],
                    ),
                  ),
                  if (showPanel) ...[const SizedBox(width: 20), const SizedBox(width: 320, child: NowPlayingPanel())],
                ],
              ),
            ),
          ),
          PlayerBar(onToggleQueue: wide ? () => setState(() => _queueOpen = !_queueOpen) : null),
        ],
      ),
    );
  }

  Widget _phone() {
    final nav = ref.watch(navProvider);
    const tabs = [AppTab.home, AppTab.search, AppTab.library, AppTab.liked];
    final selected = tabs.indexOf(nav.tab);
    return PopScope(
      canPop: !nav.canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) ref.read(navProvider.notifier).pop();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          titleSpacing: 16,
          leading: nav.canPop ? null : null,
          automaticallyImplyLeading: false,
          title: const VybeLogo(size: 28),
          actions: [
            IconButton(
              tooltip: context.l10n.navSettings,
              onPressed: () => ref.read(navProvider.notifier).selectTab(AppTab.settings),
              icon: const Icon(Icons.settings_outlined),
            ),
          ],
        ),
        body: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _content(phone: true)),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MiniPlayer(),
            NavigationBar(
              height: 64,
              selectedIndex: selected < 0 ? 0 : selected,
              onDestinationSelected: (i) => ref.read(navProvider.notifier).selectTab(tabs[i]),
              destinations: [
                for (final t in tabs)
                  NavigationDestination(
                    icon: Icon(t.iconOutlined),
                    selectedIcon: Icon(t.icon),
                    label: t.label(context.l10n),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Sidebar extends ConsumerWidget {
  const _Sidebar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nav = ref.watch(navProvider);
    final t = Theme.of(context).textTheme;

    Widget item(AppTab tab) {
      final selected = nav.tab == tab;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Material(
          color: selected ? VybeColors.surface2 : Colors.transparent,
          borderRadius: BorderRadius.circular(VybeRadius.md),
          child: InkWell(
            borderRadius: BorderRadius.circular(VybeRadius.md),
            onTap: () => ref.read(navProvider.notifier).selectTab(tab),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: selected
                  ? const BoxDecoration(
                      border: Border(left: BorderSide(color: VybeColors.accent, width: 3)),
                    )
                  : null,
              child: Row(
                children: [
                  Icon(
                    selected ? tab.icon : tab.iconOutlined,
                    color: selected ? VybeColors.text : VybeColors.textMuted,
                    size: 22,
                  ),
                  const SizedBox(width: 14),
                  Text(
                    tab.label(context.l10n),
                    style: t.bodyLarge?.copyWith(
                      color: selected ? VybeColors.text : VybeColors.textMuted,
                      fontWeight: selected ? FontWeight.w500 : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Panel(
      accents: const GlassAccents(glowCorner: Alignment.bottomLeft, rimStrength: 0.9, wave: Alignment.bottomLeft),
      padding: const EdgeInsets.fromLTRB(12, 22, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(padding: EdgeInsets.only(left: 10, bottom: 26), child: VybeLogo()),
          for (final tab in AppTab.values.where((t) => t != AppTab.settings)) item(tab),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 24, 10, 8),
            child: Text(
              context.l10n.yourMixes,
              style: t.bodyMedium?.copyWith(color: VybeColors.textMuted, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                for (final m in mixes)
                  ListTile(
                    dense: true,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(VybeRadius.sm)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    leading: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: m.colors),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(m.icon, size: 16, color: Colors.white),
                    ),
                    title: Text(m.title, style: t.bodyMedium),
                    onTap: () {
                      ref.read(navProvider.notifier)
                        ..selectTab(AppTab.home)
                        ..push(MixDestination(m.id));
                    },
                  ),
              ],
            ),
          ),
          const Divider(),
          item(AppTab.settings),
        ],
      ),
    );
  }
}

class _UserChip extends ConsumerWidget {
  const _UserChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(libraryProvider.select((s) => s.settings.userName));
    final t = Theme.of(context).textTheme;
    return InkWell(
      borderRadius: BorderRadius.circular(VybeRadius.pill),
      onTap: () => ref.read(navProvider.notifier).selectTab(AppTab.settings),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: VybeColors.accent,
              child: Text(
                name.isEmpty ? 'V' : name.characters.first.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
            if (name.isNotEmpty) ...[
              const SizedBox(width: 10),
              Text(name, style: t.bodyMedium),
              const SizedBox(width: 6),
            ],
          ],
        ),
      ),
    );
  }
}
