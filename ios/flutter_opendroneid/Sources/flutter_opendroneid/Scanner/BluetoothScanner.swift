import CoreBluetooth
import Flutter
import Foundation

/// Scans Bluetooth LE advertisements for ODID service data.
///
/// CoreBluetooth callbacks run on [dispatchQueue]; [sink] is responsible for
/// hopping to the main queue before calling into Dart.
class BluetoothScanner: NSObject, CBCentralManagerDelegate {
    static let defaultShortServiceUuid = "fffa"

    private let sink: OdidSink
    
    private var centralManager: CBCentralManager!
    private var scanPriority: ScanPriority = .high
    private var restartTimer: Timer?;
    private let restartIntervalSec: TimeInterval = 120.0
    private var shortServiceUuid: String? = nil
    private var managerStateContinuation: CheckedContinuation<Int, Never>?

    let dispatchQueue: DispatchQueue = DispatchQueue(label: "BluetoothScanner")
    
    private var serviceUUID: CBUUID {
        get {
            let shortUuid = shortServiceUuid ?? BluetoothScanner.defaultShortServiceUuid
            return CBUUID(string: "0000\(shortUuid.lowercased())-0000-1000-8000-00805f9b34fb")
        }
    }
    static let odidAdCode: [UInt8] = [ 0x0D ]
    
    init(sink: OdidSink) {
        self.sink = sink
        
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: dispatchQueue)
    }
    
    func scan() {
        if centralManager.isScanning == true { 
            updateScanState()
            return
        }
        guard centralManager.state == .poweredOn else {
            updateScanState()
            scanWhenPoweredOn()
            return
        }
        
        scanForPeripherals()
        initRestartTimer()
        updateScanState()
    }
    
    func isScanning() -> Bool {
        return centralManager.isScanning
    }
    
    func cancel() {
        centralManager.stopScan()
        if let timer = restartTimer {
            timer.invalidate()
        }
        updateScanState()
    }
    
    func setScanPriority(priority: ScanPriority)
    {
        scanPriority = priority
        restartScan()
    }

    func setServiceUuid(value: String?) {
        if value != nil && (value!.count != 4 || !value!.isHexNumber) {
            // TODO return error on invalid service UUID
            return
        }

        shortServiceUuid = value
        restartScan()
    }

    func updateScanState() {
        sink.onBluetoothScanActive(centralManager.isScanning)
    }

    /// Current CoreBluetooth state, waiting for the first update when the
    /// manager is still `.unknown`.
    func managerState() async -> Int {
        if centralManager.state != .unknown {
            return centralManager.state.rawValue
        }

        // If state is .unknown, wait for update of CBCentralManager state
        return await withCheckedContinuation { continuation in
            self.managerStateContinuation = continuation
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if let continuation = managerStateContinuation {
            managerStateContinuation = nil
            continuation.resume(returning: central.state.rawValue)
        }
        updateScanState()
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        handleOdidMessage(advertisementData: advertisementData, didDiscover: peripheral, rssi: RSSI, offset: 2)
    }

    private func scanForPeripherals(){
        centralManager.scanForPeripherals(
            withServices: [serviceUUID],
            options: [
                CBCentralManagerScanOptionAllowDuplicatesKey: true,
            ]
        )    
    }
    
    private func handleOdidMessage(advertisementData: [String : Any], didDiscover peripheral: CBPeripheral, rssi RSSI: NSNumber, offset: NSNumber){
        guard let data = getOdidData(from: advertisementData, offset: offset) else {
            // This advertisement is not an ODID ad data
            return
        }
        let systimestamp = Int64(Date().timeIntervalSince1970 * 1000)
        let metadata = ODIDMetadata(
            macAddress: peripheral.identifier.uuidString,
            source: .bluetoothLegacy,
            rssi: Int64(RSSI.intValue),
            btName: peripheral.name,
            primaryPhy: .unknown,
            secondaryPhy: .unknown
        )
        let payload = ODIDPayload(
            rawData: [UInt8](data.data),
            receivedTimestamp: systimestamp,
            metadata: metadata
        )

        sink.onPayload(payload)
    }
    
    private func getOdidData(from advertisementData: [String : Any], offset: NSNumber) -> FlutterStandardTypedData? {
        // Peripheral must have service data
        guard let serviceData = advertisementData["kCBAdvDataServiceData"] else {
            return nil
        }
    
        let serviceDataDict = serviceData as! Dictionary<CBUUID, Any>
        
        // Find the ODID service UUID
        guard serviceDataDict.keys.contains(serviceUUID) else {
            return nil
        }
        
        let data = serviceDataDict[serviceUUID] as! Data
        // offset data
        let dataF = FlutterStandardTypedData(bytes: data.dropFirst(offset.intValue))
        // All data must start with 0x0D
        guard data.starts(with: BluetoothScanner.odidAdCode) else {
            return nil
        }
        return dataF
    }

    // Restarts scanning if it was running, depending on current priority
    private func restartScan() {
        // if scan is running when settting high prio, call scan to restart and set timer
        // if scan is running when setting low prio, just cancel restart timer
        if centralManager.isScanning {
            if scanPriority == .low {
                restartTimer?.invalidate()
            }
            else {
                centralManager.stopScan()
                scan()
            }
        }
    }

    private func initRestartTimer() {
        if scanPriority == .high {
            restartTimer = Timer.scheduledTimer(withTimeInterval: restartIntervalSec, repeats: true) { timer in
                self.centralManager.stopScan()
                self.scanForPeripherals()
            }
        }
    }
    
    /// Wait for 0.5 sec and then start scan if centralManager is in .poweredOn state.
    private func scanWhenPoweredOn() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            
            if self.centralManager.state == .poweredOn {
                self.scanForPeripherals()
                self.initRestartTimer()
                self.updateScanState()
                return
            }
        }
    }
}
