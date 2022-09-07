import Flutter
import UIKit

@available(iOS 13.0.0, *)
public class SwiftFlutterOpendroneidPlugin: NSObject, FlutterPlugin, DTGApi{
    private var bluetoothScanner: BluetoothScanner!
    
    private let locationMessagesStreamHandler = StreamHandler()
    private let operatoridMessagesStreamHandler = StreamHandler()
    private let basicMessagesStreamHandler = StreamHandler()
    private let authMessagesStreamHandler = StreamHandler()
    private let selfidMessagesStreamHandler = StreamHandler()
    private let systemMessagesStreamHandler = StreamHandler()
    private let bluetoothStateStreamHandler = StreamHandler()
    private let wifiStateStreamHandler = StreamHandler()
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let messenger : FlutterBinaryMessenger = registrar.messenger()
        let instance : SwiftFlutterOpendroneidPlugin & DTGApi & NSObjectProtocol = SwiftFlutterOpendroneidPlugin.init()
        DTGApiSetup(messenger, instance);
        
        //let instance = SwiftFlutterOpendroneidPlugin()
        
        // Event channels
        FlutterEventChannel(name: "flutter_location_messages", binaryMessenger: registrar.messenger()).setStreamHandler(instance.locationMessagesStreamHandler)
        FlutterEventChannel(name: "flutter_operatorid_messages", binaryMessenger: registrar.messenger()).setStreamHandler(instance.operatoridMessagesStreamHandler)
        FlutterEventChannel(name: "flutter_basic_messages", binaryMessenger: registrar.messenger()).setStreamHandler(instance.basicMessagesStreamHandler)
        FlutterEventChannel(name: "flutter_system_messages", binaryMessenger: registrar.messenger()).setStreamHandler(instance.systemMessagesStreamHandler)
        FlutterEventChannel(name: "flutter_selfid_messages", binaryMessenger: registrar.messenger()).setStreamHandler(instance.selfidMessagesStreamHandler)
        FlutterEventChannel(name: "flutter_auth_messages", binaryMessenger: registrar.messenger()).setStreamHandler(instance.authMessagesStreamHandler)
        FlutterEventChannel(name: "flutter_odid_bt_state", binaryMessenger: registrar.messenger()).setStreamHandler(instance.bluetoothStateStreamHandler)
        FlutterEventChannel(name: "flutter_odid_wifi_state", binaryMessenger: registrar.messenger()).setStreamHandler(instance.wifiStateStreamHandler)
        
        // Register bluetooth scanner
        instance.bluetoothScanner = BluetoothScanner(
            basicMessageHandler: instance.basicMessagesStreamHandler,
            locationMessageHandler: instance.locationMessagesStreamHandler,
            operatoridMessageHandler: instance.operatoridMessagesStreamHandler,
            authMessageHandler: instance.authMessagesStreamHandler,
            systemMessageHandler: instance.systemMessagesStreamHandler,
            selfidMessageHandler: instance.selfidMessagesStreamHandler,
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
    }
    
    public func startScanWifi(completion: @escaping (FlutterError?) -> Void) {
        // wifi not used on ios so far
    }
    
    public func stopScanBluetooth(completion: @escaping (FlutterError?) -> Void) {
        bluetoothScanner?.cancel()
    }
    
    public func stopScanWifi(completion: @escaping (FlutterError?) -> Void) {
        // wifi not used on ios so far
    }
    
    public func setAutorestartBluetooth(_ enable: NSNumber?) async -> FlutterError? {
        bluetoothScanner?.autoRestart = enable as! Bool
        return nil
    }
    
    public func setAutorestartBluetoothEnable(_ enable: NSNumber?, completion: @escaping (FlutterError?) -> Void) {
        bluetoothScanner?.autoRestart = enable as! Bool
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
}
