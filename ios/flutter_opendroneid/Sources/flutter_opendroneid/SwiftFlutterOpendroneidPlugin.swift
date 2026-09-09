import Flutter
import UIKit

@available(iOS 13.0.0, *)
public class SwiftFlutterOpendroneidPlugin: NSObject, FlutterPlugin, Api {
    private var bluetoothScanner: BluetoothScanner?

    private let bluetoothOdidPayloadStreamHandler = BluetoothOdidPayloadStreamHandler()
    private let bluetoothStateStreamHandler = BluetoothStateStreamHandler()

    public static func register(with registrar: FlutterPluginRegistrar) {
        let messenger: FlutterBinaryMessenger = registrar.messenger()
        let instance = SwiftFlutterOpendroneidPlugin()
        ApiSetup.setUp(binaryMessenger: messenger, api: instance)

        StreamOdidPayloadBtStreamHandler.register(
            with: messenger, streamHandler: instance.bluetoothOdidPayloadStreamHandler
        )
        StreamBluetoothStateStreamHandler.register(
            with: messenger, streamHandler: instance.bluetoothStateStreamHandler
        )

        registrar.addApplicationDelegate(instance)
    }

    public func applicationWillTerminate(_ application: UIApplication) {
        bluetoothScanner?.cancel()
    }

    public func initialize(completion: @escaping (Result<Void, Error>) -> Void) {
        bluetoothScanner = BluetoothScanner(
            odidPayloadStreamHandler: bluetoothOdidPayloadStreamHandler,
            scanStateHandler: bluetoothStateStreamHandler
        )
        completion(.success(()))
    }

    public func isInitialized(completion: @escaping (Result<Bool, Error>) -> Void) {
        completion(.success(bluetoothScanner != nil))
    }

    public func btMaxAdvDataLen(completion: @escaping (Result<Int64, Error>) -> Void) {
        completion(.success(0))
    }

    public func btExtendedSupported(completion: @escaping (Result<Bool, Error>) -> Void) {
        completion(.success(false))
    }

    public func wifiNaNSupported(completion: @escaping (Result<Bool, Error>) -> Void) {
        completion(.success(false))
    }

    public func startScanBluetooth(serviceUuid: String?, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let scanner = bluetoothScanner else {
            return completion(.failure(PluginNotInitializedException()))
        }

        scanner.setServiceUuid(value: serviceUuid)
        scanner.scan()
        completion(.success(()))
    }

    public func startScanWifi(completion: @escaping (Result<Void, Error>) -> Void) {
        // wifi not used on ios so far
        completion(.failure(FlutterError(code: "unimplemented", message: "Wi-Fi is not available on iOS", details: nil)))
    }

    public func stopScanBluetooth(completion: @escaping (Result<Void, Error>) -> Void) {
        bluetoothScanner?.cancel()
        completion(.success(()))
    }

    public func stopScanWifi(completion: @escaping (Result<Void, Error>) -> Void) {
        // wifi not used on ios so far
        completion(.failure(FlutterError(code: "unimplemented", message: "Wi-Fi is not available on iOS", details: nil)))
    }

    public func setBtScanPriority(priority: ScanPriority, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let scanner = bluetoothScanner else {
            return completion(.failure(PluginNotInitializedException()))
        }
        scanner.setScanPriority(priority: priority)
        completion(.success(()))
    }

    public func setBtServiceUuid(serviceUuid: String?, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let scanner = bluetoothScanner else {
            return completion(.failure(PluginNotInitializedException()))
        }
        scanner.setServiceUuid(value: serviceUuid)
        completion(.success(()))
    }

    public func isScanningBluetooth(completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let scanner = bluetoothScanner else {
            return completion(.failure(PluginNotInitializedException()))
        }
        completion(.success(scanner.isScanning()))
    }

    public func isScanningWifi(completion: @escaping (Result<Bool, Error>) -> Void) {
        completion(.success(false))
    }

    public func bluetoothState(completion: @escaping (Result<Int64, Error>) -> Void) {
        guard let scanner = bluetoothScanner else {
            return completion(.failure(PluginNotInitializedException()))
        }
        Task {
            completion(.success(Int64(await scanner.managerState())))
        }
    }

    public func wifiState(completion: @escaping (Result<Int64, Error>) -> Void) {
        completion(.success(Int64(WifiState.disabled.rawValue)))
    }
}
