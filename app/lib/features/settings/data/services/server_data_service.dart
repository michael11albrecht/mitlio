/// The server side of "delete my data": the `delete_my_data` RPC (migration
/// 0008). There are no accounts yet, so the default is inert.
abstract interface class ServerDataService {
  /// Whether there is a signed-in user whose server data could exist.
  bool get isSignedIn;

  /// Calls the RPC. Idempotent on the server; throws if it did not succeed.
  Future<void> deleteMyData();
}

/// Used while the app has no accounts: nothing is stored on the server for
/// this device, so there is nothing to call.
class InertServerDataService implements ServerDataService {
  const InertServerDataService();

  @override
  bool get isSignedIn => false;

  @override
  Future<void> deleteMyData() async {}
}
