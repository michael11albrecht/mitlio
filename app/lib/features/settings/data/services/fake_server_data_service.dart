import 'package:mitlio/features/settings/data/services/server_data_service.dart';

/// Records calls; can be signed in and made to fail.
class FakeServerDataService implements ServerDataService {
  FakeServerDataService({this.isSignedIn = false, this.failWith});

  @override
  bool isSignedIn;

  /// Thrown by [deleteMyData] while set.
  Exception? failWith;

  int calls = 0;

  @override
  Future<void> deleteMyData() async {
    calls++;
    final error = failWith;
    if (error != null) throw error;
  }
}
