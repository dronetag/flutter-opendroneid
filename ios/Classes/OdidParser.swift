import Foundation

enum OdidParseFail: Error {
    case NotODIDMessage
    case NotSupportedMessageType
}

class OdidParser: NSObject {
    static let odidAdCode: [UInt8] = [ 0x0D ]
    
    static func parseData(_ data: Data) throws -> OdidMessage {
        // Make sure its ODID message
        guard data.starts(with: OdidParser.odidAdCode) else {
            throw OdidParseFail.NotODIDMessage
        }
        
        let bytes = Array(data)
        
        let header = try OdidMessageHeader.fromData(data[2])
        let messageData = data[3...]
        
        switch (header.type) {
        case .BASIC_ID:
            return BasicIdMessage.fromData(messageData)
        case .LOCATION:
            return LocationMessage.fromData(messageData)
        case .OPERATOR_ID:
            return OperatorIdMessage.fromData(messageData)
        default:
            throw OdidParseFail.NotSupportedMessageType
        }
    }
    
    static func constructJson(from message: OdidMessage, source: OdidMessageSource, macAddress: String, rssi: Int?) -> Dictionary<String, Any> {
        var json = message.toJson()
        
        json["type"] = message.getType().rawValue
        json["macAddress"] = macAddress
        json["rssi"] = rssi
        json["source"] = source.rawValue
        
        return json
    }
}
