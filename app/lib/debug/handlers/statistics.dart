import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/debug/drive_types.dart';
import 'package:mitlio/features/statistics/ui/statistics_view_model.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

StatsPeriod? _period(String? name) =>
    StatsPeriod.values.where((p) => p.name == name).firstOrNull;

/// `ext.mitlio.statistics.*`: thin wrappers over the ViewModel the
/// statistics screen uses (keys without the `ext.mitlio.` prefix).
Map<String, DriveHandler> statisticsDriveHandlers(ProviderContainer c) => {
  // The numbers for `period` (default: the screen's), without touching it.
  'statistics.get': (p) async {
    final groupId = p['groupId'];
    if (groupId == null) return invalidParams('need groupId');
    final period = _period(p['period']);
    if (p['period'] != null && period == null) {
      return invalidParams('period: ${StatsPeriod.values.map((e) => e.name)}');
    }
    final vm = c.read(statisticsViewModelProvider(groupId).notifier);
    return switch (await vm.load(period)) {
      Ok(:final value) => statisticsJson(value),
      Err(:final error) => driveError(error),
    };
  },
  // The period picker: the same command as tapping a chip.
  'statistics.period': (p) async {
    final groupId = p['groupId'];
    final period = _period(p['period']);
    if (groupId == null || period == null) {
      return invalidParams('need groupId and period');
    }
    c.read(statisticsViewModelProvider(groupId).notifier).setPeriod(period);
    return {'period': period.name};
  },
};
