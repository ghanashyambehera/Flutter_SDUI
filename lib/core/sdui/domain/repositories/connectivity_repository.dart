abstract class ConnectivityRepository {
  Future<bool> isOnline();
  Stream<bool> onStatusChange();
}
