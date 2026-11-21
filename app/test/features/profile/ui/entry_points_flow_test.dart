import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/profile/data/repositories/personal_car_links_repository.dart';
import 'package:mitlio/features/profile/data/repositories/profile_providers.dart';
import 'package:mitlio/features/profile/ui/car_edit_view.dart';
import 'package:mitlio/features/profile/ui/profile_setup_view.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../../../helpers/fake_app.dart';
import '../../../helpers/pump_app.dart';
import '../../balances/balances_support.dart';
import '../../repo_test_support.dart';

/// The just-in-time cards, the settings rows and the group integration of
/// the personal profile and cars (PU-T10, PU-T11) on the real app, router and
/// in-memory repositories (German, the default locale).
void main() {
  late FakeApp app;

  setUp(() {
    app = FakeApp();
  });

  void phone(WidgetTester tester) {
    tester.view
      ..physicalSize = const Size(400, 1000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Future<Scenario> trip() async {
    final s = await Scenario.create(app, ['Anna', 'Ben']);
    await s.expense({'Anna': 3000}, {'Anna': 1500, 'Ben': 1500});
    return s;
  }

  const settleCard = 'Zahlungsdaten einmal einrichten';
  const profileCard = 'Dein Profil einmal einrichten';
  const dismiss = 'Nicht mehr anzeigen';

  group('settle screen card', () {
    testWidgets('shown once, gone for good after dismiss', (tester) async {
      phone(tester);
      final s = await trip();
      await pumpMitlio(tester, app, location: '/groups/${s.group.id}/settle');
      expect(find.text(settleCard), findsOneWidget);
      await tester.tap(find.byTooltip(dismiss));
      await tester.pumpAndSettle();
      expect(find.text(settleCard), findsNothing);

      await pumpMitlio(tester, app, location: '/groups/${s.group.id}/settle');
      expect(find.text(settleCard), findsNothing);
    });

    testWidgets('opens the profile flow, gone once it has payment data', (
      tester,
    ) async {
      phone(tester);
      final s = await trip();
      await pumpMitlio(tester, app, location: '/groups/${s.group.id}/settle');
      await tester.tap(find.text('Einrichten'));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileSetupView), findsOneWidget);

      ok(await app.profile.save(displayName: 'Anna', paypalMe: 'anna'));
      Navigator.of(tester.element(find.byType(ProfileSetupView))).pop();
      await tester.pumpAndSettle();
      expect(find.text(settleCard), findsNothing);
    });

    testWidgets('not shown when the profile has payment data', (tester) async {
      phone(tester);
      final s = await trip();
      ok(await app.profile.save(displayName: 'Anna', paypalMe: 'anna'));
      await pumpMitlio(tester, app, location: '/groups/${s.group.id}/settle');
      expect(find.text(settleCard), findsNothing);
    });

    testWidgets('a failing dismiss says so and keeps the card', (
      tester,
    ) async {
      phone(tester);
      final s = await trip();
      await pumpMitlio(tester, app, location: '/groups/${s.group.id}/settle');
      app.setupState.failSaveWith = const Storage('disk full');
      await tester.tap(find.byTooltip(dismiss));
      await tester.pumpAndSettle();
      expect(find.text(settleCard), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });

  group('settings rows', () {
    testWidgets('"Mein Profil" says how complete the profile is, only there', (
      tester,
    ) async {
      phone(tester);
      await pumpMitlio(tester, app, location: '/settings');
      expect(find.textContaining('nur auf deinem Gerät'), findsOneWidget);

      ok(await app.profile.save(displayName: 'Mia'));
      await pumpMitlio(tester, app, location: '/settings');
      expect(find.text('Noch keine Zahlungsdaten'), findsOneWidget);

      ok(await app.profile.save(displayName: 'Mia', paypalMe: 'mia'));
      await pumpMitlio(tester, app, location: '/settings');
      expect(find.text('PayPal.Me gespeichert'), findsOneWidget);
    });

    testWidgets('a row of "Meine Autos" opens the car in one step', (
      tester,
    ) async {
      phone(tester);
      ok(
        await app.userVehicles.add(
          name: 'Golf',
          fuelType: FuelType.petrol,
          consumptionMilliPer100km: 6500,
        ),
      );
      await pumpMitlio(tester, app, location: '/settings/cars');
      await tester.tap(find.text('Golf'));
      await tester.pumpAndSettle();
      expect(find.byType(CarEditView), findsOneWidget);
      expect(
        find.widgetWithText(TextField, 'Name'),
        findsOneWidget,
      );
    });
  });

  group('editing a personal car', () {
    testWidgets('updates the groups, undo brings the old values back', (
      tester,
    ) async {
      phone(tester);
      final golf = ok(
        await app.userVehicles.add(
          name: 'Golf',
          fuelType: FuelType.petrol,
          consumptionMilliPer100km: 6500,
        ),
      );
      final a = await Scenario.create(app, ['Anna']);
      final b = await Scenario.create(app, ['Ben']);
      final c = await pumpMitlio(tester, app, location: '/settings/cars');
      final links = _links(c);
      final copyA = ok(await links.useInGroup(a.group.id, golf.id));
      ok(await links.useInGroup(b.group.id, golf.id));

      await tester.tap(find.text('Golf'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Name'),
        'Golf GTI',
      );
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();

      expect(find.text('In 2 Gruppen aktualisiert'), findsOneWidget);
      expect(ok(await app.vehicles.get(copyA.id)).name, 'Golf GTI');
      expect(ok(await app.userVehicles.get(golf.id)).name, 'Golf GTI');

      await tester.tap(find.text('Rückgängig'));
      await tester.pumpAndSettle();
      expect(ok(await app.vehicles.get(copyA.id)).name, 'Golf');
      expect(ok(await app.userVehicles.get(golf.id)).name, 'Golf');
    });

    testWidgets('a missing name stays on the form and says what is missing', (
      tester,
    ) async {
      phone(tester);
      final golf = ok(
        await app.userVehicles.add(
          name: 'Golf',
          fuelType: FuelType.petrol,
          consumptionMilliPer100km: 6500,
        ),
      );
      await pumpMitlio(tester, app, location: '/settings/cars/${golf.id}');
      await tester.enterText(find.widgetWithText(TextField, 'Name'), ' ');
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();
      expect(find.byType(CarEditView), findsOneWidget);
      expect(ok(await app.userVehicles.get(golf.id)).name, 'Golf');
    });
  });

  group('creating a group', () {
    testWidgets('prefills "Ich" from the profile', (tester) async {
      phone(tester);
      ok(await app.profile.save(displayName: 'Mia', paypalMe: 'mia'));
      await pumpMitlio(tester, app, location: '/groups/new');
      expect(find.text(profileCard), findsNothing);
      await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Ski');
      await tester.tap(find.text('Gruppe anlegen'));
      await tester.pumpAndSettle();
      final groups = (await tester.runAsync(
        () => app.groups.watchGroups().first,
      ))!;
      final members = ok(
        (await tester.runAsync(() => app.members.list(groups.single.id)))!,
      );
      expect([for (final m in members) m.name], ['Mia']);
      expect(members.single.paypalMe, 'mia');
    });

    testWidgets('a second group without profile offers the profile once', (
      tester,
    ) async {
      phone(tester);
      await Scenario.create(app, ['Anna']);
      await pumpMitlio(tester, app, location: '/groups/new');
      await tester.runAsync(pumpEventQueue);
      await tester.pumpAndSettle();
      expect(find.text(profileCard), findsOneWidget);
      await tester.tap(find.byTooltip(dismiss));
      await tester.pumpAndSettle();
      expect(find.text(profileCard), findsNothing);
    });

    testWidgets('the first group does not nag', (tester) async {
      phone(tester);
      await pumpMitlio(tester, app, location: '/groups/new');
      expect(find.text(profileCard), findsNothing);
    });
  });
}

PersonalCarLinksRepository _links(ProviderContainer c) =>
    c.read(personalCarLinksRepositoryProvider);
