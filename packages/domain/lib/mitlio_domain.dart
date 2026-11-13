/// Pure Dart business logic for mitlio.
///
/// This package must never depend on Flutter, Drift, Supabase or Riverpod.
/// See docs/IMPLEMENTATION_PLAN.md §2.2 and §2.5.
library;

export 'src/core/result.dart';
export 'src/members/member.dart';
export 'src/money/currency.dart';
export 'src/money/money.dart';
export 'src/payment/epc_qr.dart';
export 'src/payment/iban.dart';

/// Version of the domain rules, bumped whenever calculation semantics change.
const domainRulesVersion = 1;
