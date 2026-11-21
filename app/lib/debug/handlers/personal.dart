import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/core/ui/setup_flow/setup_flow_view_model.dart';
import 'package:mitlio/debug/drive_types.dart';
import 'package:mitlio/features/profile/data/repositories/profile_providers.dart';
import 'package:mitlio/features/profile/ui/car_cost_view_model.dart'
    show carCostFlow;
import 'package:mitlio/features/profile/ui/car_edit_view_model.dart';
import 'package:mitlio/features/profile/ui/car_setup_view_model.dart';
import 'package:mitlio/features/profile/ui/entry_card_view_model.dart';
import 'package:mitlio/features/profile/ui/group_car_picker_view_model.dart';
import 'package:mitlio/features/profile/ui/profile_entry_view_model.dart';
import 'package:mitlio/features/rides/ui/vehicle_link_view_model.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

DriveResult _car(Vehicle v) => {
  'id': v.id,
  'name': v.name,
  'fuelType': v.fuelType.name,
  'consumptionMilliPer100km': v.consumptionMilliPer100km,
  'wearMilliPerKm': v.wearMilliPerKm,
};

/// `ext.mitlio.cars.*`, `cards.*`, `profile.summary` and `members.isOwn`
/// (PU-T10, PU-T11): thin wrappers over the ViewModel commands the screens
/// use (keys without the `ext.mitlio.` prefix).
Map<String, DriveHandler> personalDriveHandlers(ProviderContainer c) {
  // The last personal edit, so `cars.undoEdit` can take it back like the
  // snackbar does.
  Undo? lastEdit;

  /// Keeps the autoDispose ViewModel alive while [body] runs.
  Future<T> alive<T>(
    ProviderListenable<Object?> provider,
    Future<T> Function() body,
  ) async {
    final sub = c.listen(provider, (_, _) {});
    try {
      return await body();
    } finally {
      sub.close();
    }
  }

  return {
    'cars.list': (_) async {
      final cars = await c
          .read(userVehiclesRepositoryProvider)
          .watchVehicles()
          .first;
      return {
        'cars': [for (final v in cars) _car(v)],
      };
    },
    // The finish action of the car flow: saves the car answered via
    // `setup.*` (`car_setup`, `car_cost`) into "Meine Autos".
    'cars.add': (_) async {
      // The answers are read from the saved progress, so wait for it.
      for (final flow in [carSetupFlow, carCostFlow]) {
        await c.read(setupFlowViewModelProvider(flow).notifier).restoring;
      }
      return switch (await c.read(carSetupViewModelProvider.notifier).save()) {
        Ok(:final value) => _car(value),
        Err(:final error) => driveError(error),
      };
    },
    // Params: id (required), name, fuelType, consumptionMilli, wearMilli.
    'cars.edit': (p) async {
      final id = p['id'];
      if (id == null) return invalidParams('need id');
      final provider = carEditViewModelProvider(id);
      return alive(provider, () async {
        // The form loads the car in the background.
        while (c.read(provider) is CarEditLoading) {
          await Future<void>.delayed(Duration.zero);
        }
        if (c.read(provider) case CarEditFailure(:final error)) {
          return driveError(error);
        }
        final vm = c.read(provider.notifier);
        final name = p['name'];
        if (name != null) vm.setName(name);
        final fuel = FuelType.values.asNameMap()[p['fuelType']];
        if (fuel != null) vm.setFuelType(fuel);
        final consumption = int.tryParse(p['consumptionMilli'] ?? '');
        if (consumption != null) vm.setConsumption(consumption);
        final wear = int.tryParse(p['wearMilli'] ?? '');
        if (wear != null) vm.setWear(wear);
        return switch (await vm.save()) {
          Ok(:final value) => () {
            lastEdit = value.undo;
            return {'car': _car(value.car), 'groups': value.groups};
          }(),
          Err(:final error) => driveError(error),
        };
      });
    },
    'cars.undoEdit': (_) async {
      final undo = lastEdit;
      if (undo == null) return driveError(const Conflict('nothing to undo'));
      lastEdit = null;
      return switch (await undo()) {
        Ok() => {'ok': true},
        Err(:final error) => driveError(error),
      };
    },
    // Params: groupId, carId. The "Mein Auto" picker's command.
    'cars.use': (p) async {
      final (groupId, carId) = (p['groupId'], p['carId']);
      if (groupId == null || carId == null) {
        return invalidParams('need groupId, carId');
      }
      final provider = groupCarPickerViewModelProvider(groupId);
      return alive(provider, () async {
        return switch (await c.read(provider.notifier).use(carId)) {
          Ok(:final value) => _car(value),
          Err(:final error) => driveError(error),
        };
      });
    },
    // Param: vehicleId (a group vehicle): is it a linked copy?
    'cars.linked': (p) async {
      final id = p['vehicleId'];
      if (id == null) return invalidParams('need vehicleId');
      final provider = vehicleLinkViewModelProvider(id);
      return alive(provider, () async {
        while (c.read(provider).isLoading) {
          await Future<void>.delayed(Duration.zero);
        }
        final state = c.read(provider);
        if (state.error case final RepositoryError error) {
          return driveError(error);
        }
        return {'vehicleId': id, 'linked': state.value ?? false};
      });
    },
    'cars.unlink': (p) async {
      final id = p['vehicleId'];
      if (id == null) return invalidParams('need vehicleId');
      final provider = vehicleLinkViewModelProvider(id);
      return alive(provider, () async {
        return switch (await c.read(provider.notifier).unlink()) {
          Ok() => {'vehicleId': id, 'linked': false},
          Err(:final error) => driveError(error),
        };
      });
    },
    // Param: card (settlePayment | groupCar | newGroupProfile).
    'cards.state': (p) async {
      final card = EntryCard.values.asNameMap()[p['card']];
      if (card == null) return invalidParams('need card');
      final provider = entryCardViewModelProvider(card);
      return alive(provider, () async {
        await c.read(provider.notifier).refresh();
        return {'card': card.name, 'visible': c.read(provider)};
      });
    },
    'cards.dismiss': (p) async {
      final card = EntryCard.values.asNameMap()[p['card']];
      if (card == null) return invalidParams('need card');
      final provider = entryCardViewModelProvider(card);
      return alive(provider, () async {
        return switch (await c.read(provider.notifier).dismiss()) {
          Ok() => {'card': card.name, 'visible': false},
          Err(:final error) => driveError(error),
        };
      });
    },
    // What the settings row "Mein Profil" says; never any IBAN.
    'profile.summary': (_) async {
      return alive(profileEntryViewModelProvider, () async {
        await c.read(profileEntryViewModelProvider.notifier).refresh();
        return {'summary': c.read(profileEntryViewModelProvider).name};
      });
    },
    'members.isOwn': (p) async {
      final id = p['memberId'];
      if (id == null) return invalidParams('need memberId');
      return switch (await c.read(ownMemberRepositoryProvider).isOwn(id)) {
        Ok(:final value) => {'memberId': id, 'own': value},
        Err(:final error) => driveError(error),
      };
    },
  };
}
