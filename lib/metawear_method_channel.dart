import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:metawear_dart/boards/metamotionrl_board.dart';
import 'package:metawear_dart/metawear.dart';

import 'metawear_platform_interface.dart';

/// An implementation of [MetawearPlatform] that uses method channels.
class MethodChannelMetawear extends MetawearPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel(channelNamespace);

  final scanEventChannel = const EventChannel(scanEventChannelName);

  @override
  Stream<MetamotionRLBoard> startScan() {
    methodChannel.invokeMethod('startScan');
    return scanEventChannel
        .receiveBroadcastStream()
        .map((data) => MetamotionRLBoard(
              id: data['id'],
              name: data['name'] ?? '',
              mac: data['mac'] ?? '',
            ));
  }

  @override
  Future<void> stopScan() async {
    await methodChannel.invokeMethod('stopScan');
  }
}
