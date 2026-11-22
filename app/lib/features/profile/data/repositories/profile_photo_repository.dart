import 'dart:io';
import 'dart:typed_data';

import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// Where a profile photo comes from.
enum PhotoOrigin { camera, gallery }

/// What asking for a photo returned (PU-T13).
sealed class PhotoPick {
  const PhotoPick();
}

/// The raw picture the user chose, in any format the platform decodes.
final class PhotoPicked extends PhotoPick {
  const PhotoPicked(this.bytes);

  final Uint8List bytes;
}

/// The user closed the camera or gallery without choosing.
final class PhotoPickCancelled extends PhotoPick {
  const PhotoPickCancelled();
}

/// The camera or photo permission is off.
final class PhotoPickDenied extends PhotoPick {
  const PhotoPickDenied();
}

/// The camera or gallery failed for another reason.
final class PhotoPickFailed extends PhotoPick {
  const PhotoPickFailed();
}

/// The camera and the gallery. The platform implementation arrives with the
/// `image_picker` dependency; until then no source is registered and the
/// profile flow does not offer a photo. Faked in tests.
// ignore: one_member_abstracts, injection seam with fakes
abstract interface class PhotoSource {
  Future<PhotoPick> pick(PhotoOrigin origin);
}

/// Crops a picture to a square and compresses it. Faked in tests.
// ignore: one_member_abstracts, injection seam with fakes
abstract interface class PhotoProcessor {
  /// The processed PNG, or null if [raw] is not a picture or cannot be made
  /// small enough.
  Future<Uint8List?> process(Uint8List raw);
}

/// Largest stored profile photo.
const int profilePhotoMaxBytes = 100 * 1024;

/// The profile photo of this device (PU-T13, ADR-25). One processed picture,
/// stored in the app's private folder only: it is never uploaded or synced
/// (that waits for Storage, P9-T01).
abstract interface class ProfilePhotoRepository {
  /// Null while no photo was saved.
  Future<RepoResult<Uint8List?>> get();

  /// Replaces the photo. [InvalidData] if empty or above
  /// [profilePhotoMaxBytes].
  Future<RepoResult<void>> save(Uint8List png);

  /// Deletes the photo; fine if there is none.
  Future<RepoResult<void>> remove();
}

/// Shared by the file and the in-memory repository.
RepoResult<void> validateProfilePhoto(Uint8List png) =>
    png.isEmpty || png.length > profilePhotoMaxBytes
    ? const Err(InvalidData('invalid: photo'))
    : const Ok(null);

/// One file ([file]) in the private app folder.
class FileProfilePhotoRepository implements ProfilePhotoRepository {
  const FileProfilePhotoRepository(this.file);

  final File file;

  @override
  Future<RepoResult<Uint8List?>> get() => guardStorage(
    () async => Ok(file.existsSync() ? await file.readAsBytes() : null),
  );

  @override
  Future<RepoResult<void>> save(Uint8List png) async {
    final valid = validateProfilePhoto(png);
    if (valid is Err<void, RepositoryError>) return valid;
    return guardStorage(() async {
      // Write beside, then rename: a crash never leaves half a picture.
      final temp = File('${file.path}.tmp');
      await temp.writeAsBytes(png, flush: true);
      await temp.rename(file.path);
      return const Ok(null);
    });
  }

  @override
  Future<RepoResult<void>> remove() => guardStorage(() async {
    if (file.existsSync()) await file.delete();
    return const Ok(null);
  });
}
