import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/l10n/app_localizations.dart';

/// End of a one-time setup: a short celebration, a summary of what was set
/// up and one obvious next action (ADR-25 §4). No points, streaks or badges.
/// Under reduce-motion the celebration is its final, still frame. A light
/// haptic tick marks the moment either way.
class FinishStep extends StatefulWidget {
  const FinishStep({
    required this.title,
    required this.actionLabel,
    required this.onAction,
    this.summary = const [],
    this.preview,
    this.onBack,
    super.key,
  });

  final String title;

  /// What was set up, one short line each ("PayPal.Me: anna").
  final List<String> summary;
  final String actionLabel;
  final VoidCallback onAction;

  /// What the flow made, shown as it will look (the profile card).
  final Widget? preview;

  /// Back to the last step.
  final VoidCallback? onBack;

  @override
  State<FinishStep> createState() => _FinishStepState();
}

class _FinishStepState extends State<FinishStep>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 900);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _duration,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    unawaited(HapticFeedback.lightImpact());
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Sizes.contentMaxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: Spacing.screen,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: Spacing.lg),
                      Center(
                        child: ExcludeSemantics(
                          child: _Celebration(animation: _controller),
                        ),
                      ),
                      const SizedBox(height: Spacing.lg),
                      Semantics(
                        header: true,
                        child: Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall,
                        ),
                      ),
                      if (widget.preview != null) ...[
                        const SizedBox(height: Spacing.lg),
                        widget.preview!,
                      ],
                      if (widget.summary.isNotEmpty) ...[
                        const SizedBox(height: Spacing.lg),
                        for (final line in widget.summary)
                          Padding(
                            padding: const EdgeInsets.only(bottom: Spacing.sm),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ExcludeSemantics(
                                  child: Icon(
                                    Icons.check,
                                    color: scheme.primary,
                                  ),
                                ),
                                const SizedBox(width: Spacing.sm),
                                Expanded(
                                  child: Text(
                                    line,
                                    style: theme.textTheme.bodyLarge,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: Spacing.screen,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton(
                      onPressed: widget.onAction,
                      child: Text(widget.actionLabel),
                    ),
                    if (widget.onBack != null)
                      TextButton(
                        onPressed: widget.onBack,
                        child: Text(AppLocalizations.of(context).setupBack),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A check mark that pops in while a ring of dots flies outward and fades.
/// Colours from the theme; at `animation.value == 1` only the check is left.
class _Celebration extends StatelessWidget {
  const _Celebration({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) => CustomPaint(
        size: const Size.square(Sizes.celebration),
        painter: _CelebrationPainter(
          progress: animation.value,
          badge: scheme.primary,
          mark: scheme.onPrimary,
          dots: [scheme.primary, scheme.tertiary],
        ),
      ),
    );
  }
}

class _CelebrationPainter extends CustomPainter {
  _CelebrationPainter({
    required this.progress,
    required this.badge,
    required this.mark,
    required this.dots,
  });

  static const _dotCount = 12;

  final double progress;
  final Color badge;
  final Color mark;
  final List<Color> dots;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final half = size.shortestSide / 2;
    final pop = Curves.elasticOut.transform((progress * 1.4).clamp(0, 1));
    final radius = half * 0.55 * pop;
    canvas.drawCircle(center, radius, Paint()..color = badge);
    final stroke = Paint()
      ..color = mark
      ..style = PaintingStyle.stroke
      ..strokeWidth = half * 0.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final r = radius;
    canvas.drawPath(
      Path()
        ..moveTo(center.dx - r * 0.4, center.dy)
        ..lineTo(center.dx - r * 0.1, center.dy + r * 0.3)
        ..lineTo(center.dx + r * 0.45, center.dy - r * 0.3),
      stroke,
    );
    final fade = 1 - Curves.easeIn.transform(progress);
    if (fade <= 0) return;
    final reach = half * (0.6 + 0.4 * Curves.easeOut.transform(progress));
    for (var i = 0; i < _dotCount; i++) {
      final angle = 2 * math.pi * i / _dotCount;
      canvas.drawCircle(
        center + Offset(math.cos(angle), math.sin(angle)) * reach,
        half * (i.isEven ? 0.07 : 0.05),
        Paint()..color = dots[i % dots.length].withValues(alpha: fade),
      );
    }
  }

  @override
  bool shouldRepaint(_CelebrationPainter old) =>
      old.progress != progress ||
      old.badge != badge ||
      old.mark != mark ||
      old.dots != dots;
}
