import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';

/// The VYBE mark from the brand book: two glossy ribbon-capsules forming a
/// "V". The darker left ribbon tucks under the lighter right one at the base.
class VybeMark extends StatelessWidget {
  const VybeMark({super.key, this.height = 32, this.monochrome = false});

  final double height;

  /// White single-colour version for small sizes / system tray.
  final bool monochrome;

  /// Width / height of the mark.
  static const aspect = 1.42;

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
  void paint(Canvas canvas, Size s) {
    final h = s.height, w = s.width;
    final rTop = h * 0.215; // ribbons are wide at the top…
    final rBase = h * 0.125; // …and taper into one rounded tip.
    final thick = rTop * 2;
    final r = rTop;

    final base = Offset(w * 0.5, h - rBase);
    final leftTop = Offset(rTop, rTop);
    final rightTop = Offset(w - rTop, rTop);
    final leftBase = base;
    final rightBase = base;

    final left = _taper(leftTop, rTop, leftBase, rBase);
    final right = _taper(rightBase, rBase, rightTop, rTop);

    if (monochrome) {
      final p = Paint()..color = Colors.white;
      canvas.drawPath(Path.combine(PathOperation.union, left, right), p);
      return;
    }

    // Left ribbon: deep violet at the base, lighter towards its top end.
    canvas.drawPath(
      left,
      Paint()
        ..shader = LinearGradient(
          colors: const [Color(0xFFA889FF), Color(0xFF7C4DF0), Color(0xFF4A1FB0)],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(Rect.fromPoints(leftTop, leftBase)),
    );
    // Soft top-left sheen on the left ribbon's end.
    canvas.save();
    canvas.clipPath(left);
    canvas.drawCircle(
      leftTop.translate(-r * 0.25, -r * 0.3),
      r * 1.1,
      Paint()
        ..shader = RadialGradient(colors: [Colors.white.withValues(alpha: 0.35), Colors.white.withValues(alpha: 0)])
            .createShader(Rect.fromCircle(center: leftTop.translate(-r * 0.25, -r * 0.3), radius: r * 1.1)),
    );
    canvas.restore();

    // Shadow the right ribbon casts onto the left one where they overlap.
    canvas.save();
    canvas.clipPath(left);
    canvas.drawPath(
      right.shift(Offset(-thick * 0.12, 0)),
      Paint()
        ..color = const Color(0xFF1A0B4A).withValues(alpha: 0.55)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, thick * 0.12),
    );
    canvas.restore();

    // Right ribbon: brighter, from accent at the base to Accent Light at the top.
    canvas.drawPath(
      right,
      Paint()
        ..shader = LinearGradient(
          colors: const [Color(0xFF6A35E8), VybeColors.accent, Color(0xFFC6B2FF)],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(Rect.fromPoints(rightBase, rightTop)),
    );

    // Glossy highlight running along the right ribbon's upper edge.
    canvas.save();
    canvas.clipPath(right);
    final dir = (rightTop - rightBase);
    final n = Offset(-dir.dy, dir.dx) / dir.distance; // normal pointing up-left
    canvas.drawPath(
      _capsule(rightBase + n * rBase * 0.45 + dir * 0.25, rightTop + n * r * 0.5, thick * 0.22),
      Paint()
        ..shader = LinearGradient(
          colors: [Colors.white.withValues(alpha: 0.0), Colors.white.withValues(alpha: 0.38)],
        ).createShader(Rect.fromPoints(rightBase, rightTop))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, thick * 0.05),
    );
    canvas.restore();
  }

  /// Convex hull of two circles: a pill that tapers from radius [ra] to [rb].
  static Path _taper(Offset a, double ra, Offset b, double rb) {
    final d = b - a;
    final dist = d.distance;
    final theta = math.atan2(d.dy, d.dx);
    final phi = math.acos(((ra - rb) / dist).clamp(-1.0, 1.0));
    Offset on(Offset c, double r, double ang) => c + Offset(math.cos(ang), math.sin(ang)) * r;
    return Path()
      ..moveTo(on(a, ra, theta + phi).dx, on(a, ra, theta + phi).dy)
      ..arcTo(Rect.fromCircle(center: a, radius: ra), theta + phi, 2 * math.pi - 2 * phi, false)
      ..lineTo(on(b, rb, theta - phi).dx, on(b, rb, theta - phi).dy)
      ..arcTo(Rect.fromCircle(center: b, radius: rb), theta - phi, 2 * phi, false)
      ..close();
  }

  /// A stadium (pill) shape from [a] to [b] with the given thickness.
  static Path _capsule(Offset a, Offset b, double thickness) {
    final d = b - a;
    final len = d.distance;
    final angle = math.atan2(d.dy, d.dx);
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(-thickness / 2, -thickness / 2, len + thickness, thickness),
      Radius.circular(thickness / 2),
    );
    final m = Matrix4.identity()
      ..translateByDouble(a.dx, a.dy, 0, 1)
      ..rotateZ(angle);
    return (Path()..addRRect(rect)).transform(m.storage);
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
        SizedBox(width: size * 0.45),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'VYBE',
              style: t.titleLarge?.copyWith(
                fontSize: size * 0.82,
                fontWeight: FontWeight.w400,
                letterSpacing: size * 0.16,
                height: 1.0,
                color: VybeColors.text,
              ),
            ),
            if (showTagline) ...[
              SizedBox(height: size * 0.18),
              Text(
                'YOUR SOUND. YOUR FREEDOM.',
                style: t.labelSmall?.copyWith(
                  fontSize: size * 0.22,
                  letterSpacing: size * 0.08,
                  color: VybeColors.accentLight,
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

/// App icon composition: the mark on a dark rounded tile (brand book "Основная версия").
class VybeAppIcon extends StatelessWidget {
  const VybeAppIcon({super.key, this.size = 1024, this.rounded = true});

  final double size;

  /// iOS/Android adaptive icons are masked by the OS, so they get a square tile.
  final bool rounded;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: rounded ? BorderRadius.circular(size * 0.23) : null,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A2440), Color(0xFF15131F)],
        ),
        border: rounded ? Border.all(color: Colors.white.withValues(alpha: 0.08), width: size * 0.006) : null,
      ),
      alignment: Alignment.center,
      child: Padding(
        padding: EdgeInsets.only(top: size * 0.04),
        child: VybeMark(height: size * 0.44),
      ),
    );
  }
}
