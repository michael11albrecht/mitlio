import 'dart:typed_data';

import 'package:mitlio/core/repository_error.dart';
import 'package:mitlio/features/profile/data/repositories/profile_photo_repository.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// In-memory [ProfilePhotoRepository] with the same validation.
class FakeProfilePhotoRepository implements ProfilePhotoRepository {
  Uint8List? _photo;

  @override
  Future<RepoResult<Uint8List?>> get() async => Ok(_photo);

  @override
  Future<RepoResult<void>> save(Uint8List png) async {
    final valid = validateProfilePhoto(png);
    if (valid is Err<void, RepositoryError>) return valid;
    _photo = png;
    return const Ok(null);
  }

  @override
  Future<RepoResult<void>> remove() async {
    _photo = null;
    return const Ok(null);
  }
}

/// A [PhotoSource] that returns a fixed answer and records what was asked.
class FakePhotoSource implements PhotoSource {
  FakePhotoSource([this.answer = const PhotoPickCancelled()]);

  PhotoPick answer;
  final asked = <PhotoOrigin>[];

  @override
  Future<PhotoPick> pick(PhotoOrigin origin) async {
    asked.add(origin);
    return answer;
  }
}

/// A [PhotoProcessor] that returns a fixed answer (null = unusable).
class FakePhotoProcessor implements PhotoProcessor {
  FakePhotoProcessor(this.result);

  Uint8List? result;

  @override
  Future<Uint8List?> process(Uint8List raw) async => result;
}
