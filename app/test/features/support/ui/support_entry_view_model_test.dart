import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/features/support/data/repositories/fake_support_repository.dart';
import 'package:mitlio/features/support/data/support_providers.dart';
import 'package:mitlio/features/support/ui/support_entry_view_model.dart';

void main() {
  for (final (enabled, shown) in [(false, false), (true, true)]) {
    test('settings row visible = flag ($enabled)', () async {
      final c = ProviderContainer(
        overrides: [
          supportRepositoryProvider.overrideWithValue(
            FakeSupportRepository(enabled: enabled),
          ),
        ],
      );
      addTearDown(c.dispose);
      expect(await c.read(supportRowVisibleProvider.future), shown);
    });
  }
}
