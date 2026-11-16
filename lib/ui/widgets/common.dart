import 'package:material_ui/material_ui.dart';

import '../../core/models.dart';
import '../../core/theme.dart';

export 'glass.dart';
export 'logo.dart';

import 'glass.dart';

/// Album art with a branded placeholder for tracks without artwork.
class Artwork extends StatelessWidget {
  const Artwork({super.key, required this.track, this.size = 48, this.radius = VybeRadius.sm});

  final Track? track;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final url = track?.artworkUrl;
    final placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [VybeColors.surface3, VybeColors.accent.withValues(alpha: 0.5)],
        ),
      ),
      child: Icon(
        track?.source == SourceKind.local ? Icons.audio_file_rounded : Icons.music_note_rounded,
        color: VybeColors.accentLight,
        size: size * 0.42,
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: url == null
          ? placeholder
          : Image.network(
              url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
              errorBuilder: (_, _, _) => placeholder,
              frameBuilder: (_, child, frame, sync) =>
                  sync || frame != null ? child : placeholder,
            ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(foregroundColor: VybeColors.textMuted),
              child: Row(children: [Text(action!), const SizedBox(width: 6), const Icon(Icons.arrow_forward_rounded, size: 16)]),
            ),
        ],
      ),
    );
  }
}

/// The big round purple play / pause button.
class PlayButton extends StatelessWidget {
  const PlayButton({super.key, required this.playing, required this.onPressed, this.size = 52, this.loading = false});

  final bool playing;
  final bool loading;
  final VoidCallback? onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: VybeColors.accent,
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: VybeColors.accent.withValues(alpha: 0.45), blurRadius: 24)],
          ),
          child: loading
              ? Padding(
                  padding: EdgeInsets.all(size * 0.3),
                  child: const CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                )
              : Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: size * 0.55),
        ),
      ),
    );
  }
}

/// Animated equalizer bars shown next to the playing track.
class EqualizerIcon extends StatefulWidget {
  const EqualizerIcon({super.key, this.animate = true, this.size = 18});

  final bool animate;
  final double size;

  @override
  State<EqualizerIcon> createState() => _EqualizerIconState();
}

class _EqualizerIconState extends State<EqualizerIcon> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void initState() {
    super.initState();
    if (widget.animate) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant EqualizerIcon old) {
    super.didUpdateWidget(old);
    if (widget.animate && !_c.isAnimating) _c.repeat(reverse: true);
    if (!widget.animate) _c.stop();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const phases = [0.2, 0.9, 0.5, 0.7];
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => SizedBox(
        width: widget.size,
        height: widget.size,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final p in phases)
              Container(
                width: widget.size / 6,
                height: widget.size * (0.3 + 0.7 * ((_c.value + p) % 1.0)),
                decoration: BoxDecoration(color: VybeColors.accentLight, borderRadius: BorderRadius.circular(2)),
              ),
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.subtitle, this.action});

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: VybeColors.accentLight),
            const SizedBox(height: 16),
            Text(title, style: t.titleMedium, textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!, style: t.bodyMedium?.copyWith(color: VybeColors.textMuted), textAlign: TextAlign.center),
            ],
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}

/// Glassy rounded panel used for the sidebar, now-playing panel, etc.
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.color = VybeColors.surface,
    this.accents = const GlassAccents(rimStrength: 0.5),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final GlassAccents accents;

  @override
  Widget build(BuildContext context) =>
      GlassSurface(color: color, padding: padding, accents: accents, child: child);
}
