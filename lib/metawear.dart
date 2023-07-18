export 'boards/boards.dart';
export 'data/data.dart';

import 'package:metawear/boards/metamotionrl_board.dart';
import 'package:permission_handler/permission_handler.dart';

import 'metawear_platform_interface.dart';

const String channelNamespace = 'ai.healables.metawear';

class Metawear {
  Future<bool> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.bluetooth,
      Permission.bluetoothConnect,
    ].request();

    return statuses[Permission.location] == PermissionStatus.granted &&
        statuses[Permission.bluetooth] == PermissionStatus.granted &&
        statuses[Permission.bluetoothConnect] == PermissionStatus.granted;
  }

  Future<MetamotionRLBoard> connect(String mac, {bool? retry}) {
    return MetawearPlatform.instance.connect(mac, retry: retry);
  }
}
