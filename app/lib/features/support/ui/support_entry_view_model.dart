import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/features/support/data/support_providers.dart';

/// Whether the settings row "mitlio unterstützen" exists: only while the
/// remote flag `support_tips_enabled` is on (ADR-28, default off).
// ignore: specify_nonobvious_property_types, the autoDispose provider type is not exported
final supportRowVisibleProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.watch(supportRepositoryProvider).tipsEnabled(),
);
