/// Pure Dart business logic for mitlio.
///
/// This package must never depend on Flutter, Drift, Supabase or Riverpod.
/// See docs/IMPLEMENTATION_PLAN.md §2.2 and §2.5.
library;

export 'src/allocation/allocate.dart';

/// Version of the domain rules, bumped whenever calculation semantics change.
const domainRulesVersion = 1;
