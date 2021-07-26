import Foundation

class OperatorIdMessage: OdidMessage {
    let idType: Int
    let operatorId: String
    
    init(idType: Int, operatorId: String) {
        self.idType = idType
        self.operatorId = operatorId
    }
    
    func getType() -> OdidMessageType {
        return .OPERATOR_ID
    }
    
    func toJson() -> Dictionary<String, Any> {
        return ["idType": idType, "operatorId": operatorId]
    }
    
    static func fromData(_ data: Data) -> OperatorIdMessage {
        let bytes = Array(data)
        let idBytes = Array(data)[1...]
        let operatorId = String(cString: Array(idBytes))
        
        return OperatorIdMessage(
            idType: Int(bytes[0]),
            operatorId: operatorId
        )
    }
}
