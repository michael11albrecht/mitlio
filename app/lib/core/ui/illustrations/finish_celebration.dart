import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/ui/illustrations/illustration.dart';

/// Finish screen picture: a check mark in a badge with a short burst of
/// confetti. Plays once (about 1.4 s) and then stays on the final frame. With
/// reduce-motion (`MediaQuery.disableAnimations`) it shows the final frame at
/// once, with no animation at all. One-time setups only (ADR-25 §4).
class FinishCelebration extends StatefulWidget {
  const FinishCelebration({
    required this.semanticLabel,
    this.size = 160,
    super.key,
  });

  final String semanticLabel;
  final double size;

  @override
  State<FinishCelebration> createState() => _FinishCelebrationState();
}

class _FinishCelebrationState extends State<FinishCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else if (!_started) {
      _started = true;
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = IllustrationPalette.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Illustration(
        semanticLabel: widget.semanticLabel,
        width: widget.size,
        painterBuilder: (_) => FinishCelebrationPainter(p, _controller.value),
      ),
    );
  }
}

/// Paints the celebration at [progress] 0..1 (1 = settled final frame).
/// Public so goldens and tests can render any frame deterministically.
class FinishCelebrationPainter extends UnitPainter {
  const FinishCelebrationPainter(super.p, this.progress);

  final double progress;

  @override
  bool shouldRepaint(covariant FinishCelebrationPainter old) =>
      old.p != p || old.progress != progress;

  static const _pieces = 14;

  @override
  void paintUnits(Canvas canvas) {
    const centre = Offset(50, 50);
    final pop = Curves.elasticOut.transform((progress * 1.6).clamp(0, 1));
    canvas
      ..drawCircle(centre, 40 * pop, fillPaint(p.accentSoft))
      ..drawCircle(centre, 30 * pop, fillPaint(p.accent));
    if (pop > 0.4) {
      final tick = ((pop - 0.4) / 0.6).clamp(0.0, 1.0);
      final path = Path()
        ..moveTo(38, 51)
        ..lineTo(47, 60)
        ..lineTo(63, 41);
      final metric = path.computeMetrics().first;
      canvas.drawPath(
        metric.extractPath(0, metric.length * tick),
        strokePaint(p.onAccent, 6),
      );
    }
    // Confetti: fixed pseudo-random directions so every frame is repeatable.
    final burst = Curves.easeOutCubic.transform(progress);
    final fade = progress < 0.7 ? 1.0 : 1 - (progress - 0.7) / 0.3 * 0.55;
    final tones = [
      p.warm,
      p.accent,
      p.avatars[3].background,
      p.avatars[4].background,
    ];
    for (var i = 0; i < _pieces; i++) {
      final angle = i / _pieces * 2 * math.pi + (i.isEven ? 0.12 : -0.12);
      final reach = 44 + (i % 3) * 3.0;
      const from = 34.0;
      final dist = from + (reach - from) * burst;
      final at = centre + Offset.fromDirection(angle, dist);
      final paint = fillPaint(tones[i % tones.length].withValues(alpha: fade));
      canvas
        ..save()
        ..translate(at.dx, at.dy)
        ..rotate(angle + burst * 2);
      if (i % 3 == 0) {
        canvas.drawCircle(Offset.zero, 2, paint);
      } else {
        canvas.drawRRect(unitRRect(-1.6, -3.4, 3.2, 6.8, 1.2), paint);
      }
      canvas.restore();
    }
  }
}
