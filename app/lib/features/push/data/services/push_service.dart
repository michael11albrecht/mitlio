import 'package:mitlio/features/push/data/push_models.dart';
import 'package:mitlio_domain/mitlio_domain.dart';

/// The platform side of push: permission, the FCM token and the messages
/// that reach the app (ADR-13). Every failure is a [PushError]; nothing
/// throws. The real Firebase implementation lands with P6b-T01 (needs the
/// owner's Firebase projects); until then `main` registers
/// [UnavailablePushService], and tests and DebugDrive use `FakePushService`.
abstract interface class PushService {
  /// False when this build cannot receive pushes: every other call then
  /// answers [PushUnavailable], and the app hides the offer.
  bool get isAvailable;

  /// `android` or `ios`, as `device_tokens.platform` wants it; null elsewhere.
  String? get platform;

  /// The current permission, without asking.
  Future<Result<PushPermission, PushError>> permission();

  /// Asks the OS (Android 13+, iOS). Call only after the user chose to.
  Future<Result<PushPermission, PushError>> requestPermission();

  /// The FCM token; `Ok(null)` when there is none yet.
  Future<Result<String?, PushError>> token();

  /// Forgets the token on this device (sign-out, delete my data).
  Future<Result<void, PushError>> deleteToken();

  /// A new token after the platform rotated it.
  Stream<String> get tokenRefreshes;

  /// Messages that arrived while the app was open.
  Stream<PushMessage> get foregroundMessages;

  /// Messages delivered while the app ran in the background.
  Stream<PushMessage> get backgroundMessages;

  /// The notification the user tapped while the app ran in the background.
  Stream<PushMessage> get openedMessages;

  /// The notification whose tap started the app, if any.
  Future<PushMessage?> initialMessage();
}

/// No Firebase config in this build (P6b-T01 not done): nothing can be
/// received, nothing is asked. Registered by default so the app, the
/// settings and the tests work without Firebase; the settings say so plainly
/// instead of pretending.
class UnavailablePushService implements PushService {
  const UnavailablePushService();

  static const _no = Err<Never, PushError>(PushUnavailable());

  @override
  bool get isAvailable => false;

  @override
  String? get platform => null;

  @override
  Future<Result<PushPermission, PushError>> permission() async => _no;

  @override
  Future<Result<PushPermission, PushError>> requestPermission() async => _no;

  @override
  Future<Result<String?, PushError>> token() async => _no;

  @override
  Future<Result<void, PushError>> deleteToken() async => _no;

  @override
  Stream<String> get tokenRefreshes => const Stream.empty();

  @override
  Stream<PushMessage> get foregroundMessages => const Stream.empty();

  @override
  Stream<PushMessage> get backgroundMessages => const Stream.empty();

  @override
  Stream<PushMessage> get openedMessages => const Stream.empty();

  @override
  Future<PushMessage?> initialMessage() async => null;
}
