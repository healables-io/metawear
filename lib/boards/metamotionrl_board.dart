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
  final EventChannel _stateChannel;

  late SensorFusionBoschModule sensorFusionBoschModule;

  MetamotionRLBoard({
    required this.id,
    required this.name,
    required this.mac,
  })  : _channel = MethodChannel('$channelNamespace/metawear/$id'),
        _stateChannel = EventChannel('$channelNamespace/metawear/$id/state') {
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
  void onDisconnected(void Function(String? reason) callback) {
    _stateChannel.receiveBroadcastStream().listen((call) async {
      if (!call['connected']) {
        callback(call['reason']);
      }
    });
  }

  @override
  String toString() {
    return 'MetamotionRLBoard{id: $id, name: $name, mac: $mac}';
  }

  @override
  Future<DeviceInfo> info() async {
    Map<String, String>? data =
        await _channel.invokeMapMethod<String, String>('deviceInfo');

    if (data == null) {
      throw Exception('Failed to get device info');
    }

    return DeviceInfo.fromMap(data);
  }

  @override
  Future<DeviceModel> model() async {
    String? model = await _channel.invokeMethod('model');

    if (model == null) {
      throw Exception('Failed to get device model');
    }

    if (int.tryParse(model) != null) {
      return DeviceModel.unknown.fromId(int.parse(model));
    }

    return DeviceModel.unknown.fromString(model);
  }

  @override
  Future<int> battery() async {
    if (Platform.isIOS) {
      throw UnimplementedError();
    }
    int battery = await _channel.invokeMethod<int>('battery') ?? -1;
    return battery;
  }
}
