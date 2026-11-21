import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:mitlio/features/profile/ui/entry_card_view_model.dart';

/// A card that is not needed: screens with inline cards in goldens and a11y
/// tests keep their layout and touch no repository.
class StubEntryCardViewModel extends EntryCardViewModel {
  StubEntryCardViewModel(super.card);

  @override
  bool build() => false;
}

/// Hides every inline card.
List<Override> get noEntryCards => [
  entryCardViewModelProvider.overrideWith2(StubEntryCardViewModel.new),
];
