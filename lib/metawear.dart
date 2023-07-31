export 'boards/boards.dart';
export 'data/data.dart';

import 'package:metawear_dart/boards/metamotionrl_board.dart';
import 'package:permission_handler/permission_handler.dart';

import 'metawear_platform_interface.dart';

const String channelNamespace = 'ai.healables.metawear_dart';
const String scanEventChannelName = '$channelNamespace/scan';

class Metawear {
  Future<bool> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();

    return statuses[Permission.location] == PermissionStatus.granted &&
        statuses[Permission.bluetooth] == PermissionStatus.granted &&
        statuses[Permission.bluetoothConnect] == PermissionStatus.granted;
  }

  Stream<MetamotionRLBoard> startScan() {
    return MetawearPlatform.instance.startScan();
  }

  Future<void> stopScan() {
    return MetawearPlatform.instance.stopScan();
  }
}
