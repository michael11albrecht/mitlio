import 'package:material_ui/material_ui.dart';

/// Hides the on-screen keyboard by dropping focus from the focused field.
void dismissKeyboard() => FocusManager.instance.primaryFocus?.unfocus();

/// Dismisses the keyboard whenever the enclosing [DefaultTabController]
/// changes tab, by tap or by swipe. Place it inside the controller.
class DismissKeyboardOnTabChange extends StatefulWidget {
  const DismissKeyboardOnTabChange({required this.child, super.key});

  final Widget child;

  @override
  State<DismissKeyboardOnTabChange> createState() =>
      _DismissKeyboardOnTabChangeState();
}

class _DismissKeyboardOnTabChangeState
    extends State<DismissKeyboardOnTabChange> {
  TabController? _controller;
  int _index = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = DefaultTabController.of(context);
    if (controller == _controller) return;
    _controller?.removeListener(_onChange);
    _controller = controller..addListener(_onChange);
    _index = controller.index;
  }

  void _onChange() {
    final controller = _controller!;
    if (controller.indexIsChanging || controller.index != _index) {
      dismissKeyboard();
    }
    _index = controller.index;
  }

  @override
  void dispose() {
    _controller?.removeListener(_onChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Navigator observer that drops focus on every route change, so the keyboard
/// never survives a screen change.
class KeyboardDismissObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      dismissKeyboard();

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      dismissKeyboard();

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      dismissKeyboard();
}
