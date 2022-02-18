import Foundation

enum OdidParseFail: Error {
    case NotODIDMessage
    case NotSupportedMessageType
}

class OdidParser: NSObject, DTGMessageApi {
    func determineMessageTypePayload(_ payload: FlutterStandardTypedData, offset: NSNumber, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) -> NSNumber? {
        
        let type = Int((payload.data[2] & 0xF0) >> 4)
        guard type <= 5 else {
            return -1;
        }
        return type as NSNumber
    }
    
    func fromBufferBasicPayload(_ payload: FlutterStandardTypedData, offset: NSNumber, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) -> DTGBasicIdMessage? {
        let bytes = Array(payload.data)
        let typeByte = bytes[0]
        let idType = Int((typeByte & 0xF0) >> 4)
        let uaType = Int(typeByte & 0x0F)
        let uasId = String(bytes: bytes[1...], encoding: .ascii) ?? ""
        
        return DTGBasicIdMessage.make(withReceivedTimestamp: 0, macAddress: "", source: DTGMessageSource.bluetoothLegacy, rssi: 0, uasId: uasId, idType: DTGIdType(rawValue: UInt(idType))!, uaType: DTGUaType(rawValue: UInt(uaType))!)
    }
    
    func fromBufferLocationPayload(_ payload: FlutterStandardTypedData, offset: NSNumber, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) -> DTGLocationMessage? {
        let bytes = Array(payload.data)
        let dataSlice = Data(bytes)
        let meta = bytes[0]
        
        let status = Int((meta & 0xF0) >> 4)
        let heightType = Int((meta & 0x04) >> 2)
        let ewDirection = Int((meta & 0x02) >> 1)
        let speedMult = Int((meta & 0x01))
        let direction = Int(dataSlice[1] & 0xFF)
        let speedHori = Int(dataSlice[2] & 0xFF)
        let speedVert = Int(dataSlice[3])
        let latitude = Int(dataSlice[4...7].uint32)
        let longitude = Int(dataSlice[8...11].uint32)
        let altitudePressure = Int(dataSlice[12...13].uint16)
        let altitudeGeodetic = Int(dataSlice[14...15].uint16)
        let height = Int(dataSlice[16...17].uint16)
        let horizontalAccuracy = Int(dataSlice[18] & 0x0F)
        let verticalAccuracy = Int((dataSlice[18] & 0xF0) >> 4)
        let baroAccuracy = Int(dataSlice[19] & 0x0F)
        let speedAccuracy = Int((dataSlice[19] & 0xF0) >> 4)
        let timestamp = Int(dataSlice[20...21].uint16)
        let timeAccuracy = Int(dataSlice[22] & 0x0F)
        
        return DTGLocationMessage.make(withReceivedTimestamp: 0, macAddress: "", source: DTGMessageSource.bluetoothLegacy, rssi: 0, status: DTGAircraftStatus(rawValue: UInt(status))!, heightType: DTGHeightType(rawValue: UInt(heightType))!, direction: direction as NSNumber, speedHorizontal: speedHori as NSNumber, speedVertical: speedVert as NSNumber, latitude: latitude as NSNumber, longitude: longitude as NSNumber, altitudePressure: altitudePressure as NSNumber, altitudeGeodetic: altitudeGeodetic as NSNumber, height: height as NSNumber, horizontalAccuracy: DTGHorizontalAccuracy(rawValue: UInt(horizontalAccuracy))!, verticalAccuracy: DTGVerticalAccuracy(rawValue: UInt(verticalAccuracy))!, baroAccuracy: DTGVerticalAccuracy(rawValue: UInt(baroAccuracy))!, speedAccuracy: DTGSpeedAccuracy(rawValue: UInt(timeAccuracy))!, time: timestamp as NSNumber, timeAccuracy: timeAccuracy as NSNumber)
    }
    
    func fromBufferOperatorIdPayload(_ payload: FlutterStandardTypedData, offset: NSNumber, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) -> DTGOperatorIdMessage? {
        let idBytes = Array(payload.data)[1...]
        let operatorId = String(cString: Array(idBytes))
        
        return DTGOperatorIdMessage.make(withReceivedTimestamp: 0, macAddress: "", source: DTGMessageSource.bluetoothLegacy, rssi: 0, operatorId: operatorId)
    }
    
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
