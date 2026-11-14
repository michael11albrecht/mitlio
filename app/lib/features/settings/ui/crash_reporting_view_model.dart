import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/providers.dart';

/// The opt-in crash reporting choice. [available] is false in builds without
/// a DSN: the choice is then stored but nothing can be sent.
class CrashReportingState {
  const CrashReportingState({required this.enabled, required this.available});

  final bool enabled;
  final bool available;
}

/// "Absturzberichte senden": off by default, the user decides.
class CrashReportingViewModel extends Notifier<CrashReportingState> {
  @override
  CrashReportingState build() => _read();

  CrashReportingState _read() {
    final reporter = ref.read(crashReporterProvider);
    return CrashReportingState(
      enabled: reporter.isEnabled,
      available: reporter.isAvailable,
    );
  }

  Future<void> setEnabled({required bool enabled}) async {
    await ref.read(crashReporterProvider).setEnabled(enabled: enabled);
    if (ref.mounted) state = _read();
  }
}

final crashReportingViewModelProvider =
    NotifierProvider<CrashReportingViewModel, CrashReportingState>(
      CrashReportingViewModel.new,
    );
