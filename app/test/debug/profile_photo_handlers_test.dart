import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/debug/debug_data_control.dart';
import 'package:mitlio/debug/drive_types.dart';
import 'package:mitlio/debug/handlers/profile_photo.dart';
import 'package:mitlio/features/profile/data/repositories/fake_profile_photo_repository.dart';
import 'package:mitlio/features/profile/data/repositories/profile_photo_repository.dart';
import 'package:mitlio/features/profile/data/repositories/profile_providers.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

import '../features/profile/ui/profile_photo_rig.dart';
import '../features/repo_test_support.dart';

/// The profile photo through `ext.mitlio.profile.photo.*` (PU-T13): the
/// commands the avatar step uses.
void main() {
  late FakeProfilePhotoRepository photos;
  late FakePhotoSource source;
  late FakePhotoProcessor processor;
  late ProviderContainer c;
  late Map<String, DriveHandler> h;

  ProviderContainer make({bool withSource = true}) {
    final container = ProviderContainer(
      overrides: [
        profilePhotoRepositoryProvider.overrideWithValue(photos),
        profilePhotoProcessorProvider.overrideWithValue(processor),
        if (withSource) photoSourceProvider.overrideWithValue(source),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() {
    photos = FakeProfilePhotoRepository();
    source = FakePhotoSource();
    processor = FakePhotoProcessor(samplePhotoPng);
    c = make();
    h = profilePhotoDriveHandlers(c);
  });

  String raw() => base64Encode([1, 2, 3]);

  test('photo.state starts without a photo and reports only sizes', () async {
    expect(await h['profile.photo.state']!({}), {
      'hasPhoto': false,
      'bytes': 0,
      'canPick': true,
    });
  });

  test('photo.set processes and saves the picture', () async {
    expect(await h['profile.photo.set']!({'data': raw()}), {
      'outcome': 'saved',
    });
    final state = await h['profile.photo.state']!({});
    expect(state['hasPhoto'], isTrue);
    expect(state['bytes'], samplePhotoPng.length);
  });

  test('photo.set rejects missing and malformed data', () async {
    expect(
      await h['profile.photo.set']!({}),
      containsPair('error', 'invalid_params'),
    );
    expect(
      await h['profile.photo.set']!({'data': '***'}),
      containsPair('error', 'invalid_params'),
    );
  });

  test('photo.set says unusable for a picture that cannot be used', () async {
    processor.result = null;
    expect(await h['profile.photo.set']!({'data': raw()}), {
      'outcome': 'unusable',
    });
    expect((await h['profile.photo.state']!({}))['hasPhoto'], isFalse);
  });

  test('photo.pick asks the camera or the gallery', () async {
    source.answer = PhotoPicked(Uint8List.fromList([1]));
    expect(await h['profile.photo.pick']!({'source': 'camera'}), {
      'outcome': 'saved',
    });
    expect(source.asked, [PhotoOrigin.camera]);
    source.answer = const PhotoPickDenied();
    expect(await h['profile.photo.pick']!({'source': 'gallery'}), {
      'outcome': 'denied',
    });
  });

  test('photo.pick needs a known source and a registered picker', () async {
    expect(
      await h['profile.photo.pick']!({'source': 'x'}),
      containsPair('error', 'invalid_params'),
    );
    final bare = profilePhotoDriveHandlers(make(withSource: false));
    expect(
      await bare['profile.photo.pick']!({'source': 'camera'}),
      containsPair('error', 'not_found'),
    );
  });

  test('photo.remove deletes the photo', () async {
    await h['profile.photo.set']!({'data': raw()});
    expect(await h['profile.photo.remove']!({}), {'removed': true});
    expect((await h['profile.photo.state']!({}))['hasPhoto'], isFalse);
  });

  test('reset (wipe) removes the photo too', () async {
    final r = await driftRepos();
    final control = DriftDebugDataControl(
      db: r.db!,
      groups: r.groups,
      members: r.members,
      photos: photos,
    );
    await photos.save(samplePhotoPng);
    await control.wipe();
    expect(
      ((await photos.get()) as Ok<Uint8List?, RepositoryError>).value,
      isNull,
    );
  });
}
