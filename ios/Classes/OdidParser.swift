import Foundation

enum OdidParseFail: Error {
    case NotODIDMessage
    case NotSupportedMessageType
}

class OdidParser: NSObject, DTGMessageApi {
    static let odidAdCode: [UInt8] = [ 0x0D ]
    
    public func determineMessageTypePayload(payload: FlutterStandardTypedData) -> NSNumber? {

    }

    public func fromBufferBasicPayload(payload: FlutterStandardTypedData, offset: NSNumber, error: FlutterError? ) -> DTGBasicIdMessage? {

    }

    public func fromBufferLocationPayload(payload: FlutterStandardTypedData, offset: NSNumber, error: FlutterError?) -> DTGLocationMessage? {

    }
    public func fromBufferOperatorIdPayload(payload: FlutterStandardTypedData, offset: NSNumber, error: FlutterError?) -> DTGOperatorIdMessage? {

    }

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
