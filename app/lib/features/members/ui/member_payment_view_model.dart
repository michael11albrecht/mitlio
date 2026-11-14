import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/json_map.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/members/data/repositories/payment_details_providers.dart';
import 'package:mitlio/features/members/data/repositories/payment_details_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

// The form's field names and errors are part of this ViewModel's state.
export 'package:mitlio/features/members/data/repositories/payment_details_repository.dart'
    show PaymentField, PaymentFieldError;

sealed class MemberPaymentState {
  const MemberPaymentState();
}

final class MemberPaymentLoading extends MemberPaymentState {
  const MemberPaymentLoading();
}

final class MemberPaymentFailure extends MemberPaymentState {
  const MemberPaymentFailure(this.error);

  final RepositoryError error;
}

/// The form: stored [details], inline [fieldErrors] of the last save attempt
/// and [saveError] if the repository refused it.
final class MemberPaymentLoaded extends MemberPaymentState {
  const MemberPaymentLoaded({
    required this.details,
    this.fieldErrors = const {},
    this.saveError,
  });

  final PaymentDetails details;
  final Map<PaymentField, PaymentFieldError> fieldErrors;
  final RepositoryError? saveError;
}

/// Payment details of one member (PayPal.Me handle, IBAN, BIC, account name).
/// Auto-disposed so the IBAN does not outlive the sheet.
class MemberPaymentViewModel extends Notifier<MemberPaymentState> {
  MemberPaymentViewModel(this.memberId);

  final String memberId;

  @override
  MemberPaymentState build() {
    unawaited(_load());
    return const MemberPaymentLoading();
  }

  Future<void> _load() async {
    final result = await ref
        .read(paymentDetailsRepositoryProvider)
        .get(memberId);
    if (!ref.mounted) return;
    state = switch (result) {
      Ok(:final value) => MemberPaymentLoaded(details: value),
      Err(:final error) => MemberPaymentFailure(error),
    };
  }

  void retry() {
    state = const MemberPaymentLoading();
    unawaited(_load());
  }

  /// Validates inline, then stores. Blank fields are cleared. On invalid
  /// input nothing is written and `fieldErrors` says which fields to fix
  /// (`Err(InvalidData)`).
  Future<RepoResult<PaymentDetails>> save({
    String? paypalMe,
    String? iban,
    String? bic,
    String? accountName,
  }) async {
    final current = state;
    if (current is! MemberPaymentLoaded) {
      return const Err(InvalidData('details not loaded'));
    }
    final normalized = normalizePaymentDetails(
      memberId,
      paypalMe: paypalMe,
      iban: iban,
      bic: bic,
      accountName: accountName,
    );
    if (normalized case Err(:final error)) {
      state = MemberPaymentLoaded(
        details: current.details,
        fieldErrors: error,
      );
      return Err(
        InvalidData('invalid: ${error.keys.map((f) => f.name).join(', ')}'),
      );
    }
    final result = await ref
        .read(paymentDetailsRepositoryProvider)
        .save(
          memberId,
          paypalMe: paypalMe,
          iban: iban,
          bic: bic,
          accountName: accountName,
        );
    if (ref.mounted) {
      state = switch (result) {
        Ok(:final value) => MemberPaymentLoaded(details: value),
        Err(:final error) => MemberPaymentLoaded(
          details: current.details,
          saveError: error,
        ),
      };
    }
    return result;
  }

  /// Never contains the IBAN, BIC or account name: only whether they are set
  /// and the masked hint.
  JsonMap debugSnapshot() => switch (state) {
    MemberPaymentLoading() => {'status': 'loading', 'memberId': memberId},
    MemberPaymentFailure(:final error) => {
      'status': 'error',
      'memberId': memberId,
      'error': error.toString(),
    },
    MemberPaymentLoaded(
      :final details,
      :final fieldErrors,
      :final saveError,
    ) =>
      {
        'status': 'data',
        'memberId': memberId,
        'paypalMe': details.paypalMe,
        'ibanHint': details.ibanHint,
        'hasIban': details.iban != null,
        'hasBic': details.bic != null,
        'hasAccountName': details.accountName != null,
        'fieldErrors': {
          for (final e in fieldErrors.entries) e.key.name: e.value.name,
        },
        'saveError': saveError?.toString(),
      },
  };
}

// ignore: specify_nonobvious_property_types, the family provider type is not exported
final memberPaymentViewModelProvider = NotifierProvider.autoDispose
    .family<MemberPaymentViewModel, MemberPaymentState, String>(
      MemberPaymentViewModel.new,
    );
