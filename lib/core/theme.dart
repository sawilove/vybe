import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

/// Design tokens from the VYBE brand book.
abstract final class VybeColors {
  static const accent = Color(0xFF8B5CF6);
  static const accentLight = Color(0xFFB7A0FF);
  static const background = Color(0xFF0D0D15);
  static const surface = Color(0xFF171722);
  static const surface2 = Color(0xFF20202D);
  static const surface3 = Color(0xFF2A2A3A);
  static const text = Color(0xFFF4F4F5);
  static const textMuted = Color(0xFF9C9AB3);
  static const border = Color(0x14FFFFFF);
  static const online = Color(0xFF22C55E);

  static const accentGradient = LinearGradient(colors: [accent, accentLight]);
}

abstract final class VybeRadius {
  static const sm = 10.0;
  static const md = 14.0;
  static const lg = 20.0;
  static const pill = 999.0;
}

/// Poppins (brand font) has no Cyrillic glyphs, so Russian text falls back
/// to Montserrat, which is the closest geometric sans with Cyrillic support.
TextTheme _poppinsWithCyrillic(TextTheme base) {
  TextStyle? withFallback(TextStyle? s) {
    if (s == null) return null;
    final cyr = GoogleFonts.montserrat(fontWeight: s.fontWeight).fontFamily;
    return s.copyWith(fontFamilyFallback: [?cyr]);
  }

  final t = GoogleFonts.poppinsTextTheme(base);
  return t.copyWith(
    displayLarge: withFallback(t.displayLarge),
    displayMedium: withFallback(t.displayMedium),
    displaySmall: withFallback(t.displaySmall),
    headlineLarge: withFallback(t.headlineLarge),
    headlineMedium: withFallback(t.headlineMedium),
    headlineSmall: withFallback(t.headlineSmall),
    titleLarge: withFallback(t.titleLarge),
    titleMedium: withFallback(t.titleMedium),
    titleSmall: withFallback(t.titleSmall),
    bodyLarge: withFallback(t.bodyLarge),
    bodyMedium: withFallback(t.bodyMedium),
    bodySmall: withFallback(t.bodySmall),
    labelLarge: withFallback(t.labelLarge),
    labelMedium: withFallback(t.labelMedium),
    labelSmall: withFallback(t.labelSmall),
  );
}

/// [googleFonts] is off in tests, which have no network.
ThemeData buildVybeTheme({bool googleFonts = true}) {
  final base = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: VybeColors.background,
    colorScheme: const ColorScheme.dark(
      primary: VybeColors.accent,
      secondary: VybeColors.accentLight,
      surface: VybeColors.surface,
      onSurface: VybeColors.text,
      onPrimary: Colors.white,
    ),
  );
  final text = (googleFonts ? _poppinsWithCyrillic(base.textTheme) : base.textTheme).apply(
    bodyColor: VybeColors.text,
    displayColor: VybeColors.text,
  );
  return base.copyWith(
    textTheme: text,
    iconTheme: const IconThemeData(color: VybeColors.text),
    dividerColor: VybeColors.border,
    splashFactory: InkSparkle.splashFactory,
    sliderTheme: const SliderThemeData(
      trackHeight: 4,
      activeTrackColor: VybeColors.accent,
      inactiveTrackColor: VybeColors.surface3,
      thumbColor: Colors.white,
      overlayShape: RoundSliderOverlayShape(overlayRadius: 12),
      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: VybeColors.surface,
      hintStyle: const TextStyle(color: VybeColors.textMuted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(VybeRadius.md),
        borderSide: const BorderSide(color: VybeColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(VybeRadius.md),
        borderSide: const BorderSide(color: VybeColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(VybeRadius.md),
        borderSide: const BorderSide(color: VybeColors.accent),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: VybeColors.surface2,
      contentTextStyle: TextStyle(color: VybeColors.text),
      behavior: SnackBarBehavior.floating,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: VybeColors.surface,
      indicatorColor: VybeColors.accent.withValues(alpha: 0.25),
      labelTextStyle: WidgetStatePropertyAll(text.labelSmall),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? VybeColors.accent : VybeColors.surface3,
      ),
    ),
  );
}
