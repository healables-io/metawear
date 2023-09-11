import 'package:metawear_dart/data/board_info.dart';

abstract class MetawearBoard {
  /// The ID of the board. On Android, this is the MAC address of the board. On iOS, this is a unique ID.
  String get id;

  String get name;

  /// The MAC address of the board. Not available on iOS.
  String? get mac;

  Stream<bool> get state;

  Future<void> connect();

  Future<void> disconnect();

  Future<bool> isConnected();

  void onDisconnected(void Function(String? reason) callback);

  Future<DeviceInfo> info();

  Future<DeviceModel> model();

  Future<int> battery();
}
