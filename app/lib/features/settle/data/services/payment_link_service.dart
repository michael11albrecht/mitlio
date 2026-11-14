import 'package:flutter/services.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// What the platform does with a link. Faked in tests.
abstract interface class LinkLauncher {
  /// Opens [uri] in another app or the browser. False if nothing can.
  Future<bool> launchExternal(Uri uri);

  Future<void> copyToClipboard(String text);
}

/// `url_launcher` in external-application mode and the system clipboard.
class SystemLinkLauncher implements LinkLauncher {
  const SystemLinkLauncher();

  @override
  Future<bool> launchExternal(Uri uri) async {
    try {
      return false;
    } on Object {
      return false;
    }
  }

  @override
  Future<void> copyToClipboard(String text) =>
      Clipboard.setData(ClipboardData(text: text));
}

/// How [PaymentLinkService.openPayPal] ended; the UI shows "Link kopiert"
/// for [copied].
enum PaymentLinkOutcome { opened, copied }

/// Builds payment links with the domain and opens them.
class PaymentLinkService {
  PaymentLinkService({required this._launcher});

  final LinkLauncher _launcher;

  /// `https://paypal.me/<handle>/<amount><CODE>` for [money].
  Result<Uri, PayPalError> paypalLink(String handle, Money money) =>
      buildPayPalMeLink(handle: handle, amount: money);

  /// Opens the PayPal.Me link in an external app or browser; if none can
  /// handle it, copies the link and reports [PaymentLinkOutcome.copied].
  Future<Result<PaymentLinkOutcome, PayPalError>> openPayPal(
    String handle,
    Money money,
  ) async {
    switch (paypalLink(handle, money)) {
      case Err(:final error):
        return Err(error);
      case Ok(:final value):
        if (await _launcher.launchExternal(value)) {
          return const Ok(PaymentLinkOutcome.opened);
        }
        await _launcher.copyToClipboard(value.toString());
        return const Ok(PaymentLinkOutcome.copied);
    }
  }

  /// EPC (GiroCode) payload for a SEPA transfer; see the domain rules.
  Result<String, EpcError> epcPayload({
    required String name,
    required String iban,
    required Money amount,
    String? bic,
    String remittance = '',
  }) => buildEpcQrPayload(
    name: name,
    iban: iban,
    bic: bic,
    amount: amount,
    remittance: remittance,
  );
}
