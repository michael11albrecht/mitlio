import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/features/profile/data/repositories/profile_providers.dart';
import 'package:mitlio/features/settle/data/repositories/settle_actions_repository.dart';
import 'package:mitlio/features/settle/data/services/payment_link_providers.dart';

/// Real platform actions by default; override with a fake in tests.
final settleActionsRepositoryProvider = Provider<SettleActionsRepository>(
  (ref) => PlatformSettleActionsRepository(
    details: ref.watch(payoutDetailsRepositoryProvider),
    links: ref.watch(paymentLinkServiceProvider),
    launcher: ref.watch(linkLauncherProvider),
    share: ref.watch(shareServiceProvider),
  ),
);
