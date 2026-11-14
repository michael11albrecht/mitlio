import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/router.dart';
import 'package:mitlio/debug/drive_types.dart';
import 'package:mitlio/features/groups/ui/group_detail_view_model.dart';
import 'package:mitlio/features/groups/ui/groups_view_model.dart';
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
      ..register('trip', () {
        final id = _openTripGroupId(c);
        return id == null
            ? {'status': 'not_open'}
            : c.read(tripFormViewModelProvider(id).notifier).debugSnapshot();
      });
