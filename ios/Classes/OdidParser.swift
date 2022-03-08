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
    
    func fromBufferBasicPayload(_ payload: FlutterStandardTypedData, offset: NSNumber, macAddress: String, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) -> DTGBasicIdMessage? {
        let bytes = Array(payload.data)
        let typeByte = bytes[3]
        let idType = Int((typeByte & 0xF0) >> 4)
        let uaType = Int(typeByte & 0x0F)
        let uasId = String(bytes: bytes[4...], encoding: .ascii) ?? ""
        
        return DTGBasicIdMessage.make(withReceivedTimestamp: 0, macAddress: macAddress, source: DTGMessageSource.bluetoothLegacy, rssi: 0, uasId: uasId, idType: DTGIdType(rawValue: UInt(idType))!, uaType: DTGUaType(rawValue: UInt(uaType))!)
    }
    
    func fromBufferLocationPayload(_ payload: FlutterStandardTypedData, offset: NSNumber, macAddress: String, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) -> DTGLocationMessage? {
        let bytes = Array(payload.data)
        let dataSlice = Data(bytes)
        let meta = bytes[3]
        
        let status = Int((meta & 0xF0) >> 4)
        let heightType = Int((meta & 0x04) >> 2)
        let ewDirection = Int((meta & 0x02) >> 1)
        let speedMult = Int((meta & 0x01))
        let direction = OdidParser.decodeDirection(value: Int(dataSlice[4] & 0xFF), ew: ewDirection)
        let speedHori = OdidParser.decodeSpeed(value: Int(dataSlice[5] & 0xFF), multiplier: speedMult)
        let speedVert = OdidParser.decodeSpeed(value: Int(dataSlice[6]), multiplier: speedMult)
        var latRaw = Int32(littleEndian: dataSlice[7...10].withUnsafeBytes { $0.pointee })
        var longRaw = Int32(littleEndian: dataSlice[11...14].withUnsafeBytes { $0.pointee })
        let latitude = OdidParser.LAT_LONG_MULTIPLIER * Double(latRaw)
        let longitude = OdidParser.LAT_LONG_MULTIPLIER * Double(longRaw)
        let altPressureRaw = UInt16(littleEndian: dataSlice[15...16].withUnsafeBytes { $0.pointee })
        let altGeodeticRaw = UInt16(littleEndian: dataSlice[17...18].withUnsafeBytes { $0.pointee })
        let altitudePressure = OdidParser.decodeAltitude(value: Int(altPressureRaw))
        let altitudeGeodetic = OdidParser.decodeAltitude(value: Int(altGeodeticRaw))
        let heightRaw = UInt16(littleEndian: dataSlice[19...20].withUnsafeBytes { $0.pointee })
        let height = OdidParser.decodeAltitude(value: Int(heightRaw))
        let horizontalAccuracy = Int(dataSlice[21] & 0x0F)
        let verticalAccuracy = Int((dataSlice[21] & 0xF0) >> 4)
        let baroAccuracy = Int((dataSlice[22] & 0xF0) >> 4)
        let speedAccuracy = Int(dataSlice[22] & 0x0F)
        let timestamp = Int(dataSlice[20...21].uint16)
        let timeAccuracy = Double(dataSlice[25] & 0x0F) * 0.1
        return DTGLocationMessage.make(withReceivedTimestamp: 0, macAddress: macAddress, source: DTGMessageSource.bluetoothLegacy, rssi: 0, status: DTGAircraftStatus(rawValue: UInt(status))!, heightType: DTGHeightType(rawValue: UInt(heightType))!, direction: direction as NSNumber, speedHorizontal: speedHori as NSNumber, speedVertical: speedVert as NSNumber, latitude: latitude as NSNumber, longitude: longitude as NSNumber, altitudePressure: altitudePressure as NSNumber, altitudeGeodetic: altitudeGeodetic as NSNumber, height: height as NSNumber, horizontalAccuracy: DTGHorizontalAccuracy(rawValue: UInt(horizontalAccuracy))!, verticalAccuracy: DTGVerticalAccuracy(rawValue: UInt(verticalAccuracy))!, baroAccuracy: DTGVerticalAccuracy(rawValue: UInt(baroAccuracy))!, speedAccuracy: OdidParser.decodeSpeedAccuracy(acc: speedAccuracy), time: timestamp as NSNumber, timeAccuracy: timeAccuracy as NSNumber)
    }
    
    func fromBufferOperatorIdPayload(_ payload: FlutterStandardTypedData, offset: NSNumber, macAddress: String, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) -> DTGOperatorIdMessage? {
        let idBytes = Array(payload.data)[4...]
                
        let operatorId = String(cString: Array(idBytes))
        
        return DTGOperatorIdMessage.make(withReceivedTimestamp: 0, macAddress: macAddress, source: DTGMessageSource.bluetoothLegacy, rssi: 0, operatorId: operatorId)
    }
    
    static let odidAdCode: [UInt8] = [ 0x0D ]
    static let LAT_LONG_MULTIPLIER = 1e-7


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
    
    static func decodeSpeed(value: Int, multiplier: Int) -> Double {
        return multiplier == 0 ? Double(value) * 0.25 : Double(value) * 0.75 + 255 * 0.25 // 🤨
    }
    
    static func decodeSpeedAccuracy(acc: Int) -> DTGSpeedAccuracy {
        if(acc == 10){
            return DTGSpeedAccuracy.meter_per_second_10
            
        }
        else if(acc == 3){
                return DTGSpeedAccuracy.meter_per_second_3
        }
        else if(acc == 1){
            return DTGSpeedAccuracy.meter_per_second_1
        }
            //meter_per_second_0_3
        return DTGSpeedAccuracy.unknown
    }
    
    static func decodeDirection(value: Int, ew: Int) -> Int {
        return ew == 0 ? value : (value + 180)
    }
    
    static func decodeAltitude(value: Int) -> Double {
        return Double(value) / 2 - 1000
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
