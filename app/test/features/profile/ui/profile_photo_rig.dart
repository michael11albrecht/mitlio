import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:mitlio/features/profile/data/repositories/fake_profile_photo_repository.dart';
import 'package:mitlio/features/profile/data/repositories/profile_providers.dart';
import 'package:mitlio/features/profile/ui/profile_setup_view.dart';
import 'package:mitlio/features/profile/ui/profile_setup_view_model.dart';
import 'package:mitlio/features/setup/data/setup_state_repository.dart';

import 'profile_flow_rig.dart';

/// A 16x16 single-colour PNG standing in for the processed profile photo.
/// Solid on purpose: any gradient or edge would be interpolated differently
/// by the GPU/scaler per platform and break the platform-independent golden.
final Uint8List samplePhotoPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAIAAACQkWg2AAAAFklEQVR42mOwr99PEmIY1T'
  'CqYfhqAAANOX0QszVpOgAAAABJRU5ErkJggg==',
);

/// The profile flow resumed at the avatar step, with a profile, a camera and
/// gallery fake and (if `withPhoto`) a saved photo.
class PhotoFlowRig {
  PhotoFlowRig({this.withPicker = true});

  final bool withPicker;
  final flow = ProfileFlowRig();
  final photos = FakeProfilePhotoRepository();
  final source = FakePhotoSource();
  final processor = FakePhotoProcessor(samplePhotoPng);

  Future<ProviderScope> view({bool withPhoto = false}) async {
    flow.setup.stored[profileFlowId] = const SetupProgress(
      stepIndex: 1,
      answers: {profileStepName: 'Anna Beispiel'},
    ).toJson();
    await flow.profile.save(displayName: 'Anna Beispiel');
    if (withPhoto) await photos.save(samplePhotoPng);
    return ProviderScope(
      overrides: overrides,
      child: const ProfileSetupView(),
    );
  }

  List<Override> get overrides => [
    ...flow.overrides,
    profilePhotoRepositoryProvider.overrideWithValue(photos),
    profilePhotoProcessorProvider.overrideWithValue(processor),
    if (withPicker) photoSourceProvider.overrideWithValue(source),
  ];

  Uint8List get raw => Uint8List.fromList([1, 2, 3]);
}
