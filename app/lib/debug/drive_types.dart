import 'package:mitlio/core/repository_error.dart';

/// JSON-like result of a DebugDrive handler.
typedef DriveResult = Map<String, Object?>;

/// Handler body: params arrive as strings; wrapped by `runDriveHandler`, which
/// turns thrown errors into `{error, message}`.
typedef DriveHandler = Future<DriveResult> Function(Map<String, String> params);

DriveResult invalidParams(String message) => {
  'error': 'invalid_params',
  'message': message,
};

/// Maps a repository failure to the `{error, message}` convention:
/// `invalid_params`, `not_found`, `conflict` or `internal`.
DriveResult driveError(RepositoryError error) => {
  'error': switch (error) {
    InvalidData() => 'invalid_params',
    NotFound() => 'not_found',
    Conflict() => 'conflict',
    Storage() => 'internal',
  },
  'message': error.toString(),
};
