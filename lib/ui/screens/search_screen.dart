import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/models.dart';
import '../../core/theme.dart';
import '../../sources/source_registry.dart';
import '../navigation.dart';
import '../widgets/common.dart';
import '../widgets/track_tile.dart';

final searchResultsProvider = FutureProvider.family<SearchResults, String>((ref, q) async {
  if (q.trim().isEmpty) return const SearchResults({}, {});
  return ref.watch(sourceRegistryProvider).searchAll(q);
});

/// "Write the name — get the track", like a Telegram music bot.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.showField = true});

  /// On desktop the field lives in the top bar instead.
  final bool showField;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  SourceKind? _filter;

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final t = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showField) ...[
          const SearchField(autofocus: true),
          const SizedBox(height: 14),
        ],
        Wrap(spacing: 8, children: [
          _chip('Все', null),
          for (final k in SourceKind.values) _chip(k.label, k),
        ]),
        const SizedBox(height: 12),
        Expanded(
          child: query.trim().isEmpty
              ? const EmptyState(
                  icon: Icons.manage_search_rounded,
                  title: 'Напишите название трека или артиста',
                  subtitle: 'Например: «Hozier Too Sweet» — VYBE поищет сразу во всех источниках',
                )
              : ref.watch(searchResultsProvider(query)).when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => EmptyState(icon: Icons.error_outline_rounded, title: 'Ошибка поиска', subtitle: '$e'),
                    data: (r) {
                      final list = _filter == null ? r.all : (r.bySource[_filter] ?? const []);
                      if (list.isEmpty) {
                        final yErr = r.errors[SourceKind.youtube];
                        return EmptyState(
                          icon: Icons.search_off_rounded,
                          title: 'Ничего не нашли по «$query»',
                          subtitle: yErr != null ? 'YouTube недоступен: $yErr' : 'Попробуйте написать иначе',
                        );
                      }
                      return ListView.builder(
                        itemCount: list.length + 1,
                        itemBuilder: (_, i) => i == 0
                            ? Padding(
                                padding: const EdgeInsets.only(left: 10, bottom: 6),
                                child: Text('Найдено: ${list.length}', style: t.bodySmall?.copyWith(color: VybeColors.textMuted)),
                              )
                            // Tapping a result plays just that track; radio continues it.
                            : TrackTile(track: list[i - 1]),
                      );
                    },
                  ),
        ),
      ],
    );
  }

  Widget _chip(String label, SourceKind? kind) => ChoiceChip(
        label: Text(label),
        selected: _filter == kind,
        onSelected: (_) => setState(() => _filter = kind),
        selectedColor: VybeColors.accent,
        backgroundColor: VybeColors.surface,
        side: const BorderSide(color: VybeColors.border),
        shape: const StadiumBorder(),
        showCheckmark: false,
      );
}

/// Debounced search field bound to [searchQueryProvider].
class SearchField extends ConsumerStatefulWidget {
  const SearchField({super.key, this.autofocus = false, this.focusNode, this.onSubmitted});

  final bool autofocus;
  final FocusNode? focusNode;
  final VoidCallback? onSubmitted;

  @override
  ConsumerState<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends ConsumerState<SearchField> {
  late final _controller = TextEditingController(text: ref.read(searchQueryProvider));
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _submit(String v, {bool now = false}) {
    _debounce?.cancel();
    void apply() {
      ref.read(searchQueryProvider.notifier).set(v.trim());
      final nav = ref.read(navProvider);
      if (v.trim().isNotEmpty && nav.tab != AppTab.search) {
        ref.read(navProvider.notifier).selectTab(AppTab.search);
      }
    }

    if (now) {
      apply();
      widget.onSubmitted?.call();
    } else {
      _debounce = Timer(const Duration(milliseconds: 450), apply);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(searchQueryProvider, (_, next) {
      if (next != _controller.text.trim()) _controller.text = next;
    });
    return TextField(
      controller: _controller,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      textInputAction: TextInputAction.search,
      onChanged: _submit,
      onSubmitted: (v) => _submit(v, now: true),
      decoration: InputDecoration(
        hintText: 'Артисты, треки, плейлисты…',
        prefixIcon: const Icon(Icons.search_rounded, color: VybeColors.textMuted),
        suffixIcon: ListenableBuilder(
          listenable: _controller,
          builder: (_, _) => _controller.text.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
                  onPressed: () {
                    _controller.clear();
                    _submit('', now: true);
                  },
                  icon: const Icon(Icons.close_rounded, color: VybeColors.textMuted),
                ),
        ),
      ),
    );
  }
}
