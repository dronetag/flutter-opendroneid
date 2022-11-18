import Foundation
import CoreBluetooth

class BluetoothScanner: NSObject, CBCentralManagerDelegate {
    private let operatoridMessageHandler: StreamHandler
    private let basicMessageHandler: StreamHandler
    private let locationMessageHandler: StreamHandler
    private let selfidMessageHandler: StreamHandler
    private let authMessageHandler: StreamHandler
    private let systemMessageHandler: StreamHandler
    private let scanStateHandler: StreamHandler
    private let dataParser: OdidParser
    
    private var centralManager: CBCentralManager!
    var autoRestart: Bool = false
    let dispatchQueue: DispatchQueue = DispatchQueue(label: "BluetoothScanner")
    
    static let serviceUUID = CBUUID(string: "0000fffa-0000-1000-8000-00805f9b34fb")
    
    init(basicMessageHandler: StreamHandler, locationMessageHandler: StreamHandler, operatoridMessageHandler: StreamHandler, authMessageHandler: StreamHandler, systemMessageHandler: StreamHandler, selfidMessageHandler: StreamHandler, scanStateHandler: StreamHandler) {
        self.basicMessageHandler = basicMessageHandler
        self.operatoridMessageHandler = operatoridMessageHandler
        self.locationMessageHandler = locationMessageHandler
        self.authMessageHandler = authMessageHandler
        self.selfidMessageHandler = selfidMessageHandler
        self.systemMessageHandler = systemMessageHandler
        self.scanStateHandler = scanStateHandler
        self.dataParser = OdidParser()
        
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

    func managerState() -> Int{
        return centralManager.state.rawValue
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        updateScanState()
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        handleOdidMessage(advertisementData: advertisementData, didDiscover: peripheral, rssi: RSSI, offset: 6)
    }

    private func handleOdidMessage(advertisementData: [String : Any], didDiscover peripheral: CBPeripheral, rssi RSSI: NSNumber, offset: NSNumber){
        guard let data = getOdidPayload(from: advertisementData) else {
            // This advertisement is not an ODID ad data
            return
        }
        
        do {
            var err: FlutterError?
            let typeOrdinal = UInt(exactly: dataParser.determineMessageTypePayload(data, offset: offset, error: &err)!)
            let type = DTGMessageType(rawValue: typeOrdinal!)
            if(type == DTGMessageType.basicId)
            {
                let message : DTGBasicIdMessage? = dataParser.fromBufferBasicPayload(data, offset: offset, macAddress: peripheral.identifier.uuidString, error: &err)
                message!.rssi = RSSI.intValue as NSNumber
                basicMessageHandler.send(message!.toMap() as Any)
            }
            else if(type == DTGMessageType.location)
            {
                let message : DTGLocationMessage? = dataParser.fromBufferLocationPayload(data, offset: offset, macAddress: peripheral.identifier.uuidString, error: &err)
                message!.rssi = RSSI.intValue as NSNumber
                locationMessageHandler.send(message!.toMap() as Any)
            }
            else if(type == DTGMessageType.operatorId)
            {
                let message : DTGOperatorIdMessage? = dataParser.fromBufferOperatorIdPayload(data, offset: offset, macAddress: peripheral.identifier.uuidString, error: &err)
                message!.rssi = RSSI.intValue as NSNumber
                operatoridMessageHandler.send(message!.toMap() as Any)
            }
            else if(type == DTGMessageType.selfId)
            {
                let message : DTGSelfIdMessage? = dataParser.fromBufferSelfIdPayload(data, offset: offset, macAddress: peripheral.identifier.uuidString, error: &err)
                message!.rssi = RSSI.intValue as NSNumber
                selfidMessageHandler.send(message!.toMap() as Any)
            }
            else if(type == DTGMessageType.auth)
            {
                let message : DTGAuthenticationMessage? = dataParser.fromBufferAuthenticationPayload(data, offset: offset, macAddress: peripheral.identifier.uuidString, error: &err)
                message!.rssi = RSSI.intValue as NSNumber
                authMessageHandler.send(message!.toMap() as Any)
            }
            else if(type == DTGMessageType.system)
            {
                let message : DTGSystemDataMessage? = dataParser.fromBufferSystemDataPayload(data, offset: offset, macAddress: peripheral.identifier.uuidString, error: &err)
                message!.rssi = RSSI.intValue as NSNumber
                systemMessageHandler.send(message!.toMap() as Any)
            }
            else if(type == DTGMessageType.messagePack)
            {
                let bytes = Array(data.data)
                var packOffset = offset as! Int + 1
                let messageSize = bytes[packOffset];
                packOffset += 1
                let messages = bytes[packOffset];
                packOffset += 1
                for _ in 0 ... (messages - 1) {
                    handleOdidMessage(advertisementData: advertisementData, didDiscover: peripheral, rssi: RSSI, offset: packOffset as NSNumber)
                    packOffset += Int(messageSize)
                }
            }
        } catch {
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
        
        let data = serviceDataDict[BluetoothScanner.serviceUUID] as! Data
        let dataF = FlutterStandardTypedData(bytes: data)
        // All data must start with 0x0D
        guard data.starts(with: OdidParser.odidAdCode) else {
            return nil
        }
        return dataF
    }
}
