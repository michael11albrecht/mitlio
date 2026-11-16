import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/keyboard.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/l10n/app_localizations.dart';

/// The iOS number pad has no return key. While a field inside [child] has
/// focus on iOS, this shows a "Fertig" bar right above the keyboard that
/// closes it. Other platforms have their own done key, so nothing is shown.
/// Wrap every numeric [TextField] in it.
class NumberPadDone extends StatefulWidget {
  const NumberPadDone({required this.child, super.key});

  final Widget child;

  @override
  State<NumberPadDone> createState() => _NumberPadDoneState();
}

class _NumberPadDoneState extends State<NumberPadDone> {
  OverlayEntry? _entry;

  void _onFocus(bool focused) {
    if (focused && defaultTargetPlatform == TargetPlatform.iOS) {
      if (_entry != null) return;
      final overlay = Overlay.maybeOf(context);
      if (overlay == null) return;
      _entry = OverlayEntry(builder: (_) => const _DoneBar());
      overlay.insert(_entry!);
    } else {
      _hide();
    }
  }

  void _hide() {
    _entry?.remove();
    _entry?.dispose();
    _entry = null;
  }

  @override
  void dispose() {
    _hide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Focus(
    canRequestFocus: false,
    skipTraversal: true,
    onFocusChange: _onFocus,
    child: widget.child,
  );
}

class _DoneBar extends StatelessWidget {
  const _DoneBar();

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    // No on-screen keyboard (hardware keyboard, simulator): no bar.
    if (inset <= 0) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Positioned(
      left: 0,
      right: 0,
      bottom: inset,
      child: Material(
        color: scheme.surfaceContainerHigh,
        child: Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
            child: TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                tapTargetSize: MaterialTapTargetSize.padded,
              ),
              onPressed: dismissKeyboard,
              child: Text(AppLocalizations.of(context).keyboardDone),
            ),
          ),
        ),
      ),
    );
  }
}
