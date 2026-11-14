import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/router.dart';
import 'package:mitlio/debug/drive_types.dart';
import 'package:mitlio/features/balances/ui/balances_view_model.dart';
import 'package:mitlio/features/expenses/ui/expense_form_view_model.dart';
import 'package:mitlio/features/expenses/ui/expenses_view_model.dart';
import 'package:mitlio/features/groups/ui/group_detail_view_model.dart';
import 'package:mitlio/features/groups/ui/groups_view_model.dart';
import 'package:mitlio/features/rides/ui/rides_setup_view_model.dart';
import 'package:mitlio/features/rides/ui/rides_view_model.dart';
import 'package:mitlio/features/rides/ui/template_form_view_model.dart';
import 'package:mitlio/features/rides/ui/vehicle_form_view_model.dart';
import 'package:mitlio/features/trips/ui/trip_form_view_model.dart';

/// Screen name to `debugSnapshot()` lookup behind `ext.mitlio.state`.
/// ViewModels know nothing about it: this layer reads them.
class DebugSnapshotRegistry {
  final _snapshots = <String, DriveResult Function()>{};

  void register(String screen, DriveResult Function() snapshot) =>
      _snapshots[screen] = snapshot;

  void unregister(String screen) => _snapshots.remove(screen);

  Iterable<String> get screens => _snapshots.keys;

  DriveResult? snapshot(String screen) => _snapshots[screen]?.call();
}

/// Id of the group whose detail or edit screen is the current route.
String? _openGroupId(ProviderContainer c) {
  // `state` is the topmost route, so imperative pushes count too.
  final segments = c.read(routerProvider).state.uri.pathSegments;
  return segments.length >= 2 &&
          segments.first == 'groups' &&
          segments[1] != 'new'
      ? segments[1]
      : null;
}

/// Id of the group whose trip form is the current route.
String? _openTripGroupId(ProviderContainer c) {
  final segments = c.read(routerProvider).state.uri.pathSegments;
  return segments.length == 3 &&
          segments.first == 'groups' &&
          segments[2] == 'trip'
      ? segments[1]
      : null;
}

/// The open expense form: `/groups/:id/expenses/new` or
/// `/groups/:id/expenses/:expenseId`.
ExpenseFormKey? _openExpenseForm(ProviderContainer c) {
  final segments = c.read(routerProvider).state.uri.pathSegments;
  return segments.length == 4 &&
          segments.first == 'groups' &&
          segments[2] == 'expenses'
      ? (
          groupId: segments[1],
          expenseId: segments[3] == 'new' ? null : segments[3],
        )
      : null;
}

/// The open rides form: `/groups/:id/rides/vehicles/:vehicleId` or
/// `/groups/:id/rides/templates/:templateId` (`new` for a new one).
({String groupId, String kind, String? id})? _openRidesForm(
  ProviderContainer c,
) {
  final segments = c.read(routerProvider).state.uri.pathSegments;
  return segments.length == 5 &&
          segments.first == 'groups' &&
          segments[2] == 'rides' &&
          (segments[3] == 'vehicles' || segments[3] == 'templates')
      ? (
          groupId: segments[1],
          kind: segments[3],
          id: segments[4] == 'new' ? null : segments[4],
        )
      : null;
}

/// The registry with every screen wired to its ViewModel. Add a line per
/// slice. Only call under `kDebugMode`.
DebugSnapshotRegistry buildSnapshotRegistry(ProviderContainer c) =>
    DebugSnapshotRegistry()
      ..register(
        'groups',
        () => c.read(groupsViewModelProvider.notifier).debugSnapshot(),
      )
      ..register('group', () {
        final id = _openGroupId(c);
        return id == null
            ? {'status': 'not_open'}
            : c.read(groupDetailViewModelProvider(id).notifier).debugSnapshot();
      })
      ..register('expenses', () {
        final id = _openGroupId(c);
        return id == null
            ? {'status': 'not_open'}
            : c.read(expensesViewModelProvider(id).notifier).debugSnapshot();
      })
      ..register('expense_form', () {
        final key = _openExpenseForm(c);
        return key == null
            ? {'status': 'not_open'}
            : c
                  .read(expenseFormViewModelProvider(key).notifier)
                  .debugSnapshot();
      })
      ..register('trip', () {
        final id = _openTripGroupId(c);
        return id == null
            ? {'status': 'not_open'}
            : c.read(tripFormViewModelProvider(id).notifier).debugSnapshot();
      })
      ..register('balances', () {
        final id = _openGroupId(c);
        return id == null
            ? {'status': 'not_open'}
            : c.read(balancesViewModelProvider(id).notifier).debugSnapshot();
      })
      ..register('rides', () {
        final id = _openGroupId(c);
        return id == null
            ? {'status': 'not_open'}
            : c.read(ridesViewModelProvider(id).notifier).debugSnapshot();
      })
      ..register('rides_setup', () {
        final id = _openGroupId(c);
        return id == null
            ? {'status': 'not_open'}
            : c.read(ridesSetupViewModelProvider(id).notifier).debugSnapshot();
      })
      ..register('vehicle_form', () {
        final key = _openRidesForm(c);
        return key == null || key.kind != 'vehicles'
            ? {'status': 'not_open'}
            : c
                  .read(
                    vehicleFormViewModelProvider((
                      groupId: key.groupId,
                      vehicleId: key.id,
                    )).notifier,
                  )
                  .debugSnapshot();
      })
      ..register('template_form', () {
        final key = _openRidesForm(c);
        return key == null || key.kind != 'templates'
            ? {'status': 'not_open'}
            : c
                  .read(
                    templateFormViewModelProvider((
                      groupId: key.groupId,
                      templateId: key.id,
                    )).notifier,
                  )
                  .debugSnapshot();
      });
