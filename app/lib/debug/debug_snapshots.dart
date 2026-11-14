import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/debug/drive_types.dart';

/// ViewModels register their `debugSnapshot()` here (`ext.mitlio.state`).
class DebugSnapshotRegistry {
  final _snapshots = <String, DriveResult Function()>{};

  void register(String screen, DriveResult Function() snapshot) =>
      _snapshots[screen] = snapshot;

  void unregister(String screen) => _snapshots.remove(screen);

  Iterable<String> get screens => _snapshots.keys;

  DriveResult? snapshot(String screen) => _snapshots[screen]?.call();
}

final debugSnapshotRegistryProvider = Provider<DebugSnapshotRegistry>(
  (ref) => DebugSnapshotRegistry(),
);
