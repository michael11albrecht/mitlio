import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/theme/theme.dart';

/// A calm placeholder where the illustration of a step goes (PU-T06 replaces
/// it with drawn art): an icon on a soft square.
class StepIconVisual extends StatelessWidget {
  const StepIconVisual(this.icon, {super.key});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: Sizes.stepVisual,
      width: Sizes.stepVisual,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: Radii.lgAll,
        ),
        child: Icon(
          icon,
          size: Sizes.stepVisual / 2,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
