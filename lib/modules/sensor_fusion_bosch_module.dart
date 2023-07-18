import 'dart:async';

import 'package:flutter/services.dart';
import 'package:metawear/boards/boards.dart';
import 'package:metawear/data/angular_velocity.dart';
import 'package:metawear/data/magnetic_field.dart';
import 'package:metawear/data/quaternion.dart';

class SensorFusionBoschModule {
  final MethodChannel _channel;

  final StreamController<Acceleration> _correctedAccelerationController =
      StreamController.broadcast();

  final StreamController<AngularVelocity> _correctedAngularVelocityController =
      StreamController.broadcast();

  final StreamController<MagneticField> _correctedMagneticFieldController =
      StreamController.broadcast();

  final StreamController<Quaternion> _quaternionController =
      StreamController.broadcast();

  Stream<Acceleration> get correctedAcceleration =>
      _correctedAccelerationController.stream;

  Stream<AngularVelocity> get correctedAngularVelocity =>
      _correctedAngularVelocityController.stream;

  Stream<MagneticField> get correctedMagneticField =>
      _correctedMagneticFieldController.stream;

  Stream<Quaternion> get quaternion => _quaternionController.stream;

  bool isAccelerometerActive = false;
  bool isGyroscopeActive = false;
  bool isMagnetometerActive = false;
  bool isQuaternionActive = false;

  SensorFusionBoschModule(this._channel) {
    Timer(
      const Duration(seconds: 1),
      () {
        _channel.setMethodCallHandler((call) => handleMethodCall(call));
      },
    );
  }

  dispose() {
    _channel.setMethodCallHandler(null);
  }

  handleMethodCall(MethodCall call) {
    if (call.method == 'onCorrectedAcceleration') {
      _correctedAccelerationController.sink.add(Acceleration(
        call.arguments['x'],
        call.arguments['y'],
        call.arguments['z'],
      ));
    }

    if (call.method == 'onCorrectedAngularVelocity') {
      _correctedAngularVelocityController.sink.add(AngularVelocity(
        call.arguments['x'],
        call.arguments['y'],
        call.arguments['z'],
      ));
    }

    if (call.method == 'onCorrectedMagneticField') {
      _correctedMagneticFieldController.sink.add(MagneticField(
        call.arguments['x'],
        call.arguments['y'],
        call.arguments['z'],
      ));
    }

    if (call.method == 'onQuaternion') {
      _quaternionController.sink.add(Quaternion(
        call.arguments['w'],
        call.arguments['x'],
        call.arguments['y'],
        call.arguments['z'],
      ));
    }
  }

  void startCorrectedAcceleration() async {
    if (isAccelerometerActive) {
      return;
    }
    await _channel.invokeMethod('startCorrectedAcceleration');
    isAccelerometerActive = true;
  }

  void startCorrectedAngularVelocity() async {
    if (isGyroscopeActive) {
      return;
    }
    await _channel.invokeMethod('startCorrectedAngularVelocity');
    isGyroscopeActive = true;
  }

  void startCorrectedMagneticField() async {
    if (isMagnetometerActive) {
      return;
    }
    await _channel.invokeMethod('startCorrectedMagneticField');
    isMagnetometerActive = true;
  }

  void startQuaternion() async {
    if (isQuaternionActive) {
      return;
    }
    await _channel.invokeMethod('startQuaternion');
    isQuaternionActive = true;
  }

  void stop() async {
    await _channel.invokeMethod('stop');
    isAccelerometerActive = false;
    isGyroscopeActive = false;
    isMagnetometerActive = false;
    isQuaternionActive = false;
  }
}
