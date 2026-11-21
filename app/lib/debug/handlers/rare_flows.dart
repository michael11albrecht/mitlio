import 'dart:ui' show Locale;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mitlio/debug/drive_types.dart';
import 'package:mitlio/debug/handlers/rides.dart' show driveMonth;
import 'package:mitlio/features/onboarding/ui/first_group_view_model.dart';
import 'package:mitlio/features/rides/ui/commute_template_view_model.dart';
import 'package:mitlio/features/rides/ui/month_settle_flow_view_model.dart';
import 'package:mitlio/features/rides/ui/ride_settle_view_model.dart';
import 'package:mitlio/l10n/app_localizations.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// The finish actions of the rare flows moved onto the step flow (PU-T12;
/// keys without the `ext.mitlio.` prefix). The steps themselves are driven
/// with `setup.*`; these run what the finish screens' buttons run.
Map<String, DriveHandler> rareFlowsDriveHandlers(ProviderContainer c) => {
  // The finish action of `first_group`: creates the group answered via
  // `setup.*` (name, people, currency) and clears the flow.
  'onboarding.createGroup': (_) async {
    final sub = c.listen(firstGroupViewModelProvider, (_, _) {});
    try {
      return switch (await c
          .read(firstGroupViewModelProvider.notifier)
          .create()) {
        Ok(:final value) => {
          'id': value.id,
          'name': value.name,
          'currency': value.currency.code,
        },
        Err(:final error) => driveError(error),
      };
    } finally {
      sub.close();
    }
  },
  // The finish action of `commute_template:<groupId>`: stores the route
  // answered through `setup.*` and clears that group's flow.
  'rides.commute.save': (p) async {
    final groupId = p['groupId'];
    if (groupId == null) return invalidParams('need groupId');
    final provider = commuteTemplateViewModelProvider(groupId);
    final sub = c.listen(provider, (_, _) {});
    try {
      return switch (await c.read(provider.notifier).save()) {
        Ok(:final value) => {
          'id': value.id,
          'name': value.name,
          'distanceMeters': value.distanceMeters,
          'roundTrip': value.roundTrip,
          'vehicleId': value.vehicleId,
          'defaultDriverId': value.defaultDriverId,
          'defaultPassengerIds': value.defaultPassengerIds.toList()..sort(),
          'tollsCents': value.tollsCents,
        },
        Err(:final error) => driveError(error),
      };
    } finally {
      sub.close();
    }
  },
  // The finish action of `month_settle:<groupId>:<YYYY-MM>`: settles the
  // month once its two looks were answered through `setup.*`.
  'rides.settleFlow.confirm': (p) async {
    final groupId = p['groupId'];
    final month = driveMonth(p['month']);
    if (groupId == null || month == null) {
      return invalidParams('need groupId and month (YYYY-MM)');
    }
    final provider = monthSettleFlowViewModelProvider((
      groupId: groupId,
      month: month,
    ));
    final sub = c.listen(provider, (_, _) {});
    final l10n = lookupAppLocalizations(const Locale('de'));
    try {
      return switch (await c
          .read(provider.notifier)
          .confirm(
            titleOf: (name, m) =>
                l10n.ridesSettleExpenseTitle(monthKey(m), name),
          )) {
        Ok(:final value) => {
          'month': monthKey(value.month),
          'rideCount': value.rideCount,
          'expenseIds': [for (final e in value.expenses) e.expense.id],
        },
        Err(:final error) => driveError(error),
      };
    } finally {
      sub.close();
    }
  },
};
