import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/clock.dart';
import 'package:mitlio/core/providers.dart';
import 'package:mitlio/features/support/data/repositories/fake_support_repository.dart';
import 'package:mitlio/features/support/data/support_models.dart';
import 'package:mitlio/features/support/data/support_providers.dart';
import 'package:mitlio/features/support/ui/support_prompt_view_model.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

final _now = DateTime.utc(2026, 12);

({ProviderContainer c, FakeSupportRepository repo, FixedClock clock}) _setup({
  bool enabled = true,
  SupportPromptState state = const SupportPromptState(),
}) {
  final repo = FakeSupportRepository(enabled: enabled, state: state);
  final clock = FixedClock(_now);
  final c = ProviderContainer(
    overrides: [
      supportRepositoryProvider.overrideWithValue(repo),
      clockProvider.overrideWithValue(clock),
    ],
  );
  addTearDown(c.dispose);
  return (c: c, repo: repo, clock: clock);
}

/// A new visit of the "all settled" screen.
Future<bool> _visit(ProviderContainer c) async {
  final sub = c.listen(supportPromptViewModelProvider, (_, _) {});
  addTearDown(sub.close);
  await c.read(supportPromptViewModelProvider.notifier).settledScreenReached();
  return c.read(supportPromptViewModelProvider);
}

void main() {
  test('nothing is visible before the screen is reached', () {
    final s = _setup();
    expect(s.c.read(supportPromptViewModelProvider), isFalse);
  });

  group('flag off', () {
    test('nothing is visible and nothing is counted', () async {
      final s = _setup(
        enabled: false,
        state: const SupportPromptState(settledSinceShown: 99),
      );
      expect(await _visit(s.c), isFalse);
      expect(s.repo.state.settledSinceShown, 99);
    });
  });

  group('rate limit', () {
    test('the first four settlements show nothing, the fifth shows', () async {
      final s = _setup();
      for (var i = 1; i <= 4; i++) {
        expect(await _visit(s.c), isFalse, reason: 'settlement $i');
        expect(s.repo.state.settledSinceShown, i);
      }
      expect(await _visit(s.c), isTrue);
    });

    test('showing resets the count and stamps the time', () async {
      final s = _setup(
        state: const SupportPromptState(settledSinceShown: 4),
      );
      expect(await _visit(s.c), isTrue);
      expect(s.repo.state.settledSinceShown, 0);
      expect(s.repo.state.lastShown, _now);
    });

    test('not twice within 30 days, however many settlements', () async {
      final s = _setup(
        state: SupportPromptState(
          settledSinceShown: 20,
          lastShown: _now.subtract(const Duration(days: 29)),
        ),
      );
      expect(await _visit(s.c), isFalse);
      expect(s.repo.state.settledSinceShown, 21, reason: 'still counts');
    });

    test('after 30 days the next settlement shows it again', () async {
      final s = _setup(
        state: SupportPromptState(
          settledSinceShown: 5,
          lastShown: _now.subtract(const Duration(days: 30)),
        ),
      );
      expect(await _visit(s.c), isTrue);
    });

    test('a clock set back does not unlock the line early', () async {
      final s = _setup(
        state: SupportPromptState(
          settledSinceShown: 9,
          lastShown: _now.add(const Duration(days: 3)),
        ),
      );
      expect(await _visit(s.c), isFalse);
    });
  });

  group('dismiss', () {
    test('"Nicht mehr zeigen" hides the line for good', () async {
      final s = _setup(state: const SupportPromptState(settledSinceShown: 4));
      expect(await _visit(s.c), isTrue);
      final r = await s.c
          .read(supportPromptViewModelProvider.notifier)
          .dismissForever();
      expect(r, isA<Ok<void, Object>>());
      expect(s.c.read(supportPromptViewModelProvider), isFalse);
      expect(s.repo.state.dismissed, isTrue);
      s.clock.advance(const Duration(days: 400));
      s.repo.state = s.repo.state.copyWith(settledSinceShown: 50);
      expect(await _visit(s.c), isFalse);
    });

    test(
      'a dismissal that cannot be saved is reported and stays visible',
      () async {
        final s = _setup(state: const SupportPromptState(settledSinceShown: 4));
        await _visit(s.c);
        s.repo.failStorage = true;
        final r = await s.c
            .read(supportPromptViewModelProvider.notifier)
            .dismissForever();
        expect(r, isA<Err<void, Object>>());
        expect(s.c.read(supportPromptViewModelProvider), isTrue);
      },
    );
  });

  test('state that cannot be read shows nothing, it is only a hint', () async {
    final s = _setup(state: const SupportPromptState(settledSinceShown: 4))
      ..repo.failStorage = true;
    expect(await _visit(s.c), isFalse);
  });
}
