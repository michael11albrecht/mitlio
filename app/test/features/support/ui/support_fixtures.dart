import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/features/support/ui/support_prompt_line.dart';
import 'package:mitlio/features/support/ui/support_prompt_view_model.dart';
import 'package:mitlio/features/support/ui/tip_jar_sheet.dart';
import 'package:mitlio/features/support/ui/tip_jar_view_model.dart';

/// Fixed state for goldens and a11y tests: no repository is touched.
class StubTipJarViewModel extends TipJarViewModel {
  StubTipJarViewModel(this.fixed);

  final TipJarState fixed;

  @override
  TipJarState build() => fixed;

  @override
  Future<void> load() async {}
}

/// The line, visible, without asking any repository.
class StubSupportPromptViewModel extends SupportPromptViewModel {
  @override
  bool build() => true;

  @override
  Future<void> settledScreenReached() async {}
}

const tipProducts = [
  TipProduct(size: TipSize.small, price: '0,99 €'),
  TipProduct(size: TipSize.medium, price: '2,99 €'),
  TipProduct(size: TipSize.large, price: '4,99 €'),
];

/// The sheet in [state].
Widget tipJarSheet(TipJarState state) => ProviderScope(
  overrides: <Override>[
    tipJarViewModelProvider.overrideWith(() => StubTipJarViewModel(state)),
  ],
  child: const Material(child: TipJarSheet()),
);

/// The quiet line on its own.
Widget promptLine() => ProviderScope(
  overrides: <Override>[
    supportPromptViewModelProvider.overrideWith(StubSupportPromptViewModel.new),
  ],
  child: const Material(
    child: Padding(padding: EdgeInsets.all(16), child: SupportPromptLine()),
  ),
);
