/// Pure Dart business logic for mitlio.
///
/// This package must never depend on Flutter, Drift, Supabase or Riverpod.
/// See docs/IMPLEMENTATION_PLAN.md §2.2 and §2.5.
library;

export 'src/allocation/allocate.dart';
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
export 'src/split/compute_shares.dart';
export 'src/split/split_error.dart';
export 'src/split/split_spec.dart';

/// Version of the domain rules, bumped whenever calculation semantics change.
const domainRulesVersion = 1;
