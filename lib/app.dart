import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'core/theme.dart';
import 'data/library_store.dart';
import 'l10n/l10n.dart';
import 'ui/shell.dart';

class VybeApp extends ConsumerWidget {
  const VybeApp({super.key, this.googleFonts = true});

  final bool googleFonts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final code = ref.watch(libraryProvider.select((s) => s.settings.locale));
    return MaterialApp(
      onGenerateTitle: (_) => 'VYBE',
      debugShowCheckedModeBanner: false,
      theme: buildVybeTheme(googleFonts: googleFonts),
      darkTheme: buildVybeTheme(googleFonts: googleFonts),
      themeMode: ThemeMode.dark,
      // Empty code → follow the system language (falls back to English).
      locale: code.isEmpty ? null : Locale(code),
      supportedLocales: AppLocalizations.supportedLocales,
      // Material/Cupertino/Widgets localizations come from material_ui (Flutter 3.50+).
      localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
      home: const AppShell(),
    );
  }
}
