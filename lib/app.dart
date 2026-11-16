import 'package:material_ui/material_ui.dart';

import 'core/theme.dart';
import 'ui/shell.dart';

class VybeApp extends StatelessWidget {
  const VybeApp({super.key, this.googleFonts = true});

  final bool googleFonts;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VYBE',
      debugShowCheckedModeBanner: false,
      theme: buildVybeTheme(googleFonts: googleFonts),
      darkTheme: buildVybeTheme(googleFonts: googleFonts),
      themeMode: ThemeMode.dark,
      home: const AppShell(),
    );
  }
}
