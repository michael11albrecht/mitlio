import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/features/settle/data/services/payment_link_service.dart';

/// Override with a fake launcher in tests.
final linkLauncherProvider = Provider<LinkLauncher>(
  (ref) => const SystemLinkLauncher(),
);

final paymentLinkServiceProvider = Provider<PaymentLinkService>(
  (ref) => PaymentLinkService(launcher: ref.watch(linkLauncherProvider)),
);
