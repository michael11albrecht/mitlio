import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/profile/data/repositories/profile_photo_repository.dart';
import 'package:mitlio/features/profile/data/repositories/profile_providers.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// How asking for a photo ended, when it did not fail in storage.
enum PhotoOutcome {
  saved,

  /// The user closed the camera or gallery.
  cancelled,

  /// The camera or photo permission is off: say where to turn it on.
  denied,

  /// The picture is not usable (not an image, too big even when shrunk, or
  /// the camera or gallery failed): say to pick another one.
  unusable,
}

/// [photo] is the processed PNG shown as avatar. [canPick] is false while no
/// camera/gallery is registered: a photo is then not offered, but one that
/// exists is still shown. [loadError] is set when the saved photo could not
/// be read.
final class ProfilePhotoState {
  const ProfilePhotoState({
    this.photo,
    this.canPick = false,
    this.loadError,
  });

  final Uint8List? photo;
  final bool canPick;
  final RepositoryError? loadError;
}

/// The profile photo (PU-T13, ADR-25): from the camera or the gallery, cropped
/// square, at most 100 kB, kept on this device only.
class ProfilePhotoViewModel extends Notifier<ProfilePhotoState> {
  @override
  ProfilePhotoState build() {
    unawaited(load());
    return ProfilePhotoState(canPick: ref.watch(photoSourceProvider) != null);
  }

  /// Reads the saved photo; also the retry after a failure.
  Future<void> load() async {
    final result = await ref.read(profilePhotoRepositoryProvider).get();
    if (!ref.mounted) return;
    state = switch (result) {
      Ok(:final value) => ProfilePhotoState(
        photo: value,
        canPick: state.canPick,
      ),
      Err(:final error) => ProfilePhotoState(
        photo: state.photo,
        canPick: state.canPick,
        loadError: error,
      ),
    };
  }

  /// "Foto aufnehmen": [pick] from the camera.
  Future<RepoResult<PhotoOutcome>> takePhoto() => pick(PhotoOrigin.camera);

  /// "Aus der Galerie": [pick] from the gallery.
  Future<RepoResult<PhotoOutcome>> chooseFromGallery() =>
      pick(PhotoOrigin.gallery);

  /// Asks the camera or gallery for a picture and saves it as the photo.
  Future<RepoResult<PhotoOutcome>> pick(PhotoOrigin origin) async {
    final source = ref.read(photoSourceProvider);
    if (source == null) return const Err(NotFound('photo_source', 'device'));
    return switch (await source.pick(origin)) {
      PhotoPicked(:final bytes) => setFromBytes(bytes),
      PhotoPickCancelled() => const Ok(PhotoOutcome.cancelled),
      PhotoPickDenied() => const Ok(PhotoOutcome.denied),
      PhotoPickFailed() => const Ok(PhotoOutcome.unusable),
    };
  }

  /// Crops, compresses and saves [raw] as the photo.
  Future<RepoResult<PhotoOutcome>> setFromBytes(Uint8List raw) async {
    final png = await ref.read(profilePhotoProcessorProvider).process(raw);
    if (png == null) return const Ok(PhotoOutcome.unusable);
    final saved = await ref.read(profilePhotoRepositoryProvider).save(png);
    if (saved case Err(:final error)) return Err(error);
    if (ref.mounted) {
      state = ProfilePhotoState(photo: png, canPick: state.canPick);
    }
    return const Ok(PhotoOutcome.saved);
  }

  /// Deletes the photo: the avatar goes back to colour and initials/emoji.
  Future<RepoResult<void>> remove() async {
    final removed = await ref.read(profilePhotoRepositoryProvider).remove();
    if (removed case Err(:final error)) return Err(error);
    if (ref.mounted) state = ProfilePhotoState(canPick: state.canPick);
    return const Ok(null);
  }
}

final profilePhotoViewModelProvider =
    NotifierProvider<ProfilePhotoViewModel, ProfilePhotoState>(
      ProfilePhotoViewModel.new,
    );
