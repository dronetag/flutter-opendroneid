import Foundation

enum OdidMessageType: Int {
    case BASIC_ID = 0
    case LOCATION = 1
    case OPERATOR_ID = 5
}

enum OdidMessageSource: Int {
    case BLUETOOTH_LEGACY = 0
    case BLUETOOTH_LONGRANGE = 1
    case WIFI_NAN = 2
    case WIFI_BEACON = 3
}

class OdidMessageHeader {
    public let type: OdidMessageType?
    public let version: Int?
    
    init(type: OdidMessageType?, version: Int?) {
        self.type = type
        self.version = version
    }
    
    static func fromData(_ byte: UInt8) throws -> OdidMessageHeader {
        let type = Int((byte & 0xF0) >> 4)
        guard type <= 5 else {
            throw OdidParseFail.NotSupportedMessageType
        }
        return OdidMessageHeader(
            type: OdidMessageType(rawValue: type),
            version: Int(byte & 0xFF)
        )
    }
}

protocol OdidMessage {
    func getType() -> OdidMessageType
    func toJson() -> Dictionary<String, Any>
}
