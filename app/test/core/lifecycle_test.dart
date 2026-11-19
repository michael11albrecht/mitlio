import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/lifecycle.dart';

void main() {
  testWidgets('WidgetsLifecycleSource emits on resume only', (tester) async {
    final source = WidgetsLifecycleSource();
    var resumes = 0;
    final sub = source.onResume.listen((_) => resumes++);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(resumes, 1);
    unawaited(sub.cancel());
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(resumes, 1);
  });

  test('NoLifecycle never emits', () async {
    expect(await const NoLifecycle().onResume.isEmpty, isTrue);
  });
}
