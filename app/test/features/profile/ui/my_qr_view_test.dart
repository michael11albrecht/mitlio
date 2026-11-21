import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/profile/data/repositories/qr_share_repository.dart';
import 'package:mitlio/features/profile/data/services/qr_png_renderer.dart';
import 'package:mitlio_domain/mitlio_domain.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../helpers/fake_app.dart';
import '../../../helpers/pump_app.dart';
import '../../repo_test_support.dart';
import 'profile_flow_rig.dart';

const _iban = 'DE89370400440532013000';

class _FakeQrShare implements QrShareRepository {
  final shared = <String>[];
  RepositoryError? failWith;

  @override
  Future<RepoResult<void>> sharePng(String payload) async {
    if (failWith != null) return Err(failWith!);
    shared.add(payload);
    return const Ok(null);
  }
}

/// "Mein QR-Code teilen" (PU-T16) on the real app, router and in-memory
/// repositories (German).
void main() {
  late FakeApp app;
  late _FakeQrShare share;

  setUp(() {
    app = FakeApp();
    share = _FakeQrShare();
  });

  Future<void> open(WidgetTester tester) => pumpMitlio(
    tester,
    app,
    location: '/settings/my-qr',
    extra: [qrShareRepositoryProvider.overrideWithValue(share)],
  );

  Future<void> saveIban() async {
    ok(await app.profile.save(displayName: 'Mia'));
    ok(await app.profileBank.save(iban: _iban, accountName: 'Mia Muster'));
  }

  testWidgets('shows the code, the holder and a warning, and shares it', (
    tester,
  ) async {
    await saveIban();
    await open(tester);
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('Mia Muster'), findsOneWidget);
    expect(find.textContaining('nur mit Leuten'), findsOneWidget);

    await tester.tap(find.text('Teilen'));
    await tester.pumpAndSettle();
    expect(share.shared, hasLength(1));
    expect(share.shared.single.split('\n')[7], isEmpty);
  });

  testWidgets('a failing share sheet says so with what to do', (tester) async {
    await saveIban();
    share.failWith = const Storage('share');
    await open(tester);
    await tester.tap(find.text('Teilen'));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsOneWidget);
    expect(share.shared, isEmpty);
  });

  testWidgets('without an IBAN it explains where to add one', (tester) async {
    ok(await app.profile.save(displayName: 'Mia'));
    await open(tester);
    expect(find.byType(QrImageView), findsNothing);
    expect(find.text('Noch keine IBAN'), findsOneWidget);
    expect(find.textContaining('Mein Profil'), findsOneWidget);
  });

  testWidgets('a failing read offers a retry, not a blank screen', (
    tester,
  ) async {
    ok(await app.profile.save(displayName: 'Mia'));
    final bank = FlakyBank(profile: app.profile)
      ..failGetWith = const Storage('disk');
    app.profileBank = bank;
    await open(tester);
    expect(find.byType(QrImageView), findsNothing);
    expect(find.text('Nochmal versuchen'), findsOneWidget);
  });

  group('settings entry', () {
    testWidgets('only offered once an IBAN is saved', (tester) async {
      ok(await app.profile.save(displayName: 'Mia', paypalMe: 'mia'));
      await pumpMitlio(tester, app, location: '/settings');
      expect(find.text('Mein QR-Code teilen'), findsNothing);
    });

    testWidgets('opens the QR screen', (tester) async {
      await saveIban();
      await pumpMitlio(
        tester,
        app,
        location: '/settings',
        extra: [qrShareRepositoryProvider.overrideWithValue(share)],
      );
      await tester.tap(find.text('Mein QR-Code teilen'));
      await tester.pumpAndSettle();
      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.byIcon(Icons.ios_share), findsOneWidget);
    });
  });

  testWidgets('the PNG is a real image with the PNG signature', (
    tester,
  ) async {
    final png = await tester.runAsync(
      () => const PaintedQrPngRenderer().render('BCD\n002'),
    );
    expect(png!.sublist(0, 8), [137, 80, 78, 71, 13, 10, 26, 10]);
    expect(png.length, greaterThan(500));
  });
}
