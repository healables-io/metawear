import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:metawear_dart/boards/board.dart';
import 'package:metawear_dart/data/board_info.dart';
import 'package:metawear_dart/metawear.dart';
import 'package:metawear_dart/modules/modules.dart';

class MetamotionRLBoard implements MetawearBoard {
  final String id;
  final String name;
  late String? mac;

  final MethodChannel _channel;

  late SensorFusionBoschModule sensorFusionBoschModule;

  MetamotionRLBoard({
    required this.id,
    required this.name,
    required this.mac,
  }) : _channel = MethodChannel('$channelNamespace/metawear/$id') {
    if (!Platform.isIOS) {
      mac = id;
    } else {
      mac = null;
    }

    sensorFusionBoschModule = SensorFusionBoschModule(_channel);
  }

  @override
  Future<void> connect() async {
    await _channel.invokeMethod('connect');
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

  @override
  String toString() {
    return 'MetamotionRLBoard{id: $id, name: $name, mac: $mac}';
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
