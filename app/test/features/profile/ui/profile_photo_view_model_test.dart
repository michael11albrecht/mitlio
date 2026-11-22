import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/profile/data/repositories/fake_profile_photo_repository.dart';
import 'package:mitlio/features/profile/data/repositories/profile_photo_repository.dart';
import 'package:mitlio/features/profile/data/repositories/profile_providers.dart';
import 'package:mitlio/features/profile/ui/profile_photo_view_model.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// A photo repository that can be made to fail.
class FlakyPhotos extends FakeProfilePhotoRepository {
  RepositoryError? failGetWith;
  RepositoryError? failSaveWith;
  RepositoryError? failRemoveWith;

  @override
  Future<RepoResult<Uint8List?>> get() async =>
      failGetWith == null ? super.get() : Err(failGetWith!);

  @override
  Future<RepoResult<void>> save(Uint8List png) async =>
      failSaveWith == null ? super.save(png) : Err(failSaveWith!);

  @override
  Future<RepoResult<void>> remove() async =>
      failRemoveWith == null ? super.remove() : Err(failRemoveWith!);
}

void main() {
  final raw = Uint8List.fromList([1, 2, 3]);
  final png = Uint8List.fromList([4, 5, 6]);
  late FlakyPhotos photos;
  late FakePhotoSource source;
  late FakePhotoProcessor processor;

  ProviderContainer make({bool withSource = true}) {
    final c = ProviderContainer(
      overrides: [
        profilePhotoRepositoryProvider.overrideWithValue(photos),
        profilePhotoProcessorProvider.overrideWithValue(processor),
        if (withSource) photoSourceProvider.overrideWithValue(source),
      ],
    );
    addTearDown(c.dispose);
    c.listen(profilePhotoViewModelProvider, (_, _) {});
    return c;
  }

  ProfilePhotoViewModel vm(ProviderContainer c) =>
      c.read(profilePhotoViewModelProvider.notifier);
  ProfilePhotoState state(ProviderContainer c) =>
      c.read(profilePhotoViewModelProvider);

  setUp(() {
    photos = FlakyPhotos();
    source = FakePhotoSource();
    processor = FakePhotoProcessor(png);
  });

  test('starts without a photo and says whether a picker exists', () async {
    final c = make();
    await vm(c).load();
    expect(state(c).photo, isNull);
    expect(state(c).canPick, isTrue);
    expect(state(make(withSource: false)).canPick, isFalse);
  });

  test('loads a saved photo', () async {
    await photos.save(png);
    final c = make();
    await vm(c).load();
    expect(state(c).photo, png);
  });

  test('a photo that cannot be read is an error in the state', () async {
    photos.failGetWith = const Storage('disk');
    final c = make();
    await vm(c).load();
    expect(state(c).loadError, const Storage('disk'));
    expect(state(c).photo, isNull);
  });

  group('pick', () {
    test('saves the processed picture from camera or gallery', () async {
      source.answer = PhotoPicked(raw);
      final c = make();
      for (final origin in PhotoOrigin.values) {
        final result = await vm(c).pick(origin);
        expect(
          result,
          const Ok<PhotoOutcome, RepositoryError>(PhotoOutcome.saved),
        );
      }
      expect(source.asked, PhotoOrigin.values);
      expect(state(c).photo, png);
      expect(((await photos.get()) as Ok).value, png);
    });

    test('cancelling changes nothing', () async {
      await photos.save(png);
      final c = make();
      await vm(c).load();
      source.answer = const PhotoPickCancelled();
      expect(
        await vm(c).pick(PhotoOrigin.gallery),
        const Ok<PhotoOutcome, RepositoryError>(PhotoOutcome.cancelled),
      );
      expect(state(c).photo, png);
    });

    test('a denied permission is reported as denied', () async {
      source.answer = const PhotoPickDenied();
      expect(
        await vm(make()).pick(PhotoOrigin.camera),
        const Ok<PhotoOutcome, RepositoryError>(PhotoOutcome.denied),
      );
    });

    test('a failing camera is reported as unusable', () async {
      source.answer = const PhotoPickFailed();
      expect(
        await vm(make()).pick(PhotoOrigin.camera),
        const Ok<PhotoOutcome, RepositoryError>(PhotoOutcome.unusable),
      );
    });

    test(
      'a picture that cannot be processed is unusable, nothing saved',
      () async {
        source.answer = PhotoPicked(raw);
        processor.result = null;
        final c = make();
        expect(
          await vm(c).pick(PhotoOrigin.gallery),
          const Ok<PhotoOutcome, RepositoryError>(PhotoOutcome.unusable),
        );
        expect(state(c).photo, isNull);
        expect(((await photos.get()) as Ok).value, isNull);
      },
    );

    test('a failing save is returned and the old photo stays', () async {
      await photos.save(raw);
      final c = make();
      await vm(c).load();
      source.answer = PhotoPicked(raw);
      photos.failSaveWith = const Storage('full');
      expect(
        await vm(c).pick(PhotoOrigin.gallery),
        const Err<PhotoOutcome, RepositoryError>(Storage('full')),
      );
      expect(state(c).photo, raw);
    });

    test('without a picker it is NotFound, not silent', () async {
      expect(
        await vm(make(withSource: false)).pick(PhotoOrigin.camera),
        const Err<PhotoOutcome, RepositoryError>(
          NotFound('photo_source', 'device'),
        ),
      );
    });
  });

  group('remove', () {
    test('deletes the photo', () async {
      final c = make();
      await vm(c).setFromBytes(raw);
      expect(await vm(c).remove(), isA<Ok<void, RepositoryError>>());
      expect(state(c).photo, isNull);
      expect(((await photos.get()) as Ok).value, isNull);
    });

    test('a failure is returned and the photo stays', () async {
      final c = make();
      await vm(c).setFromBytes(raw);
      photos.failRemoveWith = const Storage('locked');
      expect(
        await vm(c).remove(),
        const Err<void, RepositoryError>(Storage('locked')),
      );
      expect(state(c).photo, png);
    });
  });
}
