import Flutter
import UIKit

@available(iOS 15.0.0, *)
public class SwiftFlutterOpendroneidPlugin: NSObject, FlutterPlugin, DTGApi{
    
    public func startScan(completion: @escaping (FlutterError?) -> Void) {
        bluetoothScanner?.scan()
        wifiScanner?.scan()
    }
    
    public func stopScan(completion: @escaping (FlutterError?) -> Void) {
        bluetoothScanner?.cancel()
        wifiScanner?.cancel()
    }
    
    public func setAutorestartEnable(_ enable: NSNumber?) async -> FlutterError? {
        bluetoothScanner?.autoRestart = enable as! Bool
        return nil
    }
    
    public func isScanning() async -> (NSNumber?, FlutterError?) {
        return ((bluetoothScanner?.isScanning()) as NSNumber?, nil)
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
        let instance = SwiftFlutterOpendroneidPlugin()
        
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

        // Register bluetooth scanner
        instance.wifiScanner = WifiScanner(
            messageHandler: instance.messagesStreamHandler,
            stateHandler: instance.bluetoothStateStreamHandler
        )
    }
}
