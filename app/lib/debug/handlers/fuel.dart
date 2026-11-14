import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/debug/drive_types.dart';
import 'package:mitlio/features/fuel/data/repositories/fuel_prices_repository.dart';
import 'package:mitlio/features/fuel/data/repositories/fuel_providers.dart';

/// `ext.mitlio.fuel.*`: the national average the app would show (keys
/// without the `ext.mitlio.` prefix). Never uses a location.
Map<String, DriveHandler> fuelDriveHandlers(ProviderContainer c) => {
  'fuel.prices': (p) async {
    final grade = FuelGrade.values.asNameMap()[p['type']];
    if (grade == null) return invalidParams('param type: e5, e10 or diesel');
    final repo = c.read(fuelPricesRepositoryProvider);
    return switch (await repo.national(grade)) {
      FuelFound(:final price, :final stale) => {
        'type': price.grade.name,
        'priceMilli': price.priceMilli,
        'scope': price.scope.name,
        'source': price.source,
        'attribution': price.attribution,
        'approximation': price.approximation?.name,
        'fetchedAt': price.fetchedAt.toIso8601String(),
        'stale': stale,
      },
      FuelMissing(:final reason) => {'error': reason.name},
    };
  },
};
