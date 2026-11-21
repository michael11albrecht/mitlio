import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/debug/drive_types.dart';
import 'package:mitlio/features/profile/ui/my_qr_view_model.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// `ext.mitlio.profile.qr` and `profile.shareQr` (PU-T16; keys without the
/// `ext.mitlio.` prefix): thin wrappers over `MyQrViewModel`. The payload is
/// the EPC text the screen draws (it contains the IBAN, debug builds only).
Map<String, DriveHandler> myQrDriveHandlers(ProviderContainer c) {
  /// Keeps the autoDispose ViewModel alive while [body] runs, loaded fresh.
  Future<T> loaded<T>(Future<T> Function(MyQrState state) body) async {
    final sub = c.listen(myQrViewModelProvider, (_, _) {});
    try {
      await c.read(myQrViewModelProvider.notifier).load();
      return await body(c.read(myQrViewModelProvider));
    } finally {
      sub.close();
    }
  }

  return {
    'profile.qr': (_) => loaded(
      (state) async => switch (state) {
        MyQrLoaded(:final name, :final payload) => {
          'state': 'loaded',
          'name': name,
          'payload': payload,
        },
        MyQrNoIban() => {'state': 'noIban'},
        MyQrFailure(:final error) => driveError(error),
        MyQrLoading() => {'state': 'loading'},
      },
    ),
    'profile.shareQr': (_) => loaded(
      (_) async =>
          switch (await c.read(myQrViewModelProvider.notifier).share()) {
            Ok() => {'shared': true},
            Err(:final error) => driveError(error),
          },
    ),
  };
}
