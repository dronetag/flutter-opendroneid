import Foundation
import CoreBluetooth

class BluetoothScanner: NSObject, CBCentralManagerDelegate, DTGPayloadApi {
    static let defaultShortServiceUuid = "fffa"

    private let odidPayloadStreamHandler: StreamHandler
    private let scanStateHandler: StreamHandler
    
    private var centralManager: CBCentralManager!
    private var scanPriority: DTGScanPriority = .high
    private var restartTimer: Timer?;
    private let restartIntervalSec: TimeInterval = 120.0
    private var shortServiceUuid: String? = nil
    let dispatchQueue: DispatchQueue = DispatchQueue(label: "BluetoothScanner")
    
    private var serviceUUID: CBUUID {
        get {
            let shortUuid = shortServiceUuid ?? BluetoothScanner.defaultShortServiceUuid
            return CBUUID(string: "0000\(shortUuid.lowercased())-0000-1000-8000-00805f9b34fb")
        }
    }
    static let odidAdCode: [UInt8] = [ 0x0D ]
    
    init(odidPayloadStreamHandler: StreamHandler, scanStateHandler: StreamHandler) {
        self.odidPayloadStreamHandler = odidPayloadStreamHandler
        self.scanStateHandler = scanStateHandler
        
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
    
    func setScanPriority(priority: DTGScanPriority)
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
        scanStateHandler.send(centralManager.isScanning)
    }

    func managerState() -> Int{
        return centralManager.state.rawValue
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
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
    
    func buildPayloadRawData(_ rawData: FlutterStandardTypedData, receivedTimestamp receivedTimestamp: NSNumber, metadata: DTGODIDMetadata, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) -> DTGODIDPayload? {
        return DTGODIDPayload.make(withRawData: rawData, receivedTimestamp: receivedTimestamp ,metadata: metadata)
    }

    private func handleOdidMessage(advertisementData: [String : Any], didDiscover peripheral: CBPeripheral, rssi RSSI: NSNumber, offset: NSNumber){
        guard let data = getOdidData(from: advertisementData, offset: offset) else {
            // This advertisement is not an ODID ad data
            return
        }
        var err: FlutterError?
        let systimestamp = Int(Date().timeIntervalSince1970 * 1000)
        let metadata = DTGODIDMetadata.make(withMacAddress: peripheral.identifier.uuidString, source: DTGMessageSource.bluetoothLegacy, rssi: RSSI.intValue as NSNumber, btName:  peripheral.name, frequency: nil, centerFreq0: nil, centerFreq1: nil, channelWidthMhz: nil, primaryPhy: DTGBluetoothPhy.unknown, secondaryPhy: DTGBluetoothPhy.unknown)
        let payload = buildPayloadRawData(data, receivedTimestamp: systimestamp as NSNumber , metadata: metadata , error: &err)

        odidPayloadStreamHandler.send(payload!.toList() as Any)
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
