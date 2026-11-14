import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/debug/drive_types.dart';
import 'package:mitlio/features/balances/ui/balances_view_model.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// `ext.mitlio.balances.*`: a thin wrapper over the ViewModel the balances
/// screen uses (keys without the `ext.mitlio.` prefix).
Map<String, DriveHandler> balancesDriveHandlers(ProviderContainer c) => {
  // Always the simplified transfers, whatever the screen's toggle shows.
  'balances.get': (p) async {
    final groupId = p['groupId'];
    if (groupId == null) return invalidParams('need groupId');
    final vm = c.read(balancesViewModelProvider(groupId).notifier);
    return switch (await vm.load()) {
      Ok(:final value) => balancesJson(value, transfers: value.simplified),
      Err(:final error) => driveError(error),
    };
  },
};
