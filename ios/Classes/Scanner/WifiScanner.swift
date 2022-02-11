import Foundation

class WifiScanner: NSObject{
    private let messageHandler: StreamHandler
    private let stateHandler: StreamHandler
    
    let dispatchQueue: DispatchQueue = DispatchQueue(label: "WifiScanner")
    
    
    init(messageHandler: StreamHandler, stateHandler: StreamHandler) {
        self.messageHandler = messageHandler
        self.stateHandler = stateHandler
        super.init()
    }
    
    func isScanning() -> Bool {
        return false;
    }
    
    func scan() {
        // to-do
    }
    
    func cancel() {
        // to-do
    }
    
    
}
