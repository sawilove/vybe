import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';

/// Decorative accents from the brand book, shared by panels, cards and banners:
///
/// * an iridescent rim: the 1px border lights up lavender (with a hint of
///   magenta) at one corner and fades out towards the opposite one;
/// * a soft violet glow in that corner;
/// * an optional glass "sheen": a translucent sheet sweeping in from a corner
///   with a bright edge where it catches the light;
/// * an optional wave in a bottom corner with a glowing crest.
class GlassAccents {
  const GlassAccents({
    this.glowCorner = Alignment.topLeft,
    this.rimStrength = 1.0,
    this.cornerGlow = true,
    this.sheen,
    this.wave,
  });

  /// Where the rim is brightest. `null` → plain border.
  final Alignment? glowCorner;

  /// 0…1, how strongly the rim lights up.
  final double rimStrength;
  final bool cornerGlow;

  /// Corner the glass sheet sweeps in from (e.g. [Alignment.topRight]).
  final Alignment? sheen;

  /// Bottom corner holding a wave ([Alignment.bottomLeft] / [Alignment.bottomRight]).
  final Alignment? wave;
}

/// A rounded surface painted with [GlassAccents].
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.accents = const GlassAccents(),
    this.color = VybeColors.surface,
    this.radius = VybeRadius.lg,
    this.padding = EdgeInsets.zero,
    this.clip = true,
  });

  final Widget child;
  final GlassAccents accents;
  final Color color;
  final double radius;
  final EdgeInsetsGeometry padding;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));
    return CustomPaint(
      // Rim on top of the content, so photos and gradients get it too.
      foregroundPainter: GlassRimPainter(accents: accents, radius: radius),
      child: Material(
        color: color,
        shape: shape,
        clipBehavior: clip ? Clip.antiAlias : Clip.none,
        child: CustomPaint(
          painter: GlassBackdropPainter(accents: accents, radius: radius),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Corner glow, sheen and wave: painted behind the content.
class GlassBackdropPainter extends CustomPainter {
  const GlassBackdropPainter({required this.accents, required this.radius});

  final GlassAccents accents;
  final double radius;

  @override
  void paint(Canvas canvas, Size s) {
    final rect = Offset.zero & s;
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));

    final corner = accents.glowCorner;
    if (corner != null && accents.cornerGlow) {
      final c = corner.withinRect(rect);
      final r = s.shortestSide * 0.9;
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = ui.Gradient.radial(c, r, [
            VybeColors.accent.withValues(alpha: 0.13 * accents.rimStrength),
            VybeColors.accent.withValues(alpha: 0),
          ]),
      );
    }

    final sheen = accents.sheen;
    if (sheen != null) _paintSheen(canvas, s, sheen);

    final wave = accents.wave;
    if (wave != null) _paintWave(canvas, s, wave);

    canvas.restore();
  }

  /// A glass sheet entering from [corner]: faintly lighter fill, bright curved edge.
  void _paintSheen(Canvas canvas, Size s, Alignment corner) {
    final w = s.width, h = s.height;
    // Built for the top-right corner, mirrored for others.
    canvas.save();
    if (corner.x < 0) {
      canvas.translate(w, 0);
      canvas.scale(-1, 1);
    }
    if (corner.y > 0) {
      canvas.translate(0, h);
      canvas.scale(1, -1);
    }
    final edge = Path()
      ..moveTo(w * 0.28, -2)
      ..quadraticBezierTo(w * 0.62, h * 0.30, w + 2, h * 0.30);
    final sheet = Path.from(edge)
      ..lineTo(w + 2, -2)
      ..close();
    canvas.drawPath(
      sheet,
      Paint()
        ..shader = ui.Gradient.linear(Offset(w, 0), Offset(w * 0.45, h * 0.35), [
          Colors.white.withValues(alpha: 0.06),
          Colors.white.withValues(alpha: 0.015),
        ]),
    );
    final edgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..shader = ui.Gradient.linear(
        Offset(w * 0.3, 0),
        Offset(w, h * 0.3),
        [
          VybeColors.accentLight.withValues(alpha: 0.0),
          VybeColors.accentLight.withValues(alpha: 0.75),
          const Color(0xFFE2B8FF).withValues(alpha: 0.35),
        ],
        [0.0, 0.6, 1.0],
      );
    canvas.drawPath(
      edge,
      edgePaint
        ..strokeWidth = 4
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawPath(
      edge,
      edgePaint
        ..strokeWidth = 1.2
        ..maskFilter = null,
    );
    canvas.restore();
  }

  /// A violet wave filling a bottom corner, with a glowing crest.
  void _paintWave(Canvas canvas, Size s, Alignment corner) {
    final w = s.width, h = s.height;
    canvas.save();
    if (corner.x > 0) {
      canvas.translate(w, 0);
      canvas.scale(-1, 1);
    }
    // Sized from the shorter side so tall panels get a low, gentle sweep.
    final u = math.min(w, h);
    final top = h - u * 0.55;
    final crest = Path()
      ..moveTo(-2, top)
      ..cubicTo(w * 0.3, top - u * 0.06, w * 0.62, h - u * 0.22, w + 2, h - u * 0.04);
    final body = Path.from(crest)
      ..lineTo(w + 2, h + 2)
      ..lineTo(-2, h + 2)
      ..close();
    canvas.drawPath(
      body,
      Paint()
        ..shader = ui.Gradient.linear(Offset(0, top), Offset(w * 0.4, h), [
          const Color(0xFF5B34D6).withValues(alpha: 0.32),
          const Color(0xFF2A1A6E).withValues(alpha: 0.12),
        ]),
    );
    final crestPaint = Paint()
      ..style = PaintingStyle.stroke
      ..shader = ui.Gradient.linear(Offset(0, top), Offset(w, h), [
        VybeColors.accentLight.withValues(alpha: 0.7),
        VybeColors.accent.withValues(alpha: 0.0),
      ]);
    canvas.drawPath(
      crest,
      crestPaint
        ..strokeWidth = 5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawPath(
      crest,
      crestPaint
        ..strokeWidth = 1.2
        ..maskFilter = null,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant GlassBackdropPainter old) => old.accents != accents || old.radius != radius;
}

/// The iridescent 1px rim, painted over the content.
class GlassRimPainter extends CustomPainter {
  const GlassRimPainter({required this.accents, required this.radius});

  final GlassAccents accents;
  final double radius;

  @override
  void paint(Canvas canvas, Size s) {
    final rrect = RRect.fromRectAndRadius((Offset.zero & s).deflate(0.5), Radius.circular(radius));
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.06),
    );
    final corner = accents.glowCorner;
    if (corner == null) return;
    final k = accents.rimStrength;
    final rect = Offset.zero & s;
    final from = corner.withinRect(rect);
    final to = Alignment(-corner.x, -corner.y).withinRect(rect);
    final light = Paint()
      ..style = PaintingStyle.stroke
      ..shader = ui.Gradient.linear(
        from,
        Offset.lerp(from, to, 0.75)!,
        [
          const Color(0xFFD8C8FF).withValues(alpha: 0.75 * k),
          const Color(0xFFC07CFF).withValues(alpha: 0.4 * k), // magenta shimmer
          VybeColors.accent.withValues(alpha: 0.18 * k),
          VybeColors.accent.withValues(alpha: 0),
        ],
        [0.0, 0.18, 0.45, 1.0],
      );
    // Soft bloom + crisp line.
    canvas.drawRRect(
      rrect,
      light
        ..strokeWidth = 3
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawRRect(
      rrect,
      light
        ..strokeWidth = 1
        ..maskFilter = null,
    );
  }

  @override
  bool shouldRepaint(covariant GlassRimPainter old) => old.accents != accents || old.radius != radius;
}

/// App-wide backdrop: dark canvas with violet glows in opposite corners.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: VybeColors.background),
      child: CustomPaint(painter: const _AmbientPainter(), child: child),
    );
  }
}

class _AmbientPainter extends CustomPainter {
  const _AmbientPainter();

  @override
  void paint(Canvas canvas, Size s) {
    void glow(Offset c, double r, Color color, double a) => canvas.drawCircle(
      c,
      r,
      Paint()..shader = ui.Gradient.radial(c, r, [color.withValues(alpha: a), color.withValues(alpha: 0)]),
    );
    glow(Offset(0, s.height), s.shortestSide * 0.9, VybeColors.accent, 0.14);
    glow(Offset(s.width, 0), s.shortestSide * 0.7, const Color(0xFF6D3BF5), 0.10);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
