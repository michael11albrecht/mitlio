import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:mitlio/features/balances/ui/balances_view_model.dart';
import 'package:mitlio/features/groups/data/repositories/groups_repository.dart';
import 'package:mitlio/features/members/data/repositories/members_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// Fixed state for goldens and a11y tests: no repository is touched.
class StubBalancesViewModel extends BalancesViewModel {
  StubBalancesViewModel(super.groupId, this.fixed);

  final BalancesState fixed;
  BalancesMode? lastMode;

  @override
  BalancesState build() => fixed;

  @override
  void setMode(BalancesMode mode) {
    lastMode = mode;
    final s = fixed;
    if (s is BalancesLoaded) {
      state = BalancesLoaded(
        group: s.group,
        balances: s.balances,
        simplified: s.simplified,
        pairwise: s.pairwise,
        mode: mode,
        hasEntries: s.hasEntries,
      );
    }
  }
}

List<Override> balancesStateOverride(BalancesState state) => [
  balancesViewModelProvider.overrideWith2(
    (id) => StubBalancesViewModel(id, state),
  ),
];

final _group = Group(
  id: 'g-1',
  name: 'Wochenende in den Bergen',
  currency: Currency.eur,
  createdBy: 'local',
  createdAt: DateTime.utc(2026),
);

GroupMember _m(int i, String name) =>
    GroupMember(id: 'm-$i', groupId: 'g-1', name: name, position: i);

final GroupMember _anna = _m(0, 'Anna Berg');
final GroupMember _ben = _m(1, 'Ben');
final GroupMember _chiara = _m(2, 'Chiara Rossi');
final GroupMember _dino = _m(3, 'Dino Kovač');

/// Anna +23,40 and Dino +5,00 get money; Ben -12,00 and Chiara -16,40 owe.
final sampleBalances = BalancesLoaded(
  group: _group,
  hasEntries: true,
  mode: BalancesMode.simplified,
  balances: [
    MemberBalance(member: _anna, cents: 2340),
    MemberBalance(member: _ben, cents: -1200),
    MemberBalance(member: _chiara, cents: -1640),
    MemberBalance(member: _dino, cents: 500),
  ],
  simplified: [
    Transfer(fromId: 'm-2', toId: 'm-0', amountCents: 1640),
    Transfer(fromId: 'm-1', toId: 'm-0', amountCents: 700),
    Transfer(fromId: 'm-1', toId: 'm-3', amountCents: 500),
  ],
  pairwise: [
    Transfer(fromId: 'm-1', toId: 'm-0', amountCents: 1200),
    Transfer(fromId: 'm-2', toId: 'm-0', amountCents: 1140),
    Transfer(fromId: 'm-2', toId: 'm-3', amountCents: 500),
  ],
);

BalancesLoaded get samplePairwise => BalancesLoaded(
  group: _group,
  hasEntries: true,
  mode: BalancesMode.pairwise,
  balances: sampleBalances.balances,
  simplified: sampleBalances.simplified,
  pairwise: sampleBalances.pairwise,
);

/// One person even, the rest square.
final settledBalances = BalancesLoaded(
  group: _group,
  hasEntries: true,
  mode: BalancesMode.simplified,
  balances: [
    MemberBalance(member: _anna, cents: 0),
    MemberBalance(member: _ben, cents: 0),
  ],
  simplified: const [],
  pairwise: const [],
);

final emptyBalances = BalancesLoaded(
  group: _group,
  hasEntries: false,
  mode: BalancesMode.simplified,
  balances: [
    MemberBalance(member: _anna, cents: 0),
    MemberBalance(member: _ben, cents: 0),
  ],
  simplified: const [],
  pairwise: const [],
);

Widget scopedBalances(List<Override> overrides, Widget child) =>
    ProviderScope(overrides: overrides, child: child);
