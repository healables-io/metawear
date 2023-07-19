import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:metawear/boards/metamotionrl_board.dart';
import 'package:metawear/metawear.dart';
import 'package:metawear/modules/modules.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _metawearPlugin = Metawear();
  String macAddress = "FA:95:EE:56:26:E9";
  MetamotionRLBoard? board;

  StreamSubscription<Acceleration>? accelerationStream;

  @override
  void initState() {
    super.initState();
  }

  _connect() async {
    try {
      await _metawearPlugin.requestPermissions();
      print('Trying to connect to $macAddress');
      MetamotionRLBoard b =
          await _metawearPlugin.connect(macAddress, retry: true);
      b.onDisconnected(() {
        print('Disconnected from $macAddress');
      });
      setState(() {
        board = b;
      });
      print('Connected to $macAddress; board: $board');
    } catch (e) {
      print('Failed to connect to $macAddress');
    }
  }

  _disconnect() async {
    print('Disconnecting from $macAddress');
    board?.disconnect();
    print('Disconnected from $macAddress');
  }

  _feature({
    required String label,
    required Stream? stream,
    required Function() start,
    required Function() stop,
  }) {
    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(label),
          ElevatedButton(
            onPressed: start,
            child: Text('Start'),
          ),
          ElevatedButton(
            onPressed: stop,
            child: Text('Stop'),
          ),
        ],
      ),
      if (board != null && stream != null)
        StreamBuilder(
          stream: stream,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Text('$label: ${snapshot.data}');
            } else {
              return Text('No data');
            }
          },
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(children: [
            ElevatedButton(onPressed: _connect, child: Text('Connect')),
            ElevatedButton(onPressed: _disconnect, child: Text('Disconnect')),
            ElevatedButton(
              onPressed: () {
                board?.deviceInfo().then((value) {
                  print('Device info: $value');
                });
              },
              child: Text('Device info'),
            ),
            ElevatedButton(
              onPressed: () {
                board?.model().then((value) {
                  print('Model: $value');
                });
              },
              child: Text('Device model'),
            ),
            ElevatedButton(
              onPressed: () {
                board?.battery().then((value) {
                  print('Battery: $value');
                });
              },
              child: Text('Battery'),
            ),
            ..._feature(
              label: 'Acceleration',
              stream: board?.sensorFusionBoschModule.correctedAcceleration,
              start: () {
                board?.sensorFusionBoschModule.startCorrectedAcceleration(
                  mode: SensorFusionBoschMode.NDOF,
                  accRange: SensorFusionBoschAccRange.AR_16G,
                  gyroRange: SensorFusionBoschGyroRange.GR_2000DPS,
                );
              },
              stop: () {
                board?.sensorFusionBoschModule.stop();
              },
            ),
            ..._feature(
              label: 'Angular Velocity',
              stream: board?.sensorFusionBoschModule.correctedAngularVelocity,
              start: () {
                board?.sensorFusionBoschModule.startCorrectedAngularVelocity(
                  mode: SensorFusionBoschMode.NDOF,
                  accRange: SensorFusionBoschAccRange.AR_16G,
                  gyroRange: SensorFusionBoschGyroRange.GR_2000DPS,
                );
              },
              stop: () {
                board?.sensorFusionBoschModule.stop();
              },
            ),
            ..._feature(
              label: 'Magnetic Field',
              stream: board?.sensorFusionBoschModule.correctedMagneticField,
              start: () {
                board?.sensorFusionBoschModule.startCorrectedMagneticField(
                  mode: SensorFusionBoschMode.NDOF,
                  accRange: SensorFusionBoschAccRange.AR_16G,
                  gyroRange: SensorFusionBoschGyroRange.GR_2000DPS,
                );
              },
              stop: () {
                board?.sensorFusionBoschModule.stop();
              },
            ),
            ..._feature(
              label: 'Quaternion',
              stream: board?.sensorFusionBoschModule.quaternion,
              start: () {
                board?.sensorFusionBoschModule.startQuaternion();
              },
              stop: () {
                board?.sensorFusionBoschModule.stop();
              },
            ),
          ]),
        ),
      ),
    );
  }
}
