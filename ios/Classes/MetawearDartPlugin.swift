import BoltsSwift
import Flutter
import MetaWear
import MetaWearCpp
import UIKit

let NAMESPACE = "ai.healables.metawear_dart"

public class MetawearDartPlugin: NSObject, FlutterPlugin {

  private var registrar: FlutterPluginRegistrar?

  private var scanEvents: EventChannelHandler?

  public var items: [MetawearBoardChannel] = []

  public override init() {
    super.init()
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = MetawearDartPlugin()
    instance.setupChannel(registrar: registrar)
  }

  private func setupChannel(registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: NAMESPACE, binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(self, channel: channel)

    scanEvents = EventChannelHandler(id: "\(NAMESPACE)/scan", messenger: registrar.messenger())
    self.registrar = registrar
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    NSLog("NSLog handle(): \(call.method) ")
    print("print handle(): \(call.method)")

    switch call.method {
    case "startScan":
      self.startScan()
      result(nil)
    case "stopScan":
      self.stopScan()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  public func startScan() {
    let MIN_ALLOWED_RSSI = -45
    print("scan: \(MIN_ALLOWED_RSSI)")
    MetaWearScanner.shared.startScan(allowDuplicates: false) { (device) in
      print("Found device: \(device.name) \(device.mac) \(device.rssi)")
      do {
        let item = MetawearBoardChannel(device, self.registrar!)
        self.items.append(item)
        var args = [String: String?]()
        args["id"] = device.peripheral.identifier.uuidString
        args["name"] = device.name
        args["mac"] = device.mac
        args["rssi"] = String(device.rssi)
        try self.scanEvents?.success(event: args)
      } catch {
        print("Error: \(error.localizedDescription)")
        self.scanEvents?.error(code: "scanFailure", message: error.localizedDescription)
      }

    }
  }

  public func stopScan() {
    MetaWearScanner.shared.stopScan()
  }

}

extension Dictionary {
  var jsonStringRepresentation: String? {
    guard
      let theJSONData = try? JSONSerialization.data(
        withJSONObject: self,
        options: [.prettyPrinted])
    else {
      return nil
    }

    return String(data: theJSONData, encoding: .ascii)
  }
}
