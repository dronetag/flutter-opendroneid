import Foundation
import CoreWLAN

class WifiScanner: NSObject{
    private let messageHandler: StreamHandler
    private let stateHandler: StreamHandler
    
    var wifiClient: CWWifiClient
    let dispatchQueue: DispatchQueue = DispatchQueue(label: "BluetoothScanner")
    
    static let serviceUUID = CBUUID(string: "0000fffa-0000-1000-8000-00805f9b34fb")
    
    init(messageHandler: StreamHandler, stateHandler: StreamHandler) {
        self.messageHandler = messageHandler
        self.stateHandler = stateHandler
        self.wifiClient = CWWifiClient.shared()
        super.init()
        self.centralManager.delegate = self
    }
    
    func scan() {
        /*if centralManager.isScanning == true { return }
        
        guard centralManager.state == .poweredOn else {
            NSLog("Couldn't start BLE scan, because central is not powered on")
            return
        }
        
        centralManager.scanForPeripherals(
            withServices: nil,
            options: [
                CBCentralManagerScanOptionAllowDuplicatesKey: true,
            ]
        )*/
    }
    
    func cancel() {
        //centralManager.stopScan()
    }
    
    
    private func getOdidPayload(from advertisementData: [String : Any]) -> Data? {
        // Peripheral must have service data
       
    }
    
}
