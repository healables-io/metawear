import 'package:metawear_dart/data/board_info.dart';

abstract class MetawearBoard {
  Future<void> connect();

  Future<void> disconnect();

  Future<bool> isConnected();

  void onDisconnected(void Function(String? reason) callback);

  Future<DeviceInfo> info();

  Future<DeviceModel> model();

  Future<int> battery();
}
