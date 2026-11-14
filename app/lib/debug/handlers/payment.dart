import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/debug/drive_types.dart';
import 'package:mitlio/features/groups/data/repositories/groups_providers.dart';
import 'package:mitlio/features/groups/data/repositories/groups_repository.dart';
import 'package:mitlio/features/members/data/repositories/members_providers.dart';
import 'package:mitlio/features/members/data/repositories/members_repository.dart';
import 'package:mitlio/features/members/data/repositories/payment_details_providers.dart';
import 'package:mitlio/features/members/data/repositories/payment_details_repository.dart';
import 'package:mitlio/features/settle/data/services/payment_link_providers.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// The group that holds both members, with the two members.
typedef MemberPair = ({Group group, GroupMember from, GroupMember to});

Future<MemberPair?> findMemberPair(
  ProviderContainer c,
  String fromId,
  String toId,
) async {
  final groups = await c.read(groupsRepositoryProvider).watchGroups().first;
  for (final group in groups) {
    final list = await c.read(membersRepositoryProvider).list(group.id);
    if (list case Ok(:final value)) {
      final from = value.where((m) => m.id == fromId).firstOrNull;
      final to = value.where((m) => m.id == toId).firstOrNull;
      if (from != null && to != null) {
        return (group: group, from: from, to: to);
      }
    }
  }
  return null;
}

/// `ext.mitlio.members.setPayment` and `ext.mitlio.payment.links` (keys
/// without the `ext.mitlio.` prefix). Responses never contain the IBAN, BIC
/// or account name, except inside the EPC payload that needs them.
Map<String, DriveHandler> paymentDriveHandlers(ProviderContainer c) => {
  'members.setPayment': (p) async {
    final memberId = p['memberId'];
    if (memberId == null) return invalidParams('need memberId');
    final saved = await c
        .read(paymentDetailsRepositoryProvider)
        .save(
          memberId,
          paypalMe: p['paypalMe'],
          iban: p['iban'],
          bic: p['bic'],
          accountName: p['accountName'],
        );
    return switch (saved) {
      Ok(:final value) => {
        'memberId': memberId,
        'paypalMe': value.paypalMe,
        'ibanHint': value.ibanHint,
        'hasIban': value.iban != null,
      },
      Err(:final error) => driveError(error),
    };
  },
  'payment.links': (p) async {
    final (fromId, toId) = (p['fromId'], p['toId']);
    final cents = int.tryParse(p['amountCents'] ?? '');
    if (fromId == null || toId == null || cents == null || cents <= 0) {
      return invalidParams('need fromId, toId, amountCents (> 0)');
    }
    final pair = await findMemberPair(c, fromId, toId);
    if (pair == null) return driveError(NotFound('member', '$fromId/$toId'));
    final PaymentDetails d;
    switch (await c.read(paymentDetailsRepositoryProvider).get(toId)) {
      case Ok(:final value):
        d = value;
      case Err(:final error):
        return driveError(error);
    }
    final service = c.read(paymentLinkServiceProvider);
    final amount = Money(cents, pair.group.currency);
    final handle = d.paypalMe;
    final iban = d.iban;
    final paypal = handle == null ? null : service.paypalLink(handle, amount);
    final epc = iban == null
        ? null
        : service.epcPayload(
            name: d.accountName ?? pair.to.name,
            iban: iban,
            bic: d.bic,
            amount: amount,
            remittance: 'mitlio: ${pair.group.name}',
          );
    return {
      'paypalUrl': paypal is Ok<Uri, PayPalError>
          ? paypal.value.toString()
          : null,
      'paypalError': paypal is Err<Uri, PayPalError> ? '${paypal.error}' : null,
      'epcPayload': epc is Ok<String, EpcError> ? epc.value : null,
      'epcError': epc is Err<String, EpcError> ? '${epc.error}' : null,
    };
  },
};
