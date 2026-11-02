import Flutter
import UIKit

@available(iOS 13.0.0, *)
public class SwiftFlutterOpendroneidPlugin: NSObject, FlutterPlugin, Api {
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
        let instance = SwiftFlutterOpendroneidPlugin()
        ApiSetup.setUp(binaryMessenger: messenger, api: instance)
        
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

    func initialize(completion: @escaping (Result<Void, Error>) -> Void) {
        // Register bluetooth scanner
        bluetoothScanner = BluetoothScanner(
            odidPayloadStreamHandler: streamHandlers[SwiftFlutterOpendroneidPlugin.dataEventChannelName]!,
            scanStateHandler: streamHandlers[SwiftFlutterOpendroneidPlugin.stateEventChannelName]!
        )
        completion(.success(()))
    }
    
    func isInitialized(completion: @escaping (Result<Bool, Error>) -> Void) {
        completion(.success(bluetoothScanner != nil))
    }

    func btMaxAdvDataLen(completion: @escaping (Result<Int64, Error>) -> Void) {
        completion(.success(0))
    }
    
    func btExtendedSupported(completion: @escaping (Result<Bool, Error>) -> Void) {
        completion(.success(false))
    }
    
    func wifiNaNSupported(completion: @escaping (Result<Bool, Error>) -> Void) {
        completion(.success(false))
    }

    func startScanBluetooth(serviceUuid: String?, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let scanner = bluetoothScanner else {
            return completion(.failure(PluginNotInitializedException()))
        }

        scanner.setServiceUuid(value: serviceUuid)
        scanner.scan()
        completion(.success(()))
    }
    
    func startScanWifi(completion: @escaping (Result<Void, Error>) -> Void) {
        // wifi not used on ios so far
        completion(.failure(FlutterError(code: "unimplemented", message: "Wi-Fi is not available on iOS", details: nil)))
    }
    
    func stopScanBluetooth(completion: @escaping (Result<Void, Error>) -> Void) {
        bluetoothScanner?.cancel()
        completion(.success(()))
    }
    
    func stopScanWifi(completion: @escaping (Result<Void, Error>) -> Void) {
        // wifi not used on ios so far
        completion(.failure(FlutterError(code: "unimplemented", message: "Wi-Fi is not available on iOS", details: nil)))
    }
    
    func setBtScanPriority(priority: ScanPriority, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let scanner = bluetoothScanner else {
            return completion(.failure(PluginNotInitializedException()))
        }
        scanner.setScanPriority(priority: priority)
        completion(.success(()))
    }

    func setBtServiceUuid(serviceUuid: String?, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let scanner = bluetoothScanner else {
            return completion(.failure(PluginNotInitializedException()))
        }
        scanner.setServiceUuid(value: serviceUuid)
        completion(.success(()))
    }
    
    func isScanningBluetooth(completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let scanner = bluetoothScanner else {
            return completion(.failure(PluginNotInitializedException()))
        }
        completion(.success(scanner.isScanning()))
    }
    
    func isScanningWifi(completion: @escaping (Result<Bool, Error>) -> Void) {
        completion(.success(false))
    }
    
    func bluetoothState(completion: @escaping (Result<Int64, Error>) -> Void) {
        guard let scanner = bluetoothScanner else {
            return completion(.failure(PluginNotInitializedException()))
        }
        Task {
            completion(.success(Int64(await scanner.managerState())))
        }
    }

    func wifiState(completion: @escaping (Result<Int64, Error>) -> Void) {
        completion(.success(Int64(WifiState.disabled.rawValue)))
    }
}
