abstract class MetawearBoard {
  Future<void> disconnect();

  Future<bool> isConnected();

  void onDisconnected(void Function() callback);
}
