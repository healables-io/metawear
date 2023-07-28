import Flutter
import MetaWear
import MetaWearCpp

public class ScannerModelItem {
  public let device: MetaWear
  private var channel: FlutterMethodChannel

  public var id: String {
    return device.mac ?? device.peripheral.identifier.uuidString
  }

  init(_ device: MetaWear, _ channel: FlutterMethodChannel) {
    print(
      "init ScannerModelItem(): Channel: \(NAMESPACE)/metawear/\(device.peripheral.identifier.uuidString)"
    )
    self.device = device
    self.channel = channel
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    print("print handle(): \(call.method)")
    switch call.method {
    case "connect":
      self.connect(result: result)
    case "disconnect":
      self.disconnect(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  public func connect(result: @escaping FlutterResult) {
    print("Connect()")
    device.connectAndSetup().continueWith { t in
      if let error = t.error {
        print("Error connecting: \(error.localizedDescription)")
        result(false)
      } else {
        print("Connected!")
        result(true)
      }
    }
  }

  public func disconnect(result: @escaping FlutterResult) {
    print("Disconnect()")
    device.cancelConnection()
    result(true)

  }

}
