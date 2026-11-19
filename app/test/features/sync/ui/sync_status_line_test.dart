import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/remote/remote_error.dart';
import 'package:mitlio/core/remote/remote_error_text.dart';
import 'package:mitlio/features/sync/data/sync_providers.dart';
import 'package:mitlio/features/sync/data/sync_status.dart';
import 'package:mitlio/features/sync/ui/sync_status_line.dart';
import 'package:mitlio/features/sync/ui/sync_status_view_model.dart';
import 'package:mitlio/l10n/app_localizations.dart';
import 'package:mitlio/l10n/app_localizations_de.dart';
import 'package:mitlio/l10n/app_localizations_en.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/themed_app.dart';
import '../support/fake_sync_coordinator.dart';
import 'sync_fixtures.dart';

/// The words of each status in both languages (ADR-27 §3, no silent errors).
String _expected(AppLocalizations l10n, SyncStatus status) => switch (status) {
  SyncIdle() => l10n.syncStatusUpToDate,
  SyncSyncing() => l10n.syncStatusSending,
  SyncPending(:final count) => l10n.syncStatusPending(count),
  SyncUploading(:final remaining) =>
    (remaining ?? 0) > 0
        ? l10n.syncStatusUploadingLeft(remaining!)
        : l10n.syncStatusUploading,
  SyncError(error: Rejected()) => l10n.syncRejectedLine,
  SyncError(:final error, :final title) => remoteErrorText(
    l10n,
    error,
    title: title,
  ),
};

/// A too-old status whose store action is counted instead of launched.
class _StoreViewModel extends StubSyncStatusViewModel {
  _StoreViewModel({required this.opens})
    : super('g', const SyncLineShown(SyncError(VersionTooOld())));

  final bool opens;
  int opened = 0;

  @override
  Future<bool> openStore() async {
    opened++;
    return opens;
  }
}

Widget _versionLine(
  _StoreViewModel vm, {
  Locale locale = const Locale('de'),
}) => ProviderScope(
  overrides: [syncStatusViewModelProvider.overrideWith2((_) => vm)],
  child: themedApp(const SyncStatusLine(groupId: 'g'), locale: locale),
);

void main() {
  group('texts', () {
    for (final (name, status) in syncLineCases) {
      for (final (lang, l10n) in <(String, AppLocalizations)>[
        ('de', AppLocalizationsDe()),
        ('en', AppLocalizationsEn()),
      ]) {
        testWidgets('$name in $lang', (tester) async {
          await tester.pumpWidget(
            themedApp(syncLine(status), locale: Locale(lang)),
          );
          await tester.pumpAndSettle();
          expect(find.text(_expected(l10n, status)), findsOneWidget);
        });
      }
    }

    testWidgets('the German words, spelled out', (tester) async {
      Future<void> shows(SyncStatus s, String text) async {
        await tester.pumpWidget(
          KeyedSubtree(key: UniqueKey(), child: themedApp(syncLine(s))),
        );
        await tester.pumpAndSettle();
        expect(find.text(text), findsOneWidget);
      }

      await shows(const SyncIdle(), 'Aktuell');
      await shows(const SyncSyncing(), 'Wird gesendet …');
      await shows(const SyncPending(1), '1 Änderung wartet');
      await shows(const SyncPending(3), '3 Änderungen warten');
      await shows(
        const SyncError(Offline()),
        'Keine Verbindung. Deine Änderungen sind gespeichert und gehen raus, '
        'sobald du online bist.',
      );
    });

    testWidgets('a local-only group shows no line at all', (tester) async {
      await tester.pumpWidget(themedApp(syncLine(null)));
      await tester.pumpAndSettle();
      expect(find.byType(Icon), findsNothing);
      expect(find.byType(Text), findsNothing);
    });
  });

  group('one action per error', () {
    testWidgets('offline and not-member offer nothing to press', (
      tester,
    ) async {
      for (final error in const [Offline(), NotMember()]) {
        await tester.pumpWidget(
          KeyedSubtree(
            key: UniqueKey(),
            child: themedApp(syncLine(SyncError(error))),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(TextButton), findsNothing, reason: '$error');
      }
    });

    testWidgets('a too old app offers "Aktualisieren", which opens the store', (
      tester,
    ) async {
      final vm = _StoreViewModel(opens: true);
      await tester.pumpWidget(_versionLine(vm));
      await tester.pumpAndSettle();
      expect(
        find.text('Diese Version kann nicht mehr teilen. Aktualisiere mitlio.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Aktualisieren'));
      await tester.pumpAndSettle();
      expect(vm.opened, 1);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('"Update" in English', (tester) async {
      await tester.pumpWidget(
        _versionLine(_StoreViewModel(opens: true), locale: const Locale('en')),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('This version can no longer share. Update mitlio.'),
        findsOneWidget,
      );
      expect(find.text('Update'), findsOneWidget);
    });

    for (final (lang, text) in [
      (
        'de',
        'Der Store lässt sich nicht öffnen. Öffne ihn selbst und '
            'aktualisiere mitlio.',
      ),
      (
        'en',
        'Could not open the store. Open it yourself and update mitlio.',
      ),
    ]) {
      testWidgets('a store that cannot open says so in $lang', (tester) async {
        final vm = _StoreViewModel(opens: false);
        await tester.pumpWidget(_versionLine(vm, locale: Locale(lang)));
        await tester.pumpAndSettle();
        await tester.tap(
          find.text(lang == 'de' ? 'Aktualisieren' : 'Update'),
        );
        await tester.pumpAndSettle();
        expect(vm.opened, 1);
        expect(find.text(text), findsOneWidget);
      });
    }

    testWidgets('"Nochmal versuchen" syncs the group now', (tester) async {
      final coordinator = FakeSyncCoordinator();
      for (final error in const [
        ServerDown(),
        RateLimitedRemote(Duration(minutes: 2)),
      ]) {
        await tester.pumpWidget(
          KeyedSubtree(
            key: UniqueKey(),
            child: themedApp(
              syncLine(SyncError(error), coordinator: coordinator),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Nochmal versuchen'));
        await tester.pumpAndSettle();
      }
      expect(coordinator.synced, ['g!', 'g!']);
    });

    testWidgets('a refused change opens a sheet; OK clears it', (
      tester,
    ) async {
      final coordinator = FakeSyncCoordinator();
      const status = SyncError(
        Rejected('payers_sum_mismatch'),
        title: 'Pizza',
      );
      await tester.pumpWidget(
        themedApp(syncLine(status, coordinator: coordinator)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Eine Änderung konnte nicht geteilt werden.'), findsOne);

      await tester.tap(find.text('Ansehen'));
      await tester.pumpAndSettle();
      expect(find.text('Nicht geteilt'), findsOneWidget);
      expect(
        find.text(
          '„Pizza“ konnte nicht geteilt werden. Sie ist nur auf diesem Handy.',
        ),
        findsOneWidget,
      );
      expect(coordinator.acknowledged, isEmpty);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(coordinator.acknowledged, ['g']);
      expect(find.text('Nicht geteilt'), findsNothing);
    });

    testWidgets('dismissing the sheet keeps the refusal', (tester) async {
      final coordinator = FakeSyncCoordinator();
      await tester.pumpWidget(
        themedApp(
          syncLine(
            const SyncError(Rejected('x'), title: 'Pizza'),
            coordinator: coordinator,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ansehen'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.text('Nicht geteilt'), findsNothing);
      expect(coordinator.acknowledged, isEmpty);
    });
  });

  testWidgets('follows the coordinator live, through the real ViewModel', (
    tester,
  ) async {
    final coordinator = FakeSyncCoordinator();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [syncCoordinatorProvider.overrideWithValue(coordinator)],
        child: themedApp(const SyncStatusLine(groupId: 'g')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Text), findsNothing);

    coordinator.show(const SyncPending(2));
    await tester.pumpAndSettle();
    expect(find.text('2 Änderungen warten'), findsOneWidget);

    coordinator.show(const SyncIdle());
    await tester.pumpAndSettle();
    expect(find.text('Aktuell'), findsOneWidget);

    coordinator.show(null);
    await tester.pumpAndSettle();
    expect(find.byType(Text), findsNothing);
  });

  group('accessibility', () {
    for (final (name, status) in syncLineCases) {
      forEachMode(
        name,
        () => syncLine(status),
        (tester, _, _) => expectAccessible(tester),
      );
    }
  });

  test('syncStatusJson names the case', () {
    expect(syncStatusJson(const SyncIdle()), {'status': 'idle'});
    expect(syncStatusJson(const SyncSyncing()), {'status': 'syncing'});
    expect(syncStatusJson(const SyncPending(2)), {
      'status': 'pending',
      'pending': 2,
    });
    expect(syncStatusJson(const SyncError(Rejected('x'), title: 'Pizza')), {
      'status': 'error',
      'error': 'rejected:x',
      'title': 'Pizza',
    });
  });
}
