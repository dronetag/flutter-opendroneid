import Flutter
import UIKit

@available(iOS 13.0.0, *)
public class SwiftFlutterOpendroneidPlugin: NSObject, FlutterPlugin, DTGApi{
    private static var eventChannels: [String: FlutterEventChannel] = [:]

    private var bluetoothScanner: BluetoothScanner!

    private let streamHandlers: [String: StreamHandler] = [
        "flutter_odid_data": StreamHandler(),
        "flutter_odid_bt_state": StreamHandler(),
        "flutter_odid_wifi_state": StreamHandler()
    ]
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let messenger : FlutterBinaryMessenger = registrar.messenger()
        let instance : SwiftFlutterOpendroneidPlugin & DTGApi & NSObjectProtocol = SwiftFlutterOpendroneidPlugin.init()
        DTGApiSetup(messenger, instance);
        
        // Register event channels
        eventChannels = [
            "flutter_odid_data": FlutterEventChannel(name: "flutter_odid_data", binaryMessenger: registrar.messenger()),
            "flutter_odid_bt_state": FlutterEventChannel(name: "flutter_odid_bt_state", binaryMessenger: registrar.messenger()),
            "flutter_odid_wifi_state": FlutterEventChannel(name: "flutter_odid_wifi_state", binaryMessenger: registrar.messenger()),
        ]
        
        // Register stream handlers
        for entry in SwiftFlutterOpendroneidPlugin.eventChannels {
            entry.value.setStreamHandler(
                instance.streamHandlers[entry.key]
            )
        }
        
        // Register bluetooth scanner
        instance.bluetoothScanner = BluetoothScanner(
            odidPayloadStreamHandler: instance.streamHandlers["flutter_odid_data"]!,
            scanStateHandler: instance.streamHandlers["flutter_odid_bt_state"]!
        )
    
        registrar.addApplicationDelegate(instance)
    }
    
    public func applicationWillTerminate(_ application: UIApplication) {
        for channel in SwiftFlutterOpendroneidPlugin.eventChannels.values {
            channel.setStreamHandler(nil)
        }
        SwiftFlutterOpendroneidPlugin.eventChannels.removeAll()
        for handler in streamHandlers.values {
            handler.onCancel(withArguments: nil)
        }
    }

    public func btMaxAdvDataLen() async -> (NSNumber?, FlutterError?) {
        return (0, nil)
    }
    
    public func btExtendedSupported() async -> (NSNumber?, FlutterError?) {
        return ((false) as NSNumber?, nil)
    }
    
    public func wifiNaNSupported() async -> (NSNumber?, FlutterError?) {
        return ((false) as NSNumber?, nil)
    }

    public func startScanBluetooth(completion: @escaping (FlutterError?) -> Void) {
        bluetoothScanner?.scan()
        completion(nil)
    }
    
    public func startScanWifi(completion: @escaping (FlutterError?) -> Void) {
        // wifi not used on ios so far
        completion(FlutterError.init(code: "unimplemented", message: "Wi-Fi is not available on iOS", details: nil))
    }
    
    public func stopScanBluetooth(completion: @escaping (FlutterError?) -> Void) {
        bluetoothScanner?.cancel()
        completion(nil)
    }
    
    public func stopScanWifi(completion: @escaping (FlutterError?) -> Void) {
        // wifi not used on ios so far
        completion(FlutterError.init(code: "unimplemented", message: "Wi-Fi is not available on iOS", details: nil))
    }
    
    public func setBtScanPriorityPriority(_ priority: DTGScanPriority) async -> FlutterError? {
        bluetoothScanner.setScanPriority(priority: priority)
        return nil
    }
    
    public func isScanningBluetooth() async -> (NSNumber?, FlutterError?) {
        return ((bluetoothScanner?.isScanning()) as NSNumber?, nil)
    }
    
    public func isScanningWifi() async -> (NSNumber?, FlutterError?) {
        return (false as NSNumber?, nil)
    }
    
    public func bluetoothState() async -> (NSNumber?, FlutterError?) {
        return ((bluetoothScanner?.managerState()) as NSNumber?, nil)
    }

    public func wifiState() async -> (NSNumber?, FlutterError?) {
        return ((DTGWifiState.disabled.rawValue) as NSNumber?, nil)
    }
}
