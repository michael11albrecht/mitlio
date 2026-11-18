// Justification: all fields are final; no meta dependency for @immutable.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import 'package:mitlio_domain/src/core/result.dart';

/// A text that is not `major.minor.patch`.
final class SemVerInvalid {
  /// Creates the error.
  const SemVerInvalid(this.input);

  final String input;

  @override
  bool operator ==(Object other) =>
      other is SemVerInvalid && other.input == input;

  @override
  int get hashCode => Object.hash(SemVerInvalid, input);

  @override
  String toString() => 'SemVerInvalid($input)';
}

/// `major.minor.patch`, compared numerically (P6-T16 version gate).
///
/// Accepts an optional `+build` suffix (ignored, as the stores report it
/// that way). Pre-release tags (`-beta`) are not part of the app's versions
/// and are rejected rather than guessed at.
final class SemVer implements Comparable<SemVer> {
  /// Creates a version; all parts must be non-negative.
  const SemVer(this.major, this.minor, this.patch)
    : assert(major >= 0 && minor >= 0 && patch >= 0, 'negative part');

  final int major;
  final int minor;
  final int patch;

  static final _format = RegExp(
    r'^(\d{1,9})\.(\d{1,9})\.(\d{1,9})(?:\+[0-9A-Za-z.-]+)?$',
  );

  /// Parses `1.2.3` or `1.2.3+45`.
  static Result<SemVer, SemVerInvalid> parse(String input) {
    final m = _format.firstMatch(input);
    if (m == null) return Err(SemVerInvalid(input));
    return Ok(
      SemVer(
        int.parse(m.group(1)!),
        int.parse(m.group(2)!),
        int.parse(m.group(3)!),
      ),
    );
  }

  @override
  int compareTo(SemVer other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    return patch.compareTo(other.patch);
  }

  bool operator <(SemVer other) => compareTo(other) < 0;

  bool operator >(SemVer other) => compareTo(other) > 0;

  bool operator <=(SemVer other) => compareTo(other) <= 0;

  bool operator >=(SemVer other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) => other is SemVer && compareTo(other) == 0;

  @override
  int get hashCode => Object.hash(major, minor, patch);

  @override
  String toString() => '$major.$minor.$patch';
}
