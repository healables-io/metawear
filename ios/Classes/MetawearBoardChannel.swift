import Flutter
import MetaWear
import MetaWearCpp

public class MetawearBoardChannel {

  public let device: MetaWear
  private var channel: FlutterMethodChannel?
  private var connectionStateHandler: EventChannelHandler?

  private var registrar: FlutterPluginRegistrar?

  private var accelerationSignal: OpaquePointer? = nil
  private var magneticFieldSignal: OpaquePointer? = nil
  private var gyroscopeSignal: OpaquePointer? = nil
  private var quaternionSignal: OpaquePointer? = nil

  public var id: String {
    return device.mac ?? device.peripheral.identifier.uuidString
  }

  init(_ device: MetaWear, _ registrar: FlutterPluginRegistrar) {
    self.device = device
    self.channel = nil
    self.connectionStateHandler = nil

    DispatchQueue.main.async {
      self.channel = FlutterMethodChannel(
        name: "\(NAMESPACE)/metawear/\(device.peripheral.identifier.uuidString)",
        binaryMessenger: registrar.messenger()
      )
      self.connectionStateHandler = EventChannelHandler(
        id: "\(NAMESPACE)/metawear/\(device.peripheral.identifier.uuidString)/state",
        messenger: registrar.messenger()
      )
      self.channel?.setMethodCallHandler(self.handle)
    }
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    print("print handle(): \(call.method)")
    switch call.method {
    case "connect":
      self.connect(result: result)
    case "disconnect":
      self.disconnect(result: result)
    case "isConnected":
      result(device.isConnectedAndSetup)
    case "battery":
      self.getBattery(result: result)
    case "deviceInfo":
      self.getDeviceInfo(result: result)
    case "model":
      device.readModelNumber().continueWith { t in
        if let error = t.error {
          print("Error reading model number: \(error.localizedDescription)")
          result(nil)
        } else {
          print("Model number: \(t.result!)")
          result(t.result!)
        }
      }
    case "startCorrectedAcceleration":
      self.startCorrectedAcceleration(arguments: call.arguments, result: result)
    case "startCorrectedAngularVelocity":
      self.startCorrectedAngularVelocity(arguments: call.arguments, result: result)
    case "startCorrectedMagneticField":
      self.startCorrectedMagneticField(arguments: call.arguments, result: result)
    case "startQuaternion":
      self.startQuaternion(arguments: call.arguments, result: result)
    case "stop":
      self.stop(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  public func connect(result: @escaping FlutterResult) {
    print("Connect()")
    device.connectAndSetup().continueWith { t in
      t.result?.continueWith { task in
        print("Lost connection")
        try self.connectionStateHandler?.success(event: [
          "connected": false, "reason": "Lost connection",
        ])
      }

      if let error = t.error {
        print("Error: \(error.localizedDescription)")
        try self.connectionStateHandler?.success(event: [
          "connected": false, "reason": error.localizedDescription,
        ])
        result(nil)
      } else {
        print("Connected")
        try self.connectionStateHandler?.success(event: ["connected": true])
        result(true)
      }

    }
  }

  public func disconnect(result: @escaping FlutterResult) {
    print("Disconnect()")
    device.cancelConnection()
    result(true)

  }

  public func getBattery(result: @escaping FlutterResult) {
    // TODO: Implement battery
    result(FlutterMethodNotImplemented)
  }

  public func getDeviceInfo(result: @escaping FlutterResult) {
    let info: DeviceInformation? = self.device.info

    result([
      "manufacturer": info?.manufacturer,
      "modelNumber": info?.modelNumber,
      "serialNumber": info?.serialNumber,
      "firmwareRevision": info?.firmwareRevision,
      "hardwareRevision": info?.hardwareRevision,
    ])
  }

  private func configureSensor(arguments: [String: String]) {

    let mode = arguments["mode"]
    let accRange = arguments["accRange"]
    let gyroRange = arguments["gyroRange"]

    mbl_mw_sensor_fusion_set_mode(
      device.board,
      mode == "IMU_PLUS"
        ? MBL_MW_SENSOR_FUSION_MODE_IMU_PLUS
        : mode == "COMPASS"
          ? MBL_MW_SENSOR_FUSION_MODE_COMPASS
          : mode == "M4G"
            ? MBL_MW_SENSOR_FUSION_MODE_M4G
            : mode == "NDOF"
              ? MBL_MW_SENSOR_FUSION_MODE_NDOF
              : mode == "SLEEP" ? MBL_MW_SENSOR_FUSION_MODE_SLEEP : MBL_MW_SENSOR_FUSION_MODE_NDOF)
    mbl_mw_sensor_fusion_set_acc_range(
      device.board,
      accRange == "AR_16G"
        ? MBL_MW_SENSOR_FUSION_ACC_RANGE_16G
        : accRange == "AR_8G"
          ? MBL_MW_SENSOR_FUSION_ACC_RANGE_8G
          : accRange == "AR_4G"
            ? MBL_MW_SENSOR_FUSION_ACC_RANGE_4G
            : accRange == "AR_2G"
              ? MBL_MW_SENSOR_FUSION_ACC_RANGE_2G : MBL_MW_SENSOR_FUSION_ACC_RANGE_16G)
    mbl_mw_sensor_fusion_set_gyro_range(
      device.board,
      gyroRange == "GR_2000DPS"
        ? MBL_MW_SENSOR_FUSION_GYRO_RANGE_2000DPS
        : gyroRange == "GR_1000DPS"
          ? MBL_MW_SENSOR_FUSION_GYRO_RANGE_1000DPS
          : gyroRange == "GR_500DPS"
            ? MBL_MW_SENSOR_FUSION_GYRO_RANGE_500DPS
            : gyroRange == "GR_250DPS"
              ? MBL_MW_SENSOR_FUSION_GYRO_RANGE_250DPS : MBL_MW_SENSOR_FUSION_GYRO_RANGE_2000DPS)
    mbl_mw_sensor_fusion_write_config(self.device.board)
  }

  public func startCorrectedAcceleration(arguments: Any?, result: @escaping FlutterResult) {
    self.accelerationSignal = mbl_mw_sensor_fusion_get_data_signal(
      self.device.board, MBL_MW_SENSOR_FUSION_DATA_CORRECTED_ACC)

    mbl_mw_datasignal_subscribe(self.accelerationSignal, bridge(obj: self)) {
      (context, obj) in
      let data: MblMwCorrectedCartesianFloat = obj!.pointee.valueAs()
      let source: MetawearBoardChannel = bridge(ptr: context!)
      DispatchQueue.main.async {
        print(Double(data.x), Double(data.y), Double(data.z))
        source.channel?.invokeMethod(
          "onCorrectedAcceleration",
          arguments: [
            "x": Double(data.x),
            "y": Double(data.y),
            "z": Double(data.z),
          ])
      }
    }

    self.configureSensor(arguments: arguments as! [String: String])

    mbl_mw_sensor_fusion_enable_data(self.device.board, MBL_MW_SENSOR_FUSION_DATA_CORRECTED_ACC)
    mbl_mw_sensor_fusion_start(self.device.board)

    result(true)
  }

  public func startCorrectedAngularVelocity(arguments: Any?, result: @escaping FlutterResult) {
    self.gyroscopeSignal = mbl_mw_sensor_fusion_get_data_signal(
      self.device.board, MBL_MW_SENSOR_FUSION_DATA_CORRECTED_GYRO)

    mbl_mw_datasignal_subscribe(self.gyroscopeSignal, bridge(obj: self)) {
      (context, obj) in
      let data: MblMwCorrectedCartesianFloat = obj!.pointee.valueAs()
      let source: MetawearBoardChannel = bridge(ptr: context!)
      DispatchQueue.main.async {
        print(Double(data.x), Double(data.y), Double(data.z))
        source.channel?.invokeMethod(
          "onCorrectedAngularVelocity",
          arguments: [
            "x": Double(data.x),
            "y": Double(data.y),
            "z": Double(data.z),
          ])
      }
    }

    self.configureSensor(arguments: arguments as! [String: String])

    mbl_mw_sensor_fusion_enable_data(self.device.board, MBL_MW_SENSOR_FUSION_DATA_CORRECTED_GYRO)
    mbl_mw_sensor_fusion_start(self.device.board)

    result(true)
  }

  public func startCorrectedMagneticField(arguments: Any?, result: @escaping FlutterResult) {
    self.magneticFieldSignal = mbl_mw_sensor_fusion_get_data_signal(
      self.device.board, MBL_MW_SENSOR_FUSION_DATA_CORRECTED_MAG)

    mbl_mw_datasignal_subscribe(self.magneticFieldSignal, bridge(obj: self)) {
      (context, obj) in
      let data: MblMwCorrectedCartesianFloat = obj!.pointee.valueAs()
      let source: MetawearBoardChannel = bridge(ptr: context!)
      DispatchQueue.main.async {
        print(Double(data.x), Double(data.y), Double(data.z))
        source.channel?.invokeMethod(
          "onCorrectedMagneticField",
          arguments: [
            "x": Double(data.x),
            "y": Double(data.y),
            "z": Double(data.z),
          ])
      }
    }

    self.configureSensor(arguments: arguments as! [String: String])

    mbl_mw_sensor_fusion_enable_data(self.device.board, MBL_MW_SENSOR_FUSION_DATA_CORRECTED_MAG)
    mbl_mw_sensor_fusion_start(self.device.board)

    result(true)
  }

  public func startQuaternion(arguments: Any?, result: @escaping FlutterResult) {
    self.quaternionSignal = mbl_mw_sensor_fusion_get_data_signal(
      self.device.board, MBL_MW_SENSOR_FUSION_DATA_QUATERNION)

    mbl_mw_datasignal_subscribe(self.quaternionSignal, bridge(obj: self)) {
      (context, obj) in
      let data: MblMwQuaternion = obj!.pointee.valueAs()
      let source: MetawearBoardChannel = bridge(ptr: context!)
      DispatchQueue.main.async {
        print(Double(data.x), Double(data.y), Double(data.z), Double(data.w))
        source.channel?.invokeMethod(
          "onQuaternion",
          arguments: [
            "w": Double(data.w),
            "x": Double(data.x),
            "y": Double(data.y),
            "z": Double(data.z),
          ])
      }
    }

    mbl_mw_sensor_fusion_enable_data(self.device.board, MBL_MW_SENSOR_FUSION_DATA_QUATERNION)
    mbl_mw_sensor_fusion_start(self.device.board)

    result(true)
  }

  public func stop(result: @escaping FlutterResult) {
    print("Stop()")
    mbl_mw_sensor_fusion_stop(self.device.board)
    mbl_mw_sensor_fusion_clear_enabled_mask(self.device.board)
    if self.accelerationSignal != nil {
      mbl_mw_datasignal_unsubscribe(self.accelerationSignal!)
    }
    if self.gyroscopeSignal != nil {
      mbl_mw_datasignal_unsubscribe(self.gyroscopeSignal!)
    }
    if self.magneticFieldSignal != nil {
      mbl_mw_datasignal_unsubscribe(self.magneticFieldSignal!)
    }
    if self.quaternionSignal != nil {
      mbl_mw_datasignal_unsubscribe(self.quaternionSignal!)
    }
    result(true)
  }

}
