import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

enum AppTab {
  home('Главная', Icons.home_rounded, Icons.home_outlined),
  search('Поиск', Icons.search_rounded, Icons.search_rounded),
  library('Медиатека', Icons.library_music_rounded, Icons.library_music_outlined),
  liked('Любимые', Icons.favorite_rounded, Icons.favorite_border_rounded),
  settings('Настройки', Icons.settings_rounded, Icons.settings_outlined);

  const AppTab(this.label, this.icon, this.iconOutlined);
  final String label;
  final IconData icon;
  final IconData iconOutlined;
}

/// What the main content area shows: a tab, optionally with a detail page
/// (e.g. a mix) pushed on top.
sealed class Destination {
  const Destination();
}

class TabDestination extends Destination {
  const TabDestination(this.tab);
  final AppTab tab;
}

class MixDestination extends Destination {
  const MixDestination(this.mixId);
  final String mixId;
}

class NavState {
  const NavState(this.tab, this.stack);
  final AppTab tab;
  final List<Destination> stack;
  Destination get top => stack.isEmpty ? TabDestination(tab) : stack.last;
  bool get canPop => stack.isNotEmpty;
}

class NavController extends Notifier<NavState> {
  @override
  NavState build() => const NavState(AppTab.home, []);

  void selectTab(AppTab tab) => state = NavState(tab, const []);
  void push(Destination d) => state = NavState(state.tab, [...state.stack, d]);
  void pop() {
    if (state.canPop) state = NavState(state.tab, state.stack.sublist(0, state.stack.length - 1));
  }
}

final navProvider = NotifierProvider<NavController, NavState>(NavController.new);

/// Lets the search field anywhere (top bar, "/" shortcut) drive the Search tab.
final searchQueryProvider = NotifierProvider<SearchQuery, String>(SearchQuery.new);

class SearchQuery extends Notifier<String> {
  @override
  String build() => '';
  void set(String q) => state = q;
}
