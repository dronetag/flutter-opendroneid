import Flutter
import UIKit

public class SwiftFlutterOpendroneidPlugin: NSObject, FlutterPlugin {
    var isScanning = false
    
    private var bluetoothScanner: BluetoothScanner? = nil
    
    private let messagesStreamHandler = StreamHandler()
    private let bluetoothStateStreamHandler = StreamHandler()
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        // Method channel
        let channel = FlutterMethodChannel(name: "flutter_odid", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterOpendroneidPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        
        // Event channels
        FlutterEventChannel(name: "flutter_odid_messages", binaryMessenger: registrar.messenger()).setStreamHandler(instance.messagesStreamHandler)
        FlutterEventChannel(name: "flutter_odid_bt_state", binaryMessenger: registrar.messenger()).setStreamHandler(instance.bluetoothStateStreamHandler)
        
        // Register bluetooth scanner
        instance.bluetoothScanner = BluetoothScanner(
            messageHandler: instance.messagesStreamHandler,
            stateHandler: instance.bluetoothStateStreamHandler
        )
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        NSLog(call.method)
        switch call.method {
        case "start_scan":
            startScan(result)
        case "stop_scan":
            stopScan(result)
        case "is_scanning":
            result(isScanning)
        case "bluetooth_state":
            result(bluetoothScanner?.centralManager.state.rawValue)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    func startScan(_ result: @escaping FlutterResult) -> Void {
        isScanning = true
        bluetoothScanner?.scan()
    }
    
    func stopScan(_ result: @escaping FlutterResult) -> Void {
        isScanning = false
        bluetoothScanner?.cancel()
    }
}
