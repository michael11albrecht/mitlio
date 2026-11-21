import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/profile/ui/my_qr_view.dart';
import 'package:mitlio/features/profile/ui/my_qr_view_model.dart';

import '../../../helpers/a11y.dart';

/// Fixed state: no repository is touched.
class _Stub extends MyQrViewModel {
  _Stub(this.fixed);

  final MyQrState fixed;

  @override
  MyQrState build() => fixed;
}

void main() {
  for (final (name, state) in <(String, MyQrState)>[
    (
      'code',
      const MyQrLoaded(
        name: 'Anna Beispiel',
        payload: 'BCD\n002\n1\nSCT\n\nAnna\nDE89370400440532013000\n\n\n',
      ),
    ),
    ('no IBAN', const MyQrNoIban()),
    ('failure', const MyQrFailure(Storage('x'))),
  ]) {
    forEachMode(
      'my QR code: $name',
      () => ProviderScope(
        overrides: [myQrViewModelProvider.overrideWith(() => _Stub(state))],
        child: const MyQrView(),
      ),
      (tester, _, _) => expectAccessible(tester),
    );
  }
}
