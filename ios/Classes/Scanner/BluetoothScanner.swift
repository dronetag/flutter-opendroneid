import Foundation
import CoreBluetooth

class BluetoothScanner: NSObject, CBCentralManagerDelegate {
    private let operatoridMessageHandler: StreamHandler
    private let basicMessageHandler: StreamHandler
    private let locationMessageHandler: StreamHandler
    private let stateHandler: StreamHandler
    private let scanStateHandler: StreamHandler
    private let dataParser: OdidParser
    
    var centralManager: CBCentralManager
    var autoRestart: Bool = false
    let dispatchQueue: DispatchQueue = DispatchQueue(label: "BluetoothScanner")
    
    static let serviceUUID = CBUUID(string: "0000fffa-0000-1000-8000-00805f9b34fb")
    
    init(basicMessageHandler: StreamHandler, locationMessageHandler: StreamHandler, operatoridMessageHandler: StreamHandler,  stateHandler: StreamHandler, scanStateHandler: StreamHandler) {
        self.basicMessageHandler = basicMessageHandler
        self.operatoridMessageHandler = operatoridMessageHandler
        self.locationMessageHandler = locationMessageHandler
        self.stateHandler = stateHandler
        self.scanStateHandler = scanStateHandler
        self.centralManager = CBCentralManager(delegate: nil, queue: dispatchQueue)
        self.dataParser = OdidParser()
        super.init()
        self.centralManager.delegate = self
    }
    
    func scan() {
        if centralManager.isScanning == true { return }
        
        guard centralManager.state == .poweredOn else {
            NSLog("Couldn't start BLE scan, because central is not powered on")
            return
        }
        
        centralManager.scanForPeripherals(
            withServices: nil,
            options: [
                CBCentralManagerScanOptionAllowDuplicatesKey: true,
            ]
        )
        updateScanState()
    }
    
    func isScanning() -> Bool {
        return centralManager.isScanning
    }
    
    func cancel() {
        centralManager.stopScan()
        updateScanState()
    }
    
    func updateScanState() {
        scanStateHandler.send(centralManager.isScanning)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        stateHandler.send(central.state.rawValue)
        updateScanState()
        
        if (central.state == .poweredOn && autoRestart) {
            scan()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard let data = getOdidPayload(from: advertisementData) else {
            // This advertisement is not an ODID ad data
            return
        }
        
        do {
            var err: FlutterError?
            let typeOrdinal = UInt(exactly: dataParser.determineMessageTypePayload(data, offset: 6, error: &err)!)
            let type = DTGMessageType(rawValue: typeOrdinal!)
            if(type == DTGMessageType.basicId)
            {
                let message = dataParser.fromBufferBasicPayload(data, offset: 6, error: &err)
                message!.macAddress = peripheral.identifier.uuidString
                message!.rssi = RSSI.intValue as NSNumber
                basicMessageHandler.send(message! as Any)
            }
            else if(type == DTGMessageType.location)
            {
                let message = dataParser.fromBufferBasicPayload(data, offset: 6, error: &err)
                message!.macAddress = peripheral.identifier.uuidString
                message!.rssi = RSSI.intValue as NSNumber
                locationMessageHandler.send(message as Any)
            }
            else if(type == DTGMessageType.operatorId)
            {
                let message = dataParser.fromBufferBasicPayload(data, offset: 6, error: &err)
                message!.macAddress = peripheral.identifier.uuidString
                message!.rssi = RSSI.intValue as NSNumber
                operatoridMessageHandler.send(message as Any)
            }
        } catch {
            NSLog("scanner", "Failed to parse ODID message: \(error)")
            return
        }
    }
    
    private func getOdidPayload(from advertisementData: [String : Any]) -> FlutterStandardTypedData? {
        // Peripheral must have service data
        guard let serviceData = advertisementData["kCBAdvDataServiceData"] else {
            return nil
        }
    
        let serviceDataDict = serviceData as! Dictionary<CBUUID, Any>
        
        // Find the ODID service UUID
        guard serviceDataDict.keys.contains(BluetoothScanner.serviceUUID) else {
            return nil
        }
        
        let data = serviceDataDict[BluetoothScanner.serviceUUID] as! FlutterStandardTypedData
        
        // All data must start with 0x0D
        guard (serviceDataDict[BluetoothScanner.serviceUUID] as! Data).starts(with: OdidParser.odidAdCode) else {
            return nil
        }
        
        return data
    }
}
