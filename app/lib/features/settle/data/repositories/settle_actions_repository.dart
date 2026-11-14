// Justification: all fields are final; no meta dependency for @immutable.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/members/data/repositories/payment_details_repository.dart';
import 'package:mitlio/features/settle/data/services/payment_link_service.dart';
import 'package:mitlio/features/settle/data/services/share_service.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// How a PayPal.Me link was handled.
enum PayPalOutcome {
  /// Handed to PayPal or the browser.
  opened,

  /// Nothing could open it; the link is on the clipboard.
  copied,
}

/// What a receiver can be paid with. Never carries the IBAN itself.
final class PayoutOptions {
  const PayoutOptions({
    required this.hasPaypal,
    required this.hasIban,
    this.ibanHint,
  });

  final bool hasPaypal;
  final bool hasIban;

  /// Masked IBAN (`DE89 •••• 3000`) for display.
  final String? ibanHint;

  bool get isEmpty => !hasPaypal && !hasIban;

  @override
  bool operator ==(Object other) =>
      other is PayoutOptions &&
      other.hasPaypal == hasPaypal &&
      other.hasIban == hasIban &&
      other.ibanHint == ibanHint;

  @override
  int get hashCode => Object.hash(hasPaypal, hasIban, ibanHint);
}

/// The side effects of paying someone: payment links, the EPC QR payload,
/// the clipboard and the share sheet. The IBAN stays inside this layer: it
/// only leaves as the QR payload and on the clipboard (plan §8).
abstract interface class SettleActionsRepository {
  /// [NotFound] if the member does not exist.
  Future<RepoResult<PayoutOptions>> options(String memberId);

  /// The EPC payload for paying [amount] to [memberId], or null if that is
  /// not possible (no IBAN, not euro, amount out of range).
  Future<RepoResult<String?>> epcPayload({
    required String memberId,
    required String memberName,
    required Money amount,
    required String remittance,
  });

  /// [InvalidData] if the member has no PayPal.Me handle.
  Future<RepoResult<PayPalOutcome>> openPayPal(String memberId, Money amount);

  /// Puts the IBAN of [memberId] on the clipboard. [InvalidData] if none.
  Future<RepoResult<void>> copyIban(String memberId);

  Future<RepoResult<void>> shareText(String text);
}

/// Payment details + link service + share sheet.
class PlatformSettleActionsRepository implements SettleActionsRepository {
  PlatformSettleActionsRepository({
    required this._details,
    required this._links,
    required this._launcher,
    required this._share,
  });

  final PaymentDetailsRepository _details;
  final PaymentLinkService _links;
  final LinkLauncher _launcher;
  final ShareService _share;

  /// Runs [body] with the stored details of [memberId].
  Future<RepoResult<T>> _withDetails<T>(
    String memberId,
    Future<RepoResult<T>> Function(PaymentDetails details) body,
  ) async => switch (await _details.get(memberId)) {
    Ok<PaymentDetails, RepositoryError>(:final value) => await body(value),
    Err<PaymentDetails, RepositoryError>(:final error) => Err(error),
  };

  @override
  Future<RepoResult<PayoutOptions>> options(String memberId) => _withDetails(
    memberId,
    (d) async => Ok(
      PayoutOptions(
        hasPaypal: d.paypalMe != null,
        hasIban: d.iban != null,
        ibanHint: d.ibanHint,
      ),
    ),
  );

  @override
  Future<RepoResult<String?>> epcPayload({
    required String memberId,
    required String memberName,
    required Money amount,
    required String remittance,
  }) => _withDetails(memberId, (d) async {
    final iban = d.iban;
    if (iban == null) return const Ok(null);
    final payload = _links.epcPayload(
      name: d.accountName ?? memberName,
      iban: iban,
      bic: d.bic,
      amount: amount,
      remittance: remittance,
    );
    return Ok(payload is Ok<String, EpcError> ? payload.value : null);
  });

  @override
  Future<RepoResult<PayPalOutcome>> openPayPal(
    String memberId,
    Money amount,
  ) => _withDetails(memberId, (d) async {
    final handle = d.paypalMe;
    if (handle == null) return const Err(InvalidData('no PayPal.Me handle'));
    final opened = await _links.openPayPal(handle, amount);
    if (opened is Ok<PaymentLinkOutcome, PayPalError>) {
      return Ok(
        opened.value == PaymentLinkOutcome.opened
            ? PayPalOutcome.opened
            : PayPalOutcome.copied,
      );
    }
    return const Err(InvalidData('PayPal link'));
  });

  @override
  Future<RepoResult<void>> copyIban(String memberId) =>
      _withDetails<void>(memberId, (d) async {
        final iban = d.iban;
        if (iban == null) return const Err(InvalidData('no IBAN'));
        await _launcher.copyToClipboard(iban);
        return const Ok(null);
      });

  @override
  Future<RepoResult<void>> shareText(String text) => guardStorage(() async {
    await _share.shareText(text);
    return const Ok(null);
  });
}
