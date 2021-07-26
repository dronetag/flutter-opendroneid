import Foundation

class BasicIdMessage: OdidMessage {
    let idType: Int
    let uaType: Int
    let uasId: String
    
    init(idType: Int, uaType: Int, uasId: String) {
        self.idType = idType
        self.uaType = uaType
        self.uasId = uasId
    }
    
    func getType() -> OdidMessageType {
        return .BASIC_ID
    }
    
    func toJson() -> Dictionary<String, Any> {
        return [
            "idType": idType,
            "uaType": uaType,
            "uasId": uasId
        ]
    }
    
    static func fromData(_ data: Data) -> BasicIdMessage {
        let bytes = Array(data)
        let typeByte = bytes[0]
        let idType = Int((typeByte & 0xF0) >> 4)
        let uaType = Int(typeByte & 0x0F)
        let uasId = String(bytes: bytes[1...], encoding: .ascii)
        
        return BasicIdMessage(
            idType: idType, uaType: uaType, uasId: uasId ?? ""
        )
    }
    
}
