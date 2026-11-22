import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mitlio/features/profile/data/repositories/profile_photo_repository.dart';
import 'package:mitlio/features/profile/ui/profile_card.dart';
import 'package:mitlio/l10n/app_localizations_de.dart';

import '../../../helpers/a11y.dart';
import '../../../helpers/themed_app.dart';
import '../../../support/tap_counter.dart';
import 'profile_photo_rig.dart';

final _de = AppLocalizationsDe();

/// The profile photo on the avatar step (PU-T13): widget behaviour, tap
/// budget and accessibility.
void main() {
  Future<void> open(
    WidgetTester tester,
    PhotoFlowRig rig, {
    bool withPhoto = false,
    Brightness brightness = Brightness.light,
    double scale = 1,
  }) async {
    final view = await tester.runAsync(() => rig.view(withPhoto: withPhoto));
    await tester.pumpWidget(
      themedApp(view!, brightness: brightness, textScale: scale),
    );
    await tester.pumpAndSettle();
  }

  Finder avatarImage() => find.descendant(
    of: find.byType(ProfileAvatar),
    matching: find.byType(Image),
  );

  testWidgets('offers camera and gallery and no remove without a photo', (
    tester,
  ) async {
    await open(tester, PhotoFlowRig());
    expect(find.text(_de.profilePhotoCamera), findsOneWidget);
    expect(find.text(_de.profilePhotoGallery), findsOneWidget);
    expect(find.text(_de.profilePhotoLocalOnly), findsOneWidget);
    expect(find.text(_de.profilePhotoRemove), findsNothing);
    expect(avatarImage(), findsNothing);
  });

  testWidgets('offers nothing while no camera or gallery is wired', (
    tester,
  ) async {
    await open(tester, PhotoFlowRig(withPicker: false));
    expect(find.text(_de.profilePhotoCamera), findsNothing);
    expect(find.text(_de.profilePhotoLocalOnly), findsNothing);
  });

  testWidgets('one tap on the gallery shows the photo as avatar', (
    tester,
  ) async {
    final rig = PhotoFlowRig();
    rig.source.answer = PhotoPicked(rig.raw);
    await open(tester, rig);
    final taps = TapCounter(tester);
    await taps.tap(find.text(_de.profilePhotoGallery));
    await tester.pumpAndSettle();
    expect(rig.source.asked, [PhotoOrigin.gallery]);
    expect(avatarImage(), findsOneWidget);
    expect(find.text(_de.profilePhotoRemove), findsOneWidget);
    taps.expectWithinBudget('profile_photo');
  });

  testWidgets('remove goes back to the initials avatar', (tester) async {
    await open(tester, PhotoFlowRig(), withPhoto: true);
    expect(avatarImage(), findsOneWidget);
    await tester.tap(find.text(_de.profilePhotoRemove));
    await tester.pumpAndSettle();
    expect(avatarImage(), findsNothing);
    expect(find.text(_de.profilePhotoRemove), findsNothing);
  });

  testWidgets('a photo is still shown when no picker is wired', (tester) async {
    await open(tester, PhotoFlowRig(withPicker: false), withPhoto: true);
    expect(avatarImage(), findsOneWidget);
    expect(find.text(_de.profilePhotoRemove), findsOneWidget);
    expect(find.text(_de.profilePhotoCamera), findsNothing);
  });

  group('plain errors, nothing silent', () {
    testWidgets('denied permission says what to do', (tester) async {
      final rig = PhotoFlowRig();
      rig.source.answer = const PhotoPickDenied();
      await open(tester, rig);
      await tester.tap(find.text(_de.profilePhotoCamera));
      await tester.pumpAndSettle();
      expect(find.text(_de.profilePhotoDenied), findsOneWidget);
      expect(avatarImage(), findsNothing);
    });

    testWidgets('an unusable picture says to pick another', (tester) async {
      final rig = PhotoFlowRig();
      rig.source.answer = PhotoPicked(rig.raw);
      rig.processor.result = null;
      await open(tester, rig);
      await tester.tap(find.text(_de.profilePhotoGallery));
      await tester.pumpAndSettle();
      expect(find.text(_de.profilePhotoUnusable), findsOneWidget);
    });

    testWidgets('cancelling shows no message', (tester) async {
      await open(tester, PhotoFlowRig());
      await tester.tap(find.text(_de.profilePhotoGallery));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('a failing save is shown', (tester) async {
      final rig = PhotoFlowRig()..source.answer = PhotoPicked(Uint8List(3));
      rig.processor.result = Uint8List(profilePhotoMaxBytes + 1);
      await open(tester, rig);
      await tester.tap(find.text(_de.profilePhotoGallery));
      await tester.pumpAndSettle();
      expect(find.text(_de.errorInvalidData), findsOneWidget);
    });
  });

  for (final brightness in Brightness.values) {
    for (final scale in const [1.0, 2.0]) {
      testWidgets('the avatar step with a photo is accessible '
          '(${brightness.name}, x$scale)', (tester) async {
        final semantics = tester.ensureSemantics();
        await open(
          tester,
          PhotoFlowRig(),
          withPhoto: true,
          brightness: brightness,
          scale: scale,
        );
        await expectAccessible(tester);
        semantics.dispose();
      });
    }
  }
}
