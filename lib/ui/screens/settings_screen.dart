import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models.dart';
import '../../core/theme.dart';
import '../../core/version.dart';
import '../../data/download_manager.dart';
import '../../data/library_store.dart';
import '../../l10n/l10n.dart';
import '../../recommendations/recommendation_service.dart';
import '../../sources/source_registry.dart';
import '../widgets/common.dart';

/// Where the docs explain how to get a token for each source.
final _sourcesGuide = Uri.parse('https://github.com/sawilove/vybe/blob/main/docs/SOURCES.md');

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final AppSettings _initial = ref.read(libraryProvider).settings;
  late final _name = TextEditingController(text: _initial.userName);
  late final _lfm = TextEditingController(text: _initial.lastFmApiKey);
  late final _ym = TextEditingController(text: _initial.yandexToken);
  late final _vk = TextEditingController(text: _initial.vkToken);
  late final _vkUa = TextEditingController(text: _initial.vkUserAgent);
  late final _sc = TextEditingController(text: _initial.soundcloudClientId);

  @override
  void dispose() {
    for (final c in [_name, _lfm, _ym, _vk, _vkUa, _sc]) {
      c.dispose();
    }
    super.dispose();
  }

  void _update(AppSettings Function(AppSettings) f) =>
      ref.read(libraryProvider.notifier).updateSettings(f(ref.read(libraryProvider).settings));

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(libraryProvider.select((l) => l.settings));
    final registry = ref.watch(sourceRegistryProvider);
    final downloads = ref.watch(downloadsProvider);
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final muted = t.bodyMedium?.copyWith(color: VybeColors.textMuted);

    Widget section(String title, List<Widget> children) => Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Panel(
        accents: const GlassAccents(glowCorner: Alignment.topLeft, rimStrength: 0.7),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );

    Widget secret(TextEditingController c, String label, void Function(String) save) => Padding(
      padding: const EdgeInsets.only(top: 10),
      child: TextField(
        controller: c,
        obscureText: true,
        autocorrect: false,
        enableSuggestions: false,
        decoration: InputDecoration(labelText: label),
        onChanged: (v) => save(v.trim()),
      ),
    );

    Widget sourceTile(SourceKind kind, {String? hint, List<Widget> fields = const []}) {
      final source = registry.of(kind);
      final enabled = s.isEnabled(kind);
      final ready = source.isConfigured;
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(kind == SourceKind.local ? l.local : kind.label, style: t.titleSmall)),
                if (enabled)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      !ready
                          ? l.needsSetup
                          : kind == SourceKind.yandex && s.yandexToken.isEmpty
                          ? l.searchOnly
                          : l.ready,
                      style: t.labelMedium?.copyWith(
                        color: ready && !(kind == SourceKind.yandex && s.yandexToken.isEmpty)
                            ? VybeColors.online
                            : VybeColors.accentLight,
                      ),
                    ),
                  ),
                Switch(
                  value: enabled,
                  onChanged: (on) => _update(
                    (s) => s.copyWith(
                      disabledSources: on ? ({...s.disabledSources}..remove(kind)) : {...s.disabledSources, kind},
                    ),
                  ),
                ),
              ],
            ),
            if (enabled && hint != null) ...[
              Text(hint, style: muted),
              ...fields,
              TextButton.icon(
                onPressed: () => launchUrl(_sourcesGuide, mode: LaunchMode.externalApplication),
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: Text(l.howToGet),
              ),
            ],
          ],
        ),
      );
    }

    return ListView(
      children: [
        Text(l.navSettings, style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 20),
        section(l.profile, [
          TextField(
            controller: _name,
            decoration: InputDecoration(labelText: l.yourName),
            onChanged: (v) => _update((s) => s.copyWith(userName: v.trim())),
          ),
          const SizedBox(height: 16),
          Text(l.language, style: t.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: '', label: Text(l.languageSystem)),
              const ButtonSegment(value: 'en', label: Text('English')),
              const ButtonSegment(value: 'ru', label: Text('Русский')),
            ],
            selected: {s.locale},
            onSelectionChanged: (v) => _update((s) => s.copyWith(locale: v.first)),
          ),
        ]),
        section(l.sources, [
          Text(l.sourcesHint, style: muted),
          const SizedBox(height: 12),
          sourceTile(SourceKind.youtube),
          sourceTile(SourceKind.audius),
          sourceTile(
            SourceKind.yandex,
            hint: l.yandexHint,
            fields: [secret(_ym, l.yandexToken, (v) => _update((s) => s.copyWith(yandexToken: v)))],
          ),
          sourceTile(
            SourceKind.vk,
            hint: l.vkHint,
            fields: [
              secret(_vk, l.vkToken, (v) => _update((s) => s.copyWith(vkToken: v))),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: TextField(
                  controller: _vkUa,
                  decoration: InputDecoration(labelText: l.vkUserAgent),
                  onChanged: (v) => _update((s) => s.copyWith(vkUserAgent: v.trim())),
                ),
              ),
            ],
          ),
          sourceTile(
            SourceKind.soundcloud,
            hint: l.soundcloudHint,
            fields: [secret(_sc, l.soundcloudClientId, (v) => _update((s) => s.copyWith(soundcloudClientId: v)))],
          ),
          sourceTile(SourceKind.local),
        ]),
        section(l.playback, [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: s.autoRadio,
            onChanged: (v) => _update((s) => s.copyWith(autoRadio: v)),
            title: Text(l.autoRadio),
            subtitle: Text(l.autoRadioHint),
          ),
        ]),
        section(l.offline, [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: s.autoDownloadLiked,
            onChanged: (v) => _update((s) => s.copyWith(autoDownloadLiked: v)),
            title: Text(l.autoDownloadLiked),
            subtitle: Text(l.autoDownloadHint),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FutureBuilder<int>(
                  // Recomputed when the number of downloads changes.
                  key: ValueKey(downloads.files.length),
                  future: ref.read(downloadsProvider.notifier).sizeInBytes(),
                  builder: (_, snap) => Text(
                    '${l.trackCount(downloads.downloaded.length)} · ${l.storageUsed(formatBytes(snap.data ?? 0))}',
                    style: muted,
                  ),
                ),
              ),
              TextButton(
                onPressed: downloads.downloaded.isEmpty ? null : () => ref.read(downloadsProvider.notifier).clear(),
                child: Text(l.clearDownloads),
              ),
            ],
          ),
        ]),
        section(l.recommended, [
          Text(l.recsHint, style: muted),
          const SizedBox(height: 12),
          TextField(
            controller: _lfm,
            decoration: InputDecoration(labelText: l.lastFmKey, hintText: 'last.fm/api/account/create'),
            onSubmitted: (v) {
              _update((s) => s.copyWith(lastFmApiKey: v.trim()));
              ref.invalidate(forYouProvider);
            },
          ),
        ]),
        section(l.about, [
          const VybeLogo(size: 36, showTagline: true),
          const SizedBox(height: 12),
          Text('v$appVersion', style: t.labelLarge?.copyWith(color: VybeColors.accentLight)),
          const SizedBox(height: 6),
          Text(l.aboutText, style: muted),
        ]),
      ],
    );
  }
}

String formatBytes(int bytes) {
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  if (bytes < 1024 * 1024 * 1024) return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
}
