import 'dart:ui' show Tristate;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/core/ui/setup_flow/finish_step.dart';
import 'package:mitlio/core/ui/setup_flow/setup_flow_view.dart';
import 'package:mitlio/core/ui/setup_flow/setup_progress_bar.dart';
import 'package:mitlio/core/ui/setup_flow/step_scaffold.dart';
import 'package:mitlio/core/ui/setup_flow/yes_no_step.dart';
import 'package:mitlio/features/setup/data/fake_setup_state_repository.dart';
import 'package:mitlio/l10n/app_localizations_de.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/themed_app.dart';
import '../../../support/tap_counter.dart';
import 'setup_flow_fixtures.dart';

final _de = AppLocalizationsDe();

void main() {
  late FakeSetupStateRepository repo;
  setUp(() => repo = FakeSetupStateRepository());

  Future<void> pumpFlow(WidgetTester tester) async {
    await tester.pumpWidget(themedApp(demoFlowView(repo)));
    await tester.pumpAndSettle();
  }

  Finder text(String t) => find.text(t);

  group('SetupFlowView', () {
    testWidgets('first step: progress, no back, no skip when required', (
      tester,
    ) async {
      await pumpFlow(tester);
      expect(text('Schritt 1 von 4'), findsOneWidget);
      expect(text('Frage name'), findsOneWidget);
      expect(find.byTooltip(_de.setupBack), findsNothing);
      expect(text(_de.setupSkip), findsNothing);
      expect(text(_de.setupNext), findsOneWidget);
    });

    testWidgets('a required step shows a plain error and stays', (
      tester,
    ) async {
      await pumpFlow(tester);
      await tester.tap(text(_de.setupNext));
      await tester.pumpAndSettle();
      expect(text(_de.errorInvalidData), findsOneWidget);
      expect(text('Schritt 1 von 4'), findsOneWidget);
    });

    testWidgets('a failing save is shown, nothing is lost', (tester) async {
      await pumpFlow(tester);
      repo.failSaveWith = const Storage('full');
      await tester.enterText(find.byType(TextField), 'Anna');
      await tester.tap(text(_de.setupNext));
      await tester.pumpAndSettle();
      expect(text(_de.errorStorage), findsOneWidget);
      expect(text('Schritt 1 von 4'), findsOneWidget);
      repo.failSaveWith = null;
      // The snack bar covers the button until it times out.
      await tester.pump(const Duration(seconds: 10));
      await tester.pumpAndSettle();
      await tester.tap(text(_de.setupNext));
      await tester.pumpAndSettle();
      expect(text('Schritt 2 von 4'), findsOneWidget);
    });

    testWidgets('a failing read offers retry', (tester) async {
      repo.failLoadWith = const Storage('disk');
      await pumpFlow(tester);
      expect(text(_de.errorStorage), findsOneWidget);
      repo.failLoadWith = null;
      await tester.tap(text(_de.retry));
      await tester.pumpAndSettle();
      expect(text('Schritt 1 von 4'), findsOneWidget);
    });

    testWidgets('the result updates live while typing', (tester) async {
      await pumpFlow(tester);
      expect(text('Ergebnis: -'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Ann');
      await tester.pump();
      expect(text('Ergebnis: Ann'), findsOneWidget);
    });

    testWidgets('a text field does not leak into the next step', (
      tester,
    ) async {
      await pumpFlow(tester);
      await tester.enterText(find.byType(TextField), 'Anna');
      await tester.tap(text(_de.setupNext));
      await tester.pumpAndSettle();
      await tester.tap(text(_de.setupSkip));
      await tester.pumpAndSettle();
      expect(text('Frage handle'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Anna'), findsNothing);
    });

    testWidgets('walk through: yes/no, skip, back, finish', (tester) async {
      await pumpFlow(tester);
      await tester.enterText(find.byType(TextField), 'Anna');
      await tester.tap(text(_de.setupNext));
      await tester.pumpAndSettle();
      await tester.tap(text(_de.setupYes));
      await tester.pumpAndSettle();
      expect(text('Schritt 3 von 4'), findsOneWidget);
      await tester.tap(find.byTooltip(_de.setupBack));
      await tester.pumpAndSettle();
      expect(text('Schritt 2 von 4'), findsOneWidget);
      await tester.tap(text(_de.setupSkip));
      await tester.pumpAndSettle();
      await tester.tap(text(_de.setupSkip));
      await tester.pumpAndSettle();
      await tester.tap(text(_de.setupSkip));
      await tester.pumpAndSettle();
      expect(text('Alles eingerichtet'), findsOneWidget);
      expect(text('Name: Anna'), findsOneWidget);
      await tester.tap(text(_de.setupBack));
      await tester.pumpAndSettle();
      expect(text('Schritt 4 von 4'), findsOneWidget);
    });

    testWidgets('system back goes one step back, then leaves', (tester) async {
      await pumpFlow(tester);
      await tester.enterText(find.byType(TextField), 'Anna');
      await tester.tap(text(_de.setupNext));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(text('Schritt 1 von 4'), findsOneWidget);
    });

    testWidgets('a returning yes/no step shows the earlier answer', (
      tester,
    ) async {
      await pumpFlow(tester);
      await tester.enterText(find.byType(TextField), 'Anna');
      await tester.tap(text(_de.setupNext));
      await tester.pumpAndSettle();
      await tester.tap(text(_de.setupNo));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(_de.setupBack));
      await tester.pumpAndSettle();
      final no = tester.getSemantics(text(_de.setupNo));
      expect(no.flagsCollection.isSelected, Tristate.isTrue);
    });

    testWidgets('resumes after the app was killed', (tester) async {
      await pumpFlow(tester);
      await tester.enterText(find.byType(TextField), 'Anna');
      await tester.tap(text(_de.setupNext));
      await tester.pumpAndSettle();
      await tester.tap(text(_de.setupYes));
      await tester.pumpAndSettle();
      // Kill: tear the tree down, start a new one on the same storage.
      await tester.pumpWidget(const SizedBox());
      await pumpFlow(tester);
      expect(text('Schritt 3 von 4'), findsOneWidget);
      await tester.tap(find.byTooltip(_de.setupBack));
      await tester.pumpAndSettle();
      expect(tester.getSemantics(text(_de.setupYes)), isNotNull);
    });

    forEachMode(
      'is accessible',
      () => demoFlowView(FakeSetupStateRepository()),
      (tester, _, _) async {
        expect(find.byType(SetupFlowView), findsOneWidget);
        await expectAccessible(tester);
      },
    );
  });

  group('tap budgets (docs/ux-budgets.md)', () {
    testWidgets('input step: one tap on Weiter, typing is free', (
      tester,
    ) async {
      await pumpFlow(tester);
      final taps = TapCounter(tester);
      await taps.enterText(find.byType(TextField), 'Anna');
      await taps.tap(text(_de.setupNext));
      await tester.pumpAndSettle();
      expect(text('Schritt 2 von 4'), findsOneWidget);
      taps
        ..expectWithinBudget('setup_step_input')
        ..expectWithinBudget('setup_step_answer');
    });

    testWidgets('yes/no step: one tap on a card answers and moves on', (
      tester,
    ) async {
      await pumpFlow(tester);
      await tester.enterText(find.byType(TextField), 'Anna');
      await tester.tap(text(_de.setupNext));
      await tester.pumpAndSettle();
      final taps = TapCounter(tester);
      await taps.tap(text(_de.setupYes));
      await tester.pumpAndSettle();
      expect(text('Schritt 3 von 4'), findsOneWidget);
      taps
        ..expectWithinBudget('setup_step_yes_no')
        ..expectWithinBudget('setup_step_answer');
    });

    testWidgets('an optional step is skipped with one tap', (tester) async {
      await pumpFlow(tester);
      await tester.enterText(find.byType(TextField), 'Anna');
      await tester.tap(text(_de.setupNext));
      await tester.pumpAndSettle();
      final taps = TapCounter(tester);
      await taps.tap(text(_de.setupSkip));
      await tester.pumpAndSettle();
      expect(text('Schritt 3 von 4'), findsOneWidget);
      taps.expectWithinBudget('setup_step_skip');
    });

    testWidgets('finish: one tap on the next action', (tester) async {
      var acted = 0;
      await tester.pumpWidget(
        themedApp(
          FinishStep(
            title: 'Fertig',
            actionLabel: 'Los',
            onAction: () => acted++,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final taps = TapCounter(tester);
      await taps.tap(text('Los'));
      expect(acted, 1);
      taps.expectWithinBudget('setup_finish_action');
    });
  });

  group('StepScaffold', () {
    testWidgets('has no buttons it was not given', (tester) async {
      await tester.pumpWidget(
        themedApp(const StepScaffold(current: 1, total: 2, title: 'Frage')),
      );
      expect(find.byType(FilledButton), findsNothing);
      expect(find.byType(TextButton), findsNothing);
      expect(find.byType(IconButton), findsNothing);
    });

    testWidgets('the result is a live region', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        themedApp(
          const StepScaffold(
            current: 1,
            total: 2,
            title: 'Frage',
            result: Text('7,4 ct/km'),
          ),
        ),
      );
      final node = tester.getSemantics(find.text('7,4 ct/km'));
      expect(node.flagsCollection.isLiveRegion, isTrue);
      semantics.dispose();
    });

    forEachMode(
      'with every slot is accessible',
      () => StepScaffold(
        current: 2,
        total: 5,
        title: 'Wie hoch ist dein Verbrauch?',
        visual: const Icon(IconData(0xe1d7), size: 96),
        result: const Text('≈ 7,4 ct/km'),
        onNext: () {},
        onSkip: () {},
        onBack: () {},
        child: const TextField(
          decoration: InputDecoration(labelText: 'l/100 km'),
        ),
      ),
      (tester, _, _) async => expectAccessible(tester),
    );
  });

  group('YesNoStep', () {
    testWidgets('answers true and false', (tester) async {
      final answers = <bool>[];
      await tester.pumpWidget(
        themedApp(
          YesNoStep(
            current: 1,
            total: 3,
            title: 'Hast du ein Auto?',
            onAnswer: answers.add,
          ),
        ),
      );
      await tester.tap(text(_de.setupYes));
      await tester.tap(text(_de.setupNo));
      expect(answers, [true, false]);
    });

    forEachMode(
      'is accessible, also with an earlier answer',
      () => YesNoStep(
        current: 2,
        total: 5,
        title: 'Hast du ein Auto?',
        selected: true,
        visual: const Icon(IconData(0xe1d7), size: 96),
        onAnswer: (_) {},
        onSkip: () {},
        onBack: () {},
      ),
      (tester, _, _) async => expectAccessible(tester),
    );
  });

  group('SetupProgressBar', () {
    forEachMode(
      'is accessible and reads as one sentence',
      () => const SetupProgressBar(current: 2, total: 5),
      (tester, _, _) async {
        await expectAccessible(tester);
        expect(find.text('Schritt 2 von 5'), findsOneWidget);
      },
    );
  });

  group('FinishStep', () {
    final haptics = <Object?>[];
    setUp(() {
      haptics.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'HapticFeedback.vibrate') {
              haptics.add(call.arguments);
            }
            return null;
          });
    });
    tearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    Widget finish({bool reduceMotion = false}) => Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: FinishStep(
          title: 'Alles eingerichtet',
          summary: const ['Name: Anna'],
          actionLabel: 'Los',
          onAction: () {},
        ),
      ),
    );

    testWidgets('celebrates with one light haptic tick', (tester) async {
      await tester.pumpWidget(themedApp(finish()));
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpAndSettle();
      expect(haptics, ['HapticFeedbackType.lightImpact']);
    });

    testWidgets('reduce motion: no animation, still the haptic tick', (
      tester,
    ) async {
      await tester.pumpWidget(themedApp(finish(reduceMotion: true)));
      expect(tester.hasRunningAnimations, isFalse);
      expect(haptics, ['HapticFeedbackType.lightImpact']);
    });

    testWidgets('rebuilding does not celebrate again', (tester) async {
      await tester.pumpWidget(themedApp(finish()));
      await tester.pumpAndSettle();
      await tester.pumpWidget(themedApp(finish()));
      await tester.pumpAndSettle();
      expect(haptics, hasLength(1));
    });

    testWidgets('shows no back button unless given one', (tester) async {
      await tester.pumpWidget(themedApp(finish()));
      await tester.pumpAndSettle();
      expect(text(_de.setupBack), findsNothing);
    });

    forEachMode(
      'is accessible',
      () => FinishStep(
        title: 'Alles eingerichtet',
        summary: const ['Name: Anna', 'PayPal.Me: anna'],
        actionLabel: 'Los',
        onAction: () {},
        onBack: () {},
      ),
      (tester, _, _) async => expectAccessible(tester),
    );
  });
}
