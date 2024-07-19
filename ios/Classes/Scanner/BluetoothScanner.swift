import Foundation
import CoreBluetooth

class BluetoothScanner: NSObject, CBCentralManagerDelegate, DTGPayloadApi {
    private let odidPayloadStreamHandler: StreamHandler
    private let scanStateHandler: StreamHandler
    
    private var centralManager: CBCentralManager!
    private var scanPriority: DTGScanPriority = .high
    private var restartTimer: Timer?;
    private let restartIntervalSec: TimeInterval = 120.0
    let dispatchQueue: DispatchQueue = DispatchQueue(label: "BluetoothScanner")
    
    static let serviceUUID = CBUUID(string: "0000fffa-0000-1000-8000-00805f9b34fb")
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
            return
        }
        
        scanForPeripherals()
        if scanPriority == .high {
            restartTimer = Timer.scheduledTimer(withTimeInterval: restartIntervalSec, repeats: true) { timer in
                self.centralManager.stopScan()
                self.scanForPeripherals()
            }
        }
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
            withServices: [BluetoothScanner.serviceUUID],
            options: [
                CBCentralManagerScanOptionAllowDuplicatesKey: true,
            ]
        )    
    }
    
    func buildPayloadRawData(_ rawData: FlutterStandardTypedData, source: DTGMessageSource, macAddress: String, btName: String?, rssi: NSNumber, receivedTimestamp: NSNumber, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) -> DTGODIDPayload? {
        return DTGODIDPayload.make(withRawData: rawData, receivedTimestamp: receivedTimestamp, macAddress: macAddress, rssi: rssi, source: source, btName: btName)
    }

    private func handleOdidMessage(advertisementData: [String : Any], didDiscover peripheral: CBPeripheral, rssi RSSI: NSNumber, offset: NSNumber){
        guard let data = getOdidData(from: advertisementData, offset: offset) else {
            // This advertisement is not an ODID ad data
            return
        }
        var err: FlutterError?
        let systimestamp = Int(Date().timeIntervalSince1970 * 1000)
        let payload = buildPayloadRawData(data, source: DTGMessageSource.bluetoothLegacy, macAddress: peripheral.identifier.uuidString, btName: peripheral.name, rssi: RSSI.intValue as NSNumber, receivedTimestamp: systimestamp as NSNumber, error: &err)

        odidPayloadStreamHandler.send(payload!.toList() as Any)
    }
    
    private func getOdidData(from advertisementData: [String : Any], offset: NSNumber) -> FlutterStandardTypedData? {
        // Peripheral must have service data
        guard let serviceData = advertisementData["kCBAdvDataServiceData"] else {
            return nil
        }
    
        let serviceDataDict = serviceData as! Dictionary<CBUUID, Any>
        
        // Find the ODID service UUID
        guard serviceDataDict.keys.contains(BluetoothScanner.serviceUUID) else {
            return nil
        }
        
        let data = serviceDataDict[BluetoothScanner.serviceUUID] as! Data
        // offset data
        let dataF = FlutterStandardTypedData(bytes: data.dropFirst(offset.intValue))
        // All data must start with 0x0D
        guard data.starts(with: BluetoothScanner.odidAdCode) else {
            return nil
        }
        return dataF
    }
}
