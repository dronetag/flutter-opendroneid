import Flutter
import UIKit

@available(iOS 15.0.0, *)
public class SwiftFlutterOpendroneidPlugin: NSObject, FlutterPlugin, DTGApi{

    public func startScanBluetooth(completion: @escaping (FlutterError?) -> Void) {
        NSLog("Start Scan BT")
        bluetoothScanner?.scan()
    }
    
    public func startScanWifi(completion: @escaping (FlutterError?) -> Void) {
        NSLog("Start Scan WiFi")
        wifiScanner?.scan()
    }
    
    public func stopScanBluetooth(completion: @escaping (FlutterError?) -> Void) {
        NSLog("Stop Scan BT")
        bluetoothScanner?.cancel()
    }
    
    public func stopScanWifi(completion: @escaping (FlutterError?) -> Void) {
        NSLog("Stop Scan WiFi")
        wifiScanner?.cancel()
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
        return ((wifiScanner?.isScanning()) as NSNumber?, nil)
    }
    
    public func bluetoothState() async -> (NSNumber?, FlutterError?) {
        return ((bluetoothScanner?.centralManager.state.rawValue) as NSNumber?, nil)
    }
    
    private var bluetoothScanner: BluetoothScanner? = nil
    private var wifiScanner: WifiScanner? = nil
    
    private let locationMessagesStreamHandler = StreamHandler()
    private let operatoridMessagesStreamHandler = StreamHandler()
    private let basicMessagesStreamHandler = StreamHandler()
    private let bluetoothStateStreamHandler = StreamHandler()
    private let scanStateStreamHandler = StreamHandler()
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
        FlutterEventChannel(name: "flutter_odid_bt_state", binaryMessenger: registrar.messenger()).setStreamHandler(instance.bluetoothStateStreamHandler)
        FlutterEventChannel(name: "flutter_odid_scan_state", binaryMessenger: registrar.messenger()).setStreamHandler(instance.scanStateStreamHandler)
        
        // Register bluetooth scanner
        instance.bluetoothScanner = BluetoothScanner(
            basicMessageHandler: instance.basicMessagesStreamHandler,
            locationMessageHandler: instance.locationMessagesStreamHandler,
            operatoridMessageHandler: instance.operatoridMessagesStreamHandler,
            stateHandler: instance.bluetoothStateStreamHandler,
            scanStateHandler: instance.scanStateStreamHandler
        )

        // Register wifi scanner
        instance.wifiScanner = WifiScanner(
            messageHandler: instance.basicMessagesStreamHandler,
            stateHandler: instance.bluetoothStateStreamHandler
        )
    }
}
