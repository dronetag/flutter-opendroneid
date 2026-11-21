import Flutter
import UIKit

public class SwiftFlutterOpendroneidPlugin: NSObject, FlutterPlugin, OdidScannerHostApi {
    private let registrar: FlutterPluginRegistrar
    private let sink: FlutterApiSink

    private var bluetoothScanner: BluetoothScanner?

    init(registrar: FlutterPluginRegistrar) {
        self.registrar = registrar
        self.sink = FlutterApiSink(registrar: registrar)
        super.init()
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = SwiftFlutterOpendroneidPlugin(registrar: registrar)
        registrar.publish(instance)
        OdidScannerHostApiSetup.register(api: instance, registrar: registrar)
    }

    public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
        OdidScannerHostApiSetup.unregister(api: self, registrar: registrar)
    }

    func initialize() throws {
        bluetoothScanner = BluetoothScanner(sink: sink)
    }

    func isInitialized() throws -> Bool {
        return bluetoothScanner != nil
    }

    func btMaxAdvDataLen() throws -> Int64 {
        return 0
    }

    func btExtendedSupported() throws -> Bool {
        return false
    }

    func wifiNaNSupported() throws -> Bool {
        return false
    }

    func startScanBluetooth(serviceUuid: String?) throws {
        guard let scanner = bluetoothScanner else {
            throw notInitialized()
        }

        scanner.setServiceUuid(value: serviceUuid)
        scanner.scan()
    }

    func startScanWifi() throws {
        // wifi not used on ios so far
        throw wifiUnavailable()
    }

    func stopScanBluetooth() throws {
        bluetoothScanner?.cancel()
    }

    func stopScanWifi() throws {
        // wifi not used on ios so far
        throw wifiUnavailable()
    }

    func setBtScanPriority(priority: ScanPriority) throws {
        guard let scanner = bluetoothScanner else {
            throw notInitialized()
        }
        scanner.setScanPriority(priority: priority)
    }

    func setBtServiceUuid(serviceUuid: String?) throws {
        guard let scanner = bluetoothScanner else {
            throw notInitialized()
        }
        scanner.setServiceUuid(value: serviceUuid)
    }

    func isScanningBluetooth() throws -> Bool {
        guard let scanner = bluetoothScanner else {
            throw notInitialized()
        }
        return scanner.isScanning()
    }

    func isScanningWifi() throws -> Bool {
        return false
    }

    func bluetoothState() async throws -> Int64 {
        guard let scanner = bluetoothScanner else {
            throw notInitialized()
        }
        return Int64(await scanner.managerState())
    }

    func wifiState() throws -> Int64 {
        return Int64(WifiState.disabled.rawValue)
    }

    private func notInitialized() -> PigeonError {
        return PigeonError(
            code: "uninitialized",
            message: "Plugin was not initialized",
            details: "Call the initialize method before using the plugin"
        )
    }

    private func wifiUnavailable() -> PigeonError {
        return PigeonError(
            code: "unimplemented",
            message: "Wi-Fi is not available on iOS",
            details: nil
        )
    }
}
