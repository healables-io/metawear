import 'dart:async';

import 'package:flutter/services.dart';
import 'package:metawear_dart/boards/boards.dart';
import 'package:metawear_dart/data/angular_velocity.dart';
import 'package:metawear_dart/data/magnetic_field.dart';
import 'package:metawear_dart/data/quaternion.dart';

enum SensorFusionBoschMode {
  SLEEP,
  NDOF,
  IMU_PLUS,
  COMPASS,
  M4G,
}

enum SensorFusionBoschAccRange {
  AR_2G,
  AR_4G,
  AR_8G,
  AR_16G,
}

enum SensorFusionBoschGyroRange {
  GR_2000DPS,
  GR_1000DPS,
  GR_500DPS,
  GR_250DPS,
  GR_125DPS,
}

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

  void startCorrectedAcceleration({
    required SensorFusionBoschMode mode,
    required SensorFusionBoschAccRange accRange,
    required SensorFusionBoschGyroRange gyroRange,
  }) async {
    if (isAccelerometerActive) {
      return;
    }
    await _channel.invokeMethod('startCorrectedAcceleration', {
      'mode': mode.name,
      'accRange': accRange.name,
      'gyroRange': gyroRange.name,
    });
    isAccelerometerActive = true;
  }

  void startCorrectedAngularVelocity({
    required SensorFusionBoschMode mode,
    required SensorFusionBoschAccRange accRange,
    required SensorFusionBoschGyroRange gyroRange,
  }) async {
    if (isGyroscopeActive) {
      return;
    }
    await _channel.invokeMethod('startCorrectedAngularVelocity', {
      'mode': mode.name,
      'accRange': accRange.name,
      'gyroRange': gyroRange.name,
    });
    isGyroscopeActive = true;
  }

  void startCorrectedMagneticField({
    required SensorFusionBoschMode mode,
    required SensorFusionBoschAccRange accRange,
    required SensorFusionBoschGyroRange gyroRange,
  }) async {
    if (isMagnetometerActive) {
      return;
    }
    await _channel.invokeMethod('startCorrectedMagneticField', {
      'mode': mode.name,
      'accRange': accRange.name,
      'gyroRange': gyroRange.name,
    });
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
