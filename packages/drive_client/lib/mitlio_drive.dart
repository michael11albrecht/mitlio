/// Client for the `ext.mitlio.*` DebugDrive protocol (docs/drive-protocol.md).
///
/// Implemented in P3-T04; P0 only provides the package skeleton.
library;

/// Prefix of every DebugDrive service extension.
const extensionPrefix = 'ext.mitlio.';

/// Returns the fully qualified extension name for [method].
String extensionName(String method) =>
    method.startsWith(extensionPrefix) ? method : '$extensionPrefix$method';
