import 'dart:async';

import 'package:flutter/services.dart';
import 'package:metawear/boards/board.dart';
import 'package:metawear/data/board_info.dart';
import 'package:metawear/metawear.dart';
import 'package:metawear/modules/modules.dart';

class MetamotionRLBoard implements MetawearBoard {
  final String mac;

  final MethodChannel _channel;

  late SensorFusionBoschModule sensorFusionBoschModule;

  MetamotionRLBoard(this.mac)
      : _channel = MethodChannel('$channelNamespace/metawear/$mac') {
    sensorFusionBoschModule = SensorFusionBoschModule(_channel);
  }

  @override
  Future<void> disconnect() async {
    await _channel.invokeMethod('disconnect');
  }

  @override
  Future<bool> isConnected() async {
    return await _channel.invokeMethod<bool>('isConnected') ?? false;
  }

  @override
  void onDisconnected(void Function() callback) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onDisconnect') {
        callback();
      }
    });
  }

  Future<String?> model() {
    return _channel.invokeMethod('model');
  }

  Future<DeviceInfo> deviceInfo() async {
    Map<String, String>? data =
        await _channel.invokeMapMethod<String, String>('deviceInfo');

    if (data == null) {
      throw Exception('Failed to get device info');
    }

    return DeviceInfo.fromMap(data);
  }

  Future<DeviceModel> deviceModel() async {
    String? model = await _channel.invokeMethod('model');

    if (model == null) {
      throw Exception('Failed to get device model');
    }

    return DeviceModel.unknown.fromString(model);
  }

  Future<int> battery() async {
    return await _channel.invokeMethod<int>('battery') ?? -1;
  }
}
