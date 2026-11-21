import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/profile/ui/car_edit_view.dart';
import 'package:mitlio/features/profile/ui/car_edit_view_model.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../../helpers/a11y.dart';

/// Fixed state: no repository is touched.
class _Stub extends CarEditViewModel {
  _Stub(super.carId, this.fixed);

  final CarEditState fixed;

  @override
  CarEditState build() => fixed;
}

void main() {
  for (final (name, state) in <(String, CarEditState)>[
    (
      'data',
      const CarEditReady(
        name: 'Golf',
        fuelType: FuelType.petrol,
        consumptionMilli: 6500,
        wearMilli: 80,
        showErrors: false,
        saving: false,
      ),
    ),
    (
      'electric with errors',
      const CarEditReady(
        name: '',
        fuelType: FuelType.electric,
        consumptionMilli: null,
        wearMilli: null,
        showErrors: true,
        saving: false,
      ),
    ),
    ('failure', const CarEditFailure(NotFound('vehicle', 'x'))),
  ]) {
    forEachMode(
      'edit a personal car: $name',
      () => ProviderScope(
        overrides: [
          carEditViewModelProvider.overrideWith2((id) => _Stub(id, state)),
        ],
        child: const CarEditView(carId: 'c-1'),
      ),
      (tester, _, _) => expectAccessible(tester),
    );
  }
}
