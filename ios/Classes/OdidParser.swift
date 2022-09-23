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
        let systimestamp = Int(Date().timeIntervalSince1970 * 1000)
        
        return DTGBasicIdMessage.make(withReceivedTimestamp: systimestamp as NSNumber, macAddress: macAddress, source: DTGMessageSource.bluetoothLegacy, rssi: 0, uasId: uasId, idType: DTGIdType(rawValue: UInt(idType))!, uaType: DTGUaType(rawValue: UInt(uaType))!)
    }
    
    func fromBufferLocationPayload(_ payload: FlutterStandardTypedData, offset: NSNumber, macAddress: String, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) -> DTGLocationMessage? {
        let bytes = Array(payload.data)
        let dataSlice = Data(bytes)
        let meta = bytes[3]
        let systimestamp = Int(Date().timeIntervalSince1970 * 1000)
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
        return DTGLocationMessage.make(withReceivedTimestamp: systimestamp as NSNumber, macAddress: macAddress, source: DTGMessageSource.bluetoothLegacy, rssi: 0, status: DTGAircraftStatus(rawValue: UInt(status))!, heightType: DTGHeightType(rawValue: UInt(heightType))!, direction: direction as NSNumber, speedHorizontal: speedHori as NSNumber, speedVertical: speedVert as NSNumber, latitude: latitude as NSNumber, longitude: longitude as NSNumber, altitudePressure: altitudePressure as NSNumber, altitudeGeodetic: altitudeGeodetic as NSNumber, height: height as NSNumber, horizontalAccuracy: DTGHorizontalAccuracy(rawValue: UInt(horizontalAccuracy))!, verticalAccuracy: DTGVerticalAccuracy(rawValue: UInt(verticalAccuracy))!, baroAccuracy: DTGVerticalAccuracy(rawValue: UInt(baroAccuracy))!, speedAccuracy: OdidParser.decodeSpeedAccuracy(acc: speedAccuracy), time: timestamp as NSNumber, timeAccuracy: timeAccuracy as NSNumber)
    }
    
    func fromBufferOperatorIdPayload(_ payload: FlutterStandardTypedData, offset: NSNumber, macAddress: String, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) -> DTGOperatorIdMessage? {
        let idBytes = Array(payload.data)[4...]
                
        let operatorId = String(cString: Array(idBytes))
        let systimestamp = Int(Date().timeIntervalSince1970 * 1000)
        
        return DTGOperatorIdMessage.make(withReceivedTimestamp: systimestamp as NSNumber, macAddress: macAddress, source: DTGMessageSource.bluetoothLegacy, rssi: 0, operatorId: operatorId)
    }

    func fromBufferSelfIdPayload(_ payload: FlutterStandardTypedData, offset: NSNumber, macAddress: String, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) -> DTGSelfIdMessage? {
        let bytes = Array(payload.data)
        var opDesc: String = ""
        var it = 0
        let opDecType = (bytes[3] & 0xFF)
        while(it < OdidParser.MAX_STRING_BYTE_SIZE) {
            opDesc += String(bytes[4+it])
                it += 1
        }
        let systimestamp = Int(Date().timeIntervalSince1970 * 1000)
        return DTGSelfIdMessage.make(withReceivedTimestamp: systimestamp as NSNumber, macAddress: macAddress, source: DTGMessageSource.bluetoothLegacy, rssi: 0, descriptionType: opDecType as NSNumber, operationDescription: opDesc);
    }

    func fromBufferConnectionPayload(_ payload: FlutterStandardTypedData, offset: NSNumber, macAddress: String, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) -> DTGConnectionMessage? {
        let systimestamp = Int(Date().timeIntervalSince1970 * 1000)
        return DTGConnectionMessage.make(withReceivedTimestamp: systimestamp as NSNumber, macAddress: macAddress, source: DTGMessageSource.bluetoothLegacy, rssi: 0, transportType: "", lastSeen: 0, firstSeen: 0, msgDelta: 0)
    }

    func fromBufferAuthenticationPayload(_ payload: FlutterStandardTypedData, offset: NSNumber, macAddress: String, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) -> DTGAuthenticationMessage? {
        let bytes = Array(payload.data)
        let dataSlice = Data(bytes)
        let type = bytes[3]
        let authType = (type & 0xF0) >> 4
        let authDataPage: UInt8 = type & 0x0F
        var authLength: UInt8 = 0
        var authTimestamp: UInt32 = 0
        var authLastPageIndex: UInt8 = 0
        var authData: String = ""
        let systimestamp = Int(Date().timeIntervalSince1970 * 1000)

        var offset: UInt8 = 0
        var amount: Int = OdidParser.MAX_AUTH_PAGE_ZERO_SIZE
        if (authDataPage == 0) {
                authLastPageIndex = (bytes[4] & 0xFF)
                authLength = bytes[5] & 0xFF
                authTimestamp = UInt32(littleEndian: dataSlice[6...9].withUnsafeBytes { $0.pointee }) & 0xFFFFFFF
        // For an explanation, please see the description for struct ODID_Auth_data in:
        // https://github.com/opendroneid/opendroneid-core-c/blob/master/libopendroneid/opendroneid.h
            var len: UInt8 =
            UInt8((Int(authLastPageIndex) * OdidParser.MAX_AUTH_PAGE_NON_ZERO_SIZE +
                   OdidParser.MAX_AUTH_PAGE_ZERO_SIZE))
            if (authLastPageIndex >= OdidParser.MAX_AUTH_DATA_PAGES || authLength > len){
                authLastPageIndex = 0
                authLength = 0
                authTimestamp = 0
            }
            else {
                // Display both normal authentication data and any possible additional data
                authLength = len
            }
        }
        else {
            offset = UInt8(OdidParser.MAX_AUTH_PAGE_ZERO_SIZE + (Int(authDataPage) - 0x1) * OdidParser.MAX_AUTH_PAGE_NON_ZERO_SIZE)
            amount = OdidParser.MAX_AUTH_PAGE_NON_ZERO_SIZE
        }
        if (authDataPage >= 0 && authDataPage < OdidParser.MAX_AUTH_DATA_PAGES){
            var index = 10
            let maxLen = 26
            for _ in offset ... offset + UInt8(amount){
                if(index > maxLen){
                    break
                }
                authData += String(bytes[index])
                index += 1
            }
        }
        return DTGAuthenticationMessage.make(withReceivedTimestamp: systimestamp as NSNumber, macAddress: macAddress, source: DTGMessageSource.bluetoothLegacy, rssi: 0, authType: DTGAuthType(rawValue: UInt(authType))!, authDataPage: authDataPage as NSNumber, authLastPageIndex: authLastPageIndex as NSNumber, authLength: authLength as NSNumber, authTimestamp: authTimestamp as NSNumber, authData: authData)
    }

    func fromBufferSystemDataPayload(_ payload: FlutterStandardTypedData, offset: NSNumber, macAddress: String, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) -> DTGSystemDataMessage? {
        let bytes = Array(payload.data)
        let dataSlice = Data(bytes)
        var b = bytes[3]
        let opLocType = b & 0x03
        let classType = (b & 0x1C) >> 2
        let systimestamp = Int(Date().timeIntervalSince1970 * 1000)
        let opLat: Double = OdidParser.LAT_LONG_MULTIPLIER * Double(Int32(littleEndian: dataSlice[4...7].withUnsafeBytes { $0.pointee}))
        let opLong: Double = OdidParser.LAT_LONG_MULTIPLIER * Double(Int32(littleEndian: dataSlice[8...11].withUnsafeBytes { $0.pointee}))
        let areaCnt = UInt16(littleEndian: dataSlice[12...13].withUnsafeBytes { $0.pointee}) & 0xFFFF
        let areaRad = (dataSlice[14] & 0xFF) * 10
        let areaCeil: Double = Double(UInt16(littleEndian: dataSlice[15...16].withUnsafeBytes { $0.pointee}) & 0xFFFF)
        let areaFloor: Double = Double(UInt16(littleEndian: dataSlice[17...18].withUnsafeBytes { $0.pointee}) & 0xFFFF)
        b = dataSlice[19]
        let airCat = (b & 0xF0) >> 4
        let airClass = b & 0x0F
        let altGeo : Double = OdidParser.decodeAltitude(value: Int(littleEndian: dataSlice[20...21].withUnsafeBytes { $0.pointee} & 0xFFFF))
        
        return DTGSystemDataMessage.make(withReceivedTimestamp: systimestamp as NSNumber, macAddress: macAddress, source: DTGMessageSource.bluetoothLegacy, rssi: 0, operatorLocationType: DTGOperatorLocationType(rawValue: UInt(opLocType))!, classificationType: DTGClassificationType(rawValue: UInt(classType))!, operatorLatitude: opLat as NSNumber, operatorLongitude: opLong as NSNumber, areaCount: areaCnt as NSNumber, areaRadius: areaRad as NSNumber, areaCeiling: areaCeil as NSNumber, areaFloor: areaFloor as NSNumber, category: DTGAircraftCategory(rawValue: UInt(airCat))!, classValue: DTGAircraftClass(rawValue: UInt(airClass))!, operatorAltitudeGeo: altGeo as NSNumber)
    }

    static let odidAdCode: [UInt8] = [ 0x0D ]
    static let LAT_LONG_MULTIPLIER = 1e-7
    static let MAX_MESSAGE_SIZE = 25
    static let MAX_ID_BYTE_SIZE = 20
    static let MAX_STRING_BYTE_SIZE = 23
    static let MAX_AUTH_DATA_PAGES = 16
    static let MAX_AUTH_PAGE_ZERO_SIZE = 17
    static let MAX_AUTH_PAGE_NON_ZERO_SIZE = 23
    static let MAX_AUTH_DATA =
                MAX_AUTH_PAGE_ZERO_SIZE + (MAX_AUTH_DATA_PAGES - 1) * MAX_AUTH_PAGE_NON_ZERO_SIZE
    static let MAX_MESSAGES_IN_PACK = 9
    static let MAX_MESSAGE_PACK_SIZE: Int = MAX_MESSAGE_SIZE * MAX_MESSAGES_IN_PACK
        
    
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
    
    static func decodeDirection(value: Int, ew: Int) -> Double {
        return Double(ew == 0 ? value : (value + 180))
    }
    
    static func decodeAltitude(value: Int) -> Double {
        return Double(value) / 2 - 1000
    }
}
