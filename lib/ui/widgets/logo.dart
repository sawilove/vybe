import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';

/// Geometry of the VYBE mark, measured from the brand book PNG.
///
/// All coordinates are in units of the mark's height (H = 1). [outline] is
/// the silhouette traced from the logo (marching squares on an 8× upsampled
/// mask), resampled to 70 points and drawn as a Catmull-Rom spline with a
/// sharp corner at the V's notch. The fold curves were traced from an edge
/// map of the same image.
abstract final class _G {
  static const outline = [
    Offset(0.7627, 1.0018),
    Offset(0.7015, 1.0002),
    Offset(0.6414, 0.9883),
    Offset(0.5846, 0.9657),
    Offset(0.5329, 0.9328),
    Offset(0.4879, 0.8914),
    Offset(0.4495, 0.8437),
    Offset(0.4126, 0.7947),
    Offset(0.3770, 0.7448),
    Offset(0.3403, 0.6957),
    Offset(0.3041, 0.6462),
    Offset(0.2677, 0.5969),
    Offset(0.2314, 0.5475),
    Offset(0.1948, 0.4983),
    Offset(0.1578, 0.4494),
    Offset(0.1215, 0.4001),
    Offset(0.0848, 0.3510),
    Offset(0.0499, 0.3006),
    Offset(0.0212, 0.2465),
    Offset(0.0036, 0.1880),
    Offset(0.0043, 0.1272),
    Offset(0.0285, 0.0713),
    Offset(0.0736, 0.0305),
    Offset(0.1294, 0.0055),
    Offset(0.1899, -0.0032),
    Offset(0.2512, -0.0021),
    Offset(0.3113, 0.0095),
    Offset(0.3691, 0.0295),
    Offset(0.4244, 0.0559),
    Offset(0.4763, 0.0883),
    Offset(0.5244, 0.1263),
    Offset(0.5690, 0.1683),
    Offset(0.6092, 0.2146),
    Offset(0.6481, 0.2620),
    Offset(0.6874, 0.3090),
    Offset(0.7254, 0.3571),
    Offset(0.7983, 0.4239),
    Offset(0.8792, 0.3057),
    Offset(0.9163, 0.2569),
    Offset(0.9527, 0.2076),
    Offset(0.9912, 0.1599),
    Offset(1.0327, 0.1148),
    Offset(1.0800, 0.0760),
    Offset(1.1322, 0.0438),
    Offset(1.1883, 0.0194),
    Offset(1.2473, 0.0028),
    Offset(1.3081, -0.0041),
    Offset(1.3692, -0.0005),
    Offset(1.4270, 0.0194),
    Offset(1.4761, 0.0553),
    Offset(1.5081, 0.1069),
    Offset(1.5155, 0.1674),
    Offset(1.5026, 0.2272),
    Offset(1.4762, 0.2824),
    Offset(1.4438, 0.3344),
    Offset(1.4062, 0.3828),
    Offset(1.3674, 0.4303),
    Offset(1.3302, 0.4790),
    Offset(1.2925, 0.5273),
    Offset(1.2545, 0.5755),
    Offset(1.2173, 0.6242),
    Offset(1.1795, 0.6724),
    Offset(1.1413, 0.7204),
    Offset(1.1035, 0.7687),
    Offset(1.0657, 0.8169),
    Offset(1.0271, 0.8645),
    Offset(0.9847, 0.9087),
    Offset(0.9353, 0.9450),
    Offset(0.8814, 0.9740),
    Offset(0.8233, 0.9932),
  ];
  static const notchIndex = 36;
  static const minX = 0.0036, maxX = 1.5155, minY = -0.0041, maxY = 1.0018;

  // Fold "P": edge between the lighter top faces and the darker underside,
  // running across both lobes.
  static const p0 = Offset(0.1703, 0.4444), p1 = Offset(0.5113, 0.6658);
  static const p2 = Offset(1.0209, 0.6244), p3 = Offset(1.3539, 0.4179);
  // Fold "R": the left ribbon tucking into the right lobe, from the crossing.
  static const q0 = Offset(0.7983, 0.4239), q1 = Offset(0.9259, 0.5891);
  static const q2 = Offset(1.1897, 0.5416), q3 = Offset(1.3357, 0.4300);

  // Edge "E": the glass ribbon's left edge, from the crossing down to the base.
  static const e0 = Offset(0.7983, 0.4239), e1 = Offset(0.6493, 0.5633);
  static const e2 = Offset(0.3741, 0.8787), e3 = Offset(0.6957, 0.9976);

  static const width = maxX - minX, height = maxY - minY;
}

/// The VYBE mark: a folded glass ribbon forming a "V" (brand book, "Основная версия").
class VybeMark extends StatelessWidget {
  const VybeMark({super.key, this.height = 32, this.monochrome = false});

  final double height;

  /// Flat white version (brand book "Монохромная").
  final bool monochrome;

  static const aspect = _G.width / _G.height;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: height * aspect,
        height: height,
        child: CustomPaint(painter: VybeMarkPainter(monochrome: monochrome)),
      );
}

class VybeMarkPainter extends CustomPainter {
  const VybeMarkPainter({this.monochrome = false});

  final bool monochrome;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.height / _G.height;
    canvas.save();
    canvas.scale(k);
    canvas.translate(-_G.minX, -_G.minY);

    final union = _outline();

    if (monochrome) {
      canvas.drawPath(union, Paint()..color = Colors.white);
      canvas.restore();
      return;
    }

    // Regions split by the fold curves.
    final belowP = Path()
      ..moveTo(-1, _G.p0.dy)
      ..lineTo(_G.p0.dx, _G.p0.dy)
      ..cubicTo(_G.p1.dx, _G.p1.dy, _G.p2.dx, _G.p2.dy, _G.p3.dx, _G.p3.dy)
      ..lineTo(3, _G.p3.dy)
      ..lineTo(3, 3)
      ..lineTo(-1, 3)
      ..close();
    final aboveR = Path()
      ..moveTo(_G.q0.dx, _G.q0.dy)
      ..cubicTo(_G.q1.dx, _G.q1.dy, _G.q2.dx, _G.q2.dy, _G.q3.dx, _G.q3.dy)
      ..lineTo(3, _G.q3.dy)
      ..lineTo(3, -1)
      ..lineTo(_G.q0.dx - 0.6, -1)
      ..close();
    // Everything right of the notch's vertical and of edge E belongs to the glass ribbon.
    final rightOfE = Path()
      ..moveTo(_G.e0.dx, -1)
      ..lineTo(_G.e0.dx, _G.e0.dy)
      ..cubicTo(_G.e1.dx, _G.e1.dy, _G.e2.dx, _G.e2.dy, _G.e3.dx, _G.e3.dy)
      ..lineTo(_G.e3.dx, 3)
      ..lineTo(3, 3)
      ..lineTo(3, -1)
      ..close();
    Path and(Path a, Path b) => Path.combine(PathOperation.intersect, a, b);
    Path minus(Path a, Path b) => Path.combine(PathOperation.difference, a, b);

    final left = minus(union, rightOfE); // left ribbon (behind)
    final rightInner = and(and(union, rightOfE), aboveR); // inside of the glass ribbon
    final front = minus(and(union, rightOfE), aboveR); // glass ribbon's front face
    final leftUnder = minus(and(union, belowP), front); // left ribbon's underside
    final band = minus(front, belowP); // where the front face crosses the left top face

    Paint lin(Offset from, Offset to, List<Color> colors, [List<double>? stops]) =>
        Paint()..shader = ui.Gradient.linear(from, to, colors, stops);

    // Faint violet glow behind the mark.
    canvas.drawPath(
      union,
      Paint()
        ..color = const Color(0xFF7C4DFF).withValues(alpha: 0.14)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 0.04),
    );

    // 1. Left ribbon, top face: light lavender at the outer end → deep violet by the notch.
    canvas.drawPath(
      union,
      lin(const Offset(0.08, 0.1), const Offset(0.75, 0.42),
          const [Color(0xFF905CF3), Color(0xFF7346D9), Color(0xFF4D33AE)], const [0.0, 0.5, 1.0]),
    );
    _radial(canvas, left, const Offset(0.12, 0.1), 0.28, const Color(0xFFD9C8FF), 0.16);

    // 2. Left ribbon, underside: indigo, lighter by the outer edge, darkest towards the base.
    canvas.drawPath(
      leftUnder,
      lin(const Offset(0.2, 0.5), const Offset(0.55, 0.85),
          const [Color(0xFF45329F), Color(0xFF332684), Color(0xFF1F1652)], const [0.0, 0.35, 1.0]),
    );

    // 3. Glass ribbon, inner face: dark navy by the notch, lighting up towards its outer end.
    canvas.drawPath(
      rightInner,
      lin(const Offset(0.9, 0.3), const Offset(1.48, 0.28),
          const [Color(0xFF2E1985), Color(0xFF3A1E9C), Color(0xFF6A34E2), Color(0xFF8A4CF5)],
          const [0.0, 0.4, 0.8, 1.0]),
    );
    _radial(canvas, rightInner, const Offset(1.27, 0.44), 0.16, const Color(0xFF6A35E0), 0.6);

    // 4. Glass ribbon, front face: violet, brighter to the right and towards the base.
    canvas.drawPath(
      front,
      lin(const Offset(0.6, 0.6), const Offset(1.2, 0.85),
          const [Color(0xFF6A3BDF), Color(0xFF6335D7), Color(0xFF8550F3)], const [0.0, 0.4, 1.0]),
    );
    _radial(canvas, front, const Offset(0.66, 1.0), 0.24, const Color(0xFFB79CFF), 0.38);
    canvas.drawPath(band, Paint()..color = const Color(0xFFB89CFF).withValues(alpha: 0.2));

    // 5. Glass rim: thin and bright on the ends and the base, fading out in the notch.
    const edge = 0.008;
    const rim = SweepGradient(
      colors: [
        Color(0xE6F1DCFF), // 0°   right end
        Color(0xB3E2D2FF),
        Color(0x40C9B3FF), // lower-right edge
        Color(0xC0E6DAFF), // 90°  base
        Color(0x40C9B3FF), // lower-left edge
        Color(0x8CDCCDFF), // left side
        Color(0xF2F8F4FF), // top-left end
        Color(0x40C9B3FF), // left ribbon's inner edge: dark
        Color(0x08B79CFF), // notch
        Color(0x99D9C8FF), // glass ribbon's inner edge: lit
        Color(0xB3E6D6FF), // top-right end
        Color(0xE6F1DCFF),
      ],
      stops: [0.0, 0.06, 0.15, 0.25, 0.34, 0.47, 0.6, 0.66, 0.8, 0.845, 0.9, 1.0],
    );
    _stroke(canvas, union, 0.035, rim, blur: 0.018, opacity: 0.16); // soft inner glow
    _stroke(canvas, union, edge, rim);
    // …and the internal fold lines.
    Paint line(double alpha) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = edge * 0.75
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFC9B3FF).withValues(alpha: alpha);
    canvas.save();
    canvas.clipPath(union);
    canvas.drawPath(
      Path()
        ..moveTo(_G.p0.dx, _G.p0.dy)
        ..cubicTo(_G.p1.dx, _G.p1.dy, _G.p2.dx, _G.p2.dy, _G.p3.dx, _G.p3.dy),
      line(0.55),
    );
    canvas.drawPath(
      Path()
        ..moveTo(_G.q0.dx, _G.q0.dy)
        ..cubicTo(_G.q1.dx, _G.q1.dy, _G.q2.dx, _G.q2.dy, _G.q3.dx, _G.q3.dy),
      line(0.4),
    );
    canvas.drawPath(
      Path()
        ..moveTo(_G.e0.dx, _G.e0.dy)
        ..cubicTo(_G.e1.dx, _G.e1.dy, _G.e2.dx, _G.e2.dy, _G.e3.dx, _G.e3.dy),
      line(0.35),
    );
    canvas.restore();

    canvas.restore();
  }

  static void _radial(Canvas c, Path clip, Offset center, double radius, Color color, double alpha) {
    c.save();
    c.clipPath(clip);
    c.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(colors: [color.withValues(alpha: alpha), color.withValues(alpha: 0)])
            .createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    c.restore();
  }

  /// Inner-aligned edge highlight (clipped so it never spills outside).
  static void _stroke(Canvas c, Path shape, double width, Gradient g, {double blur = 0, double opacity = 1}) {
    final b = shape.getBounds();
    c.save();
    c.clipPath(shape);
    if (opacity < 1) c.saveLayer(b.inflate(0.1), Paint()..color = Color.fromRGBO(0, 0, 0, opacity));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width * 2
      ..shader = g.createShader(b);
    if (blur > 0) paint.maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
    c.drawPath(shape, paint);
    if (opacity < 1) c.restore();
    c.restore();
  }

  /// Closed Catmull-Rom spline through [_G.outline], sharp at the notch.
  static Path _outline() {
    final p = _G.outline;
    final n = p.length;
    Offset at(int i) => p[(i + n) % n];
    final path = Path()..moveTo(p[0].dx, p[0].dy);
    for (var i = 0; i < n; i++) {
      final p0 = at(i - 1), p1 = at(i), p2 = at(i + 1), p3 = at(i + 2);
      final i1 = i % n, i2 = (i + 1) % n;
      final c1 = i1 == _G.notchIndex ? p1 : p1 + (p2 - p0) / 6;
      final c2 = i2 == _G.notchIndex ? p2 : p2 - (p3 - p1) / 6;
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }
    return path..close();
  }

  @override
  bool shouldRepaint(covariant VybeMarkPainter old) => old.monochrome != monochrome;
}

/// Mark + "VYBE" wordmark (+ optional tagline), as in the brand book.
class VybeLogo extends StatelessWidget {
  const VybeLogo({super.key, this.size = 30, this.showWordmark = true, this.showTagline = false});

  /// Height of the mark.
  final double size;
  final bool showWordmark;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    if (!showWordmark) return VybeMark(height: size);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        VybeMark(height: size),
        SizedBox(width: size * 0.4),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'VYBE',
              style: t.titleLarge?.copyWith(
                fontSize: size * 0.78,
                fontWeight: FontWeight.w400,
                letterSpacing: size * 0.14,
                height: 1.0,
                color: VybeColors.text,
              ),
            ),
            if (showTagline) ...[
              SizedBox(height: size * 0.2),
              Text(
                'YOUR SOUND. YOUR FREEDOM.',
                style: t.labelSmall?.copyWith(
                  fontSize: size * 0.21,
                  letterSpacing: size * 0.09,
                  color: VybeColors.accent,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// App icon: the mark on a dark glass tile with a lit top edge (brand book "Основная версия").
class VybeAppIcon extends StatelessWidget {
  const VybeAppIcon({super.key, this.size = 1024, this.rounded = true});

  final double size;

  /// iOS / adaptive Android icons are masked by the OS, so they get a full-bleed square.
  final bool rounded;

  @override
  Widget build(BuildContext context) {
    final radius = rounded ? size * 0.225 : 0.0;
    return CustomPaint(
      painter: _TilePainter(radius: radius, rim: rounded),
      child: SizedBox.square(
        dimension: size,
        child: Center(
          child: Padding(
            padding: EdgeInsets.only(top: size * 0.03),
            child: VybeMark(height: size * 0.48),
          ),
        ),
      ),
    );
  }
}

class _TilePainter extends CustomPainter {
  const _TilePainter({required this.radius, required this.rim});

  final double radius;
  final bool rim;

  @override
  void paint(Canvas canvas, Size s) {
    final r = RRect.fromRectAndRadius(Offset.zero & s, Radius.circular(radius));
    canvas.drawRRect(
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF211D31), Color(0xFF15131D), Color(0xFF100E17)],
          stops: [0.0, 0.55, 1.0],
        ).createShader(Offset.zero & s),
    );
    // Faint violet bloom behind the mark.
    canvas.drawRRect(
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, 0.05),
          radius: 0.6,
          colors: [const Color(0xFF7C4DFF).withValues(alpha: 0.16), Colors.transparent],
        ).createShader(Offset.zero & s),
    );
    if (!rim) return;
    // Glass rim: bright lavender along the top edge, fading down the sides.
    final w = s.width * 0.008;
    canvas.drawRRect(
      r.deflate(w / 2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFB9A2FF).withValues(alpha: 0.55),
            Colors.white.withValues(alpha: 0.06),
            const Color(0xFF8B5CF6).withValues(alpha: 0.32),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Offset.zero & s),
    );
  }

  @override
  bool shouldRepaint(covariant _TilePainter old) => old.radius != radius || old.rim != rim;
}
