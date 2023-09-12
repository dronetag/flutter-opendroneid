import Flutter
import UIKit

@available(iOS 13.0.0, *)
public class SwiftFlutterOpendroneidPlugin: NSObject, FlutterPlugin, DTGApi{

    private var bluetoothScanner: BluetoothScanner!
    
    private let odidPayloadStreamHandler = StreamHandler()
    private let bluetoothStateStreamHandler = StreamHandler()
    private let wifiStateStreamHandler = StreamHandler()
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let messenger : FlutterBinaryMessenger = registrar.messenger()
        let instance : SwiftFlutterOpendroneidPlugin & DTGApi & NSObjectProtocol = SwiftFlutterOpendroneidPlugin.init()
        DTGApiSetup(messenger, instance);
        
        // Event channels
        FlutterEventChannel(name: "flutter_odid_data", binaryMessenger: registrar.messenger()).setStreamHandler(instance.odidPayloadStreamHandler)
        FlutterEventChannel(name: "flutter_odid_bt_state", binaryMessenger: registrar.messenger()).setStreamHandler(instance.bluetoothStateStreamHandler)
        FlutterEventChannel(name: "flutter_odid_wifi_state", binaryMessenger: registrar.messenger()).setStreamHandler(instance.wifiStateStreamHandler)
        
        // Register bluetooth scanner
        instance.bluetoothScanner = BluetoothScanner(
            odidPayloadStreamHandler: instance.odidPayloadStreamHandler,
            scanStateHandler: instance.bluetoothStateStreamHandler
        )
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
