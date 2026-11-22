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

/// A 16x16 colour gradient PNG standing in for the processed profile photo.
final Uint8List samplePhotoPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAB6UlEQVR4nBXMoW3gMAAAQC9g8NTwUXiVBawfwORhaIEXqBeIVGxWFvySF3AXCOgKXaEr+C8D3IUQ1voVftbv8L1ewtf6Ez7X3/BvvYaP9Rbe13t4Wx/hdf0Lf9dn+LO+wsv6Dr/XT/i1FhxCFERBFERBFERBFERBFERBFERBFERBFMQnSIIkSIIkSIIkSIIkSIIkSIIkSIIkSIL0BJtgE2yCTbAJNsEm2ASbYBNsgk2wCTbBJtieYBfsgl2wC3bBLtgFu2AX7IJdsAt2wS7YBfsTZEEWZEEWZEEWZEEWZEEWZEEWZEEWZEF+giIogiIogiIogiIogiIogiIogiIogiIoT3AIDsEhOASH4BAcgkNwCA7BITgEh+AQHILjCaqgCqqgCqqgCqqgCqqgCqqgCqqgCqqgPkETNEETNEETNEETNEETNEETNEETNEETtCc4BafgFJyCU3AKTsEpOAWn4BScglNwCk7B+QRd0AVd0AVd0AVd0AVd0AVd0AVd0AVd0J/gElyCS3AJLsEluASX4BJcgktwCS7BJbgE1xMMwRAMwRAMwRAMwRAMwRAMwRAMwRAMwXiCKZiCKZiCKZiCKZiCKZiCKZiCKZiCKZhPcAtuwS24BbfgFtyCW3ALbsEtuAW34Bbcgjus//tjYc+BHUBDAAAAAElFTkSuQmCC',
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
