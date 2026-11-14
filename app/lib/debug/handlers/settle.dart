import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/debug/drive_types.dart';
import 'package:mitlio/debug/handlers/payment.dart';
import 'package:mitlio/features/settle/ui/settle_view_model.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// `ext.mitlio.settle.markPaid` and `ext.mitlio.settle.list` (keys without
/// the `ext.mitlio.` prefix): the commands the settle screen uses. Nothing
/// here touches payment details. For the links use `payment.links`.
Map<String, DriveHandler> settleDriveHandlers(ProviderContainer c) => {
  'settle.markPaid': (p) async {
    final (fromId, toId) = (p['fromId'], p['toId']);
    final cents = int.tryParse(p['amountCents'] ?? '');
    if (fromId == null || toId == null || cents == null || cents <= 0) {
      return invalidParams('need fromId, toId, amountCents (> 0)');
    }
    final pair = await findMemberPair(c, fromId, toId);
    if (pair == null) return driveError(NotFound('member', '$fromId/$toId'));
    final vm = c.read(settleViewModelProvider(pair.group.id).notifier);
    return switch (await vm.markPaid(
      fromId: fromId,
      toId: toId,
      amountCents: cents,
    )) {
      Ok(:final value) => {
        'id': value.entry.settlement.id,
        'groupId': pair.group.id,
        'amount': cents,
      },
      Err(:final error) => driveError(error),
    };
  },
  'settle.list': (p) async {
    final groupId = p['groupId'];
    if (groupId == null) return invalidParams('need groupId');
    final vm = c.read(settleViewModelProvider(groupId).notifier);
    return switch (await vm.list()) {
      Ok(:final value) => {'groupId': groupId, ...value},
      Err(:final error) => driveError(error),
    };
  },
};
