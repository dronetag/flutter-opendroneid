import Flutter
import UIKit

@available(iOS 13.0.0, *)
public class SwiftFlutterOpendroneidPlugin: NSObject, FlutterPlugin, DTGApi{
    private static let dataEventChannelName = "flutter_odid_data_bt"
    private static let stateEventChannelName = "flutter_odid_state_bt"
    private static var eventChannels: [String: FlutterEventChannel] = [:]

    private var bluetoothScanner: BluetoothScanner?

    private let streamHandlers: [String: StreamHandler] = [
        dataEventChannelName: StreamHandler(),
        stateEventChannelName: StreamHandler(),
    ]
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let messenger : FlutterBinaryMessenger = registrar.messenger()
        let instance : SwiftFlutterOpendroneidPlugin & DTGApi & NSObjectProtocol = SwiftFlutterOpendroneidPlugin.init()
        DTGApiSetup(messenger, instance);
        
        // Register event channels
        eventChannels = [
            dataEventChannelName: FlutterEventChannel(name: dataEventChannelName, binaryMessenger: registrar.messenger()),
            stateEventChannelName: FlutterEventChannel(name: stateEventChannelName, binaryMessenger: registrar.messenger()),
        ]
        
        // Register stream handlers
        for entry in SwiftFlutterOpendroneidPlugin.eventChannels {
            entry.value.setStreamHandler(
                instance.streamHandlers[entry.key]
            )
        }
    
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

    public func initialize(completion: @escaping (FlutterError?) -> Void) {
        // Register bluetooth scanner
        bluetoothScanner = BluetoothScanner(
            odidPayloadStreamHandler: streamHandlers[SwiftFlutterOpendroneidPlugin.dataEventChannelName]!,
            scanStateHandler: streamHandlers[SwiftFlutterOpendroneidPlugin.stateEventChannelName]!
        )
        completion(nil)
    }
    
    public func isInitialized(completion: @escaping (NSNumber?, FlutterError?) -> Void) {
        completion((bluetoothScanner != nil) as NSNumber?, nil)
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

    public func startScanBluetoothServiceUuid(_ serviceUuid: String?, completion: @escaping (FlutterError?) -> Void) {
        guard let scanner = bluetoothScanner else {
            return completion(PluginNotInitializedException.init())
        }

        scanner.setServiceUuid(value: serviceUuid)
        scanner.scan()
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
        guard let scanner = bluetoothScanner else {
            return PluginNotInitializedException.init()
        }
        scanner.setScanPriority(priority: priority)
        return nil
    }
    
    public func isScanningBluetooth() async -> (NSNumber?, FlutterError?) {
        guard let scanner = bluetoothScanner else {
            return (nil, PluginNotInitializedException.init())
        }
        return ((scanner.isScanning()) as NSNumber?, nil)
    }
    
    public func isScanningWifi() async -> (NSNumber?, FlutterError?) {
        return (false as NSNumber?, nil)
    }
    
    public func bluetoothState() async -> (NSNumber?, FlutterError?) {
        guard let scanner = bluetoothScanner else {
            return (nil, PluginNotInitializedException())
        }
        return ((scanner.managerState()) as NSNumber?, nil)
    }

    public func wifiState() async -> (NSNumber?, FlutterError?) {
        return ((DTGWifiState.disabled.rawValue) as NSNumber?, nil)
    }
}
