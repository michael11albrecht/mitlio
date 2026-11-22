import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mitlio/core/app_version.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/db/database_provider.dart';
import 'package:mitlio/features/support/data/repositories/support_repository.dart';
import 'package:mitlio/features/support/data/services/tip_store_service.dart';
import 'package:mitlio/features/sync/data/sync_providers.dart';

/// The store; tests and DebugDrive override it with `FakeTipStoreService`.
final tipStoreServiceProvider = Provider<TipStoreService>(
  (ref) => InAppPurchaseTipStore(InAppPurchase.instance),
);

final supportRepositoryProvider = Provider<SupportRepository>(
  (ref) => DriftSupportRepository(
    db: ref.watch(appDatabaseProvider),
    remote: ref.watch(appConfigRemoteProvider),
    store: ref.watch(tipStoreServiceProvider),
    clock: ref.watch(clockProvider),
    platform: ref.watch(storePlatformProvider),
  ),
);
