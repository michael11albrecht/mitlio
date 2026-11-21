import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/ui/illustrations/illustration.dart';

/// Friendly default portrait for the profile step: head and shoulders on a
/// soft disc. [colorIndex] picks one of the theme's avatar colours.
class ProfileAvatarIllustration extends StatelessWidget {
  const ProfileAvatarIllustration({
    required this.semanticLabel,
    this.colorIndex = 0,
    this.size = 120,
    super.key,
  });

  final String semanticLabel;
  final int colorIndex;
  final double size;

  @override
  Widget build(BuildContext context) => Illustration(
    semanticLabel: semanticLabel,
    width: size,
    painterBuilder: (p) => _AvatarPainter(p, colorIndex),
  );
}

class _AvatarPainter extends UnitPainter {
  const _AvatarPainter(super.p, this.colorIndex);

  final int colorIndex;

  @override
  void paintUnits(Canvas canvas) {
    final colors = p.avatars[colorIndex % p.avatars.length];
    const centre = Offset(50, 50);
    canvas
      ..drawCircle(centre, 48, fillPaint(p.accentSoft))
      ..save()
      ..clipPath(Path()..addOval(Rect.fromCircle(center: centre, radius: 48)))
      // Shoulders.
      ..drawOval(
        const Rect.fromLTWH(18, 66, 64, 56),
        fillPaint(colors.background),
      )
      // Neck.
      ..drawRRect(unitRRect(43, 54, 14, 18, 6), fillPaint(p.surface))
      // Head.
      ..drawCircle(const Offset(50, 40), 17, fillPaint(p.surface))
      ..drawCircle(const Offset(50, 40), 17, strokePaint(p.line, 2.5))
      // Hair cap.
      ..drawArc(
        Rect.fromCircle(center: const Offset(50, 40), radius: 17),
        3.6,
        2.4,
        true,
        fillPaint(colors.background),
      )
      ..restore()
      ..drawCircle(centre, 48, strokePaint(p.accent, 2.5));
    // Eyes and smile.
    for (final x in const [44.0, 56.0]) {
      canvas.drawCircle(Offset(x, 42), 1.6, fillPaint(p.ink));
    }
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(50, 46), radius: 6),
      0.5,
      2.1,
      false,
      strokePaint(p.ink, 1.8),
    );
  }
}
