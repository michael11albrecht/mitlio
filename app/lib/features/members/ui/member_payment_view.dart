import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/theme/theme.dart';
import 'package:mitlio/core/widgets/error_state.dart';
import 'package:mitlio/features/members/ui/member_payment_view_model.dart';
import 'package:mitlio/l10n/app_localizations.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// Opens the payment details of a member in a bottom sheet (no dialog).
Future<void> showMemberPaymentSheet(
  BuildContext context, {
  required String memberId,
  required String memberName,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) =>
      MemberPaymentSheet(memberId: memberId, memberName: memberName),
);

/// "Zahlungsdaten": PayPal.Me handle, IBAN, BIC (optional) and account holder
/// of one member, validated inline. Saving closes the sheet; leaving the
/// fields blank clears them.
class MemberPaymentSheet extends ConsumerStatefulWidget {
  const MemberPaymentSheet({
    required this.memberId,
    required this.memberName,
    super.key,
  });

  final String memberId;
  final String memberName;

  @override
  ConsumerState<MemberPaymentSheet> createState() => _MemberPaymentSheetState();
}

class _MemberPaymentSheetState extends ConsumerState<MemberPaymentSheet> {
  final _paypal = TextEditingController();
  final _iban = TextEditingController();
  final _bic = TextEditingController();
  final _accountName = TextEditingController();
  var _filled = false;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    final provider = memberPaymentViewModelProvider(widget.memberId);
    _fill(ref.read(provider));
    ref.listenManual(provider, (_, next) => setState(() => _fill(next)));
  }

  /// Fills the fields once with the stored values; later edits are the user's.
  void _fill(MemberPaymentState state) {
    if (state is! MemberPaymentLoaded || _filled) return;
    _filled = true;
    _paypal.text = state.details.paypalMe ?? '';
    _iban.text = state.details.iban ?? '';
    _bic.text = state.details.bic ?? '';
    _accountName.text = state.details.accountName ?? '';
  }

  @override
  void dispose() {
    _paypal.dispose();
    _iban.dispose();
    _bic.dispose();
    _accountName.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final vm = ref.read(
      memberPaymentViewModelProvider(widget.memberId).notifier,
    );
    setState(() => _busy = true);
    final result = await vm.save(
      paypalMe: _paypal.text,
      iban: _iban.text,
      bic: _bic.text,
      accountName: _accountName.text,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (result is Ok) Navigator.of(context).pop();
  }

  String? _error(
    AppLocalizations l10n,
    Map<PaymentField, PaymentFieldError> errors,
    PaymentField field,
  ) {
    final error = errors[field];
    if (error == null) return null;
    return switch (field) {
      PaymentField.paypalMe => l10n.paymentErrorPaypal,
      PaymentField.iban when _iban.text.trim().isEmpty =>
        l10n.paymentErrorIbanMissing,
      PaymentField.iban when error == PaymentFieldError.checksum =>
        l10n.paymentErrorIbanChecksum,
      PaymentField.iban => l10n.paymentErrorIban,
      PaymentField.bic => l10n.paymentErrorBic,
      PaymentField.accountName => l10n.paymentErrorAccountName,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final vm = ref.read(
      memberPaymentViewModelProvider(widget.memberId).notifier,
    );
    final state = ref.watch(memberPaymentViewModelProvider(widget.memberId));
    return switch (state) {
      MemberPaymentLoading() => const SizedBox(
        height: Sizes.stateIcon * 3,
        child: Center(child: CircularProgressIndicator()),
      ),
      MemberPaymentFailure() => ErrorState(onRetry: vm.retry),
      MemberPaymentLoaded(:final fieldErrors, :final saveError) => SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: Spacing.md,
            right: Spacing.md,
            bottom: MediaQuery.viewInsetsOf(context).bottom + Spacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.paymentSectionTitle,
                style: theme.textTheme.titleLarge,
              ),
              Text(widget.memberName, style: theme.textTheme.bodyMedium),
              const SizedBox(height: Spacing.md),
              TextField(
                controller: _paypal,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: l10n.paymentPaypalLabel,
                  errorText: _error(l10n, fieldErrors, PaymentField.paypalMe),
                ),
              ),
              const SizedBox(height: Spacing.sm),
              TextField(
                controller: _iban,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.characters,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  labelText: l10n.paymentIbanLabel,
                  errorText: _error(l10n, fieldErrors, PaymentField.iban),
                ),
              ),
              const SizedBox(height: Spacing.sm),
              TextField(
                controller: _bic,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.characters,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  labelText: l10n.paymentBicLabel,
                  errorText: _error(l10n, fieldErrors, PaymentField.bic),
                ),
              ),
              const SizedBox(height: Spacing.sm),
              TextField(
                controller: _accountName,
                textInputAction: TextInputAction.done,
                textCapitalization: TextCapitalization.words,
                onSubmitted: (_) => unawaited(_save()),
                decoration: InputDecoration(
                  labelText: l10n.paymentAccountNameLabel,
                  errorText: _error(
                    l10n,
                    fieldErrors,
                    PaymentField.accountName,
                  ),
                ),
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                saveError == null ? l10n.paymentPrivacyHint : l10n.errorMessage,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: saveError == null
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: Spacing.md),
              FilledButton(
                onPressed: _busy ? null : () => unawaited(_save()),
                child: Text(l10n.paymentSave),
              ),
            ],
          ),
        ),
      ),
    };
  }
}
