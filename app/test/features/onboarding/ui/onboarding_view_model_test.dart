import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/groups/data/repositories/groups_repository.dart';
import 'package:mitlio/features/onboarding/ui/onboarding_view_model.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../../helpers/fake_app.dart';
import '../../repo_test_support.dart';

void main() {
  late FakeApp app;
  late ProviderContainer container;

  OnboardingViewModel vm() =>
      container.read(onboardingViewModelProvider.notifier);
  bool busy() => container.read(onboardingViewModelProvider).busy;
  Future<List<Group>> groups() => app.groups.watchGroups().first;

  setUp(() {
    app = FakeApp();
    container = app.container();
    addTearDown(container.dispose);
  });

  group('startCommute', () {
    test('creates exactly one euro group with the given name', () async {
      final created = ok(await vm().startCommute(groupName: ' Pendler '));
      expect(created.name, 'Pendler');
      expect(created.currency, Currency.eur);
      expect(await groups(), [created]);
      expect(busy(), isFalse);
    });

    test('a blank name is invalid and creates nothing', () async {
      final result = await vm().startCommute(groupName: '  ');
      expect((result as Err<Group, RepositoryError>).error, isA<InvalidData>());
      expect(await groups(), isEmpty);
    });

    test('a repository failure is returned and the screen is usable', () async {
      app.groups.failWith = const Storage('disk full');
      final result = await vm().startCommute(groupName: 'Pendler');
      expect(result, isA<Err<Group, RepositoryError>>());
      expect(busy(), isFalse);
      app.groups.failWith = null;
      expect(ok(await vm().startCommute(groupName: 'Pendler')).name, 'Pendler');
    });

    test('a second tap while busy creates no second group', () async {
      final first = vm().startCommute(groupName: 'Pendler');
      expect(busy(), isTrue);
      final second = await vm().startCommute(groupName: 'Pendler');
      expect(second, isA<Err<Group, RepositoryError>>());
      ok(await first);
      expect(await groups(), hasLength(1));
    });
  });
}
