import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitlio/debug/drive_types.dart';
import 'package:mitlio/features/profile/data/repositories/profile_photo_repository.dart';
import 'package:mitlio/features/profile/ui/profile_photo_view_model.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// `ext.mitlio.profile.photo.*` (PU-T13; keys without the `ext.mitlio.`
/// prefix): thin wrappers over `ProfilePhotoViewModel`, the commands the
/// avatar step uses. The photo itself never leaves the device; `photo.state`
/// reports only its size.
Map<String, DriveHandler> profilePhotoDriveHandlers(ProviderContainer c) {
  ProfilePhotoViewModel vm() => c.read(profilePhotoViewModelProvider.notifier);

  Future<DriveResult> state() async {
    await vm().load();
    final s = c.read(profilePhotoViewModelProvider);
    return {
      'hasPhoto': s.photo != null,
      'bytes': s.photo?.length ?? 0,
      'canPick': s.canPick,
    };
  }

  DriveResult outcome(PhotoOutcome o) => {'outcome': o.name};

  return {
    'profile.photo.state': (_) => state(),
    'profile.photo.set': (p) async {
      final data = p['data'];
      if (data == null || data.isEmpty) {
        return invalidParams('missing param: data');
      }
      final List<int> raw;
      try {
        raw = base64Decode(data);
      } on FormatException {
        return invalidParams('param data is not base64');
      }
      return switch (await vm().setFromBytes(Uint8List.fromList(raw))) {
        Ok(:final value) => outcome(value),
        Err(:final error) => driveError(error),
      };
    },
    'profile.photo.pick': (p) async {
      final origin = PhotoOrigin.values.asNameMap()[p['source']];
      if (origin == null) {
        return invalidParams('param source must be camera or gallery');
      }
      return switch (await vm().pick(origin)) {
        Ok(:final value) => outcome(value),
        Err(:final error) => driveError(error),
      };
    },
    'profile.photo.remove': (_) async => switch (await vm().remove()) {
      Ok() => {'removed': true},
      Err(:final error) => driveError(error),
    },
  };
}
