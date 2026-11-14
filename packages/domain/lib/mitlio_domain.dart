/// Pure Dart business logic for mitlio.
///
/// This package must never depend on Flutter, Drift, Supabase or Riverpod.
/// See docs/IMPLEMENTATION_PLAN.md §2.2 and §2.5.
library;

export 'src/allocation/allocate.dart';
export 'src/balance/compute_balances.dart';
export 'src/core/result.dart';
export 'src/expense/expense.dart';
export 'src/expense/expense_error.dart';
export 'src/expense/settlement.dart';
export 'src/expense/settlement_error.dart';
export 'src/fx/fx.dart';
export 'src/members/member.dart';
export 'src/money/currency.dart';
export 'src/money/money.dart';
export 'src/payment/epc_qr.dart';
export 'src/payment/iban.dart';
export 'src/payment/paypal_me.dart';
export 'src/rides/ride.dart';
export 'src/rides/ride_aggregate.dart';
export 'src/rides/ride_cost.dart';
export 'src/rides/ride_period.dart';
export 'src/rides/ride_template.dart';
export 'src/rides/vehicle.dart';
export 'src/settle/simplify_debts.dart';
export 'src/split/compute_shares.dart';
export 'src/split/split_error.dart';
export 'src/split/split_spec.dart';
export 'src/trip/trip_cost.dart';
export 'src/trip/trip_error.dart';
export 'src/trip/trip_input.dart';
export 'src/trip/trip_units.dart';

/// Version of the domain rules, bumped whenever calculation semantics change.
const domainRulesVersion = 1;
