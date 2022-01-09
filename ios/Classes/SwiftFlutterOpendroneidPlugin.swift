import Flutter
import UIKit

public class SwiftFlutterOpendroneidPlugin: NSObject, FlutterPlugin {
    private var bluetoothScanner: BluetoothScanner? = nil
    
    private let messagesStreamHandler = StreamHandler()
    private let bluetoothStateStreamHandler = StreamHandler()
    private let scanStateStreamHandler = StreamHandler()
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        // Method channel
        let channel = FlutterMethodChannel(name: "flutter_odid", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterOpendroneidPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        
        // Event channels
        FlutterEventChannel(name: "flutter_odid_messages", binaryMessenger: registrar.messenger()).setStreamHandler(instance.messagesStreamHandler)
        FlutterEventChannel(name: "flutter_odid_bt_state", binaryMessenger: registrar.messenger()).setStreamHandler(instance.bluetoothStateStreamHandler)
        FlutterEventChannel(name: "flutter_odid_scan_state", binaryMessenger: registrar.messenger()).setStreamHandler(instance.scanStateStreamHandler)
        
        // Register bluetooth scanner
        instance.bluetoothScanner = BluetoothScanner(
            messageHandler: instance.messagesStreamHandler,
            stateHandler: instance.bluetoothStateStreamHandler,
            scanStateHandler: instance.scanStateStreamHandler
        )
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = call.arguments as? Dictionary<String, AnyObject> ?? [:]
        
        switch call.method {
        case "start_scan":
            startScan(result)
        case "stop_scan":
            stopScan(result)
        case "is_scanning":
            result(bluetoothScanner?.isScanning())
        case "bluetooth_state":
            result(bluetoothScanner?.centralManager.state.rawValue)
        case "set_autorestart":
            bluetoothScanner?.autoRestart = arguments["enable"] as! Bool
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    func startScan(_ result: @escaping FlutterResult) -> Void {
        bluetoothScanner?.scan()
    }
    
    func stopScan(_ result: @escaping FlutterResult) -> Void {
        bluetoothScanner?.cancel()
    }
}
