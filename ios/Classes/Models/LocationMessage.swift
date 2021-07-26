import Foundation

class LocationMessage: OdidMessage {
    let status: Int
    let heightType: Int
    let ewDirection: Int
    let speedMult: Int
    let direction: Int
    let speedHori: Int
    let speedVert: Int
    let droneLat: Int // FIXME: RENAME THIS, horrible!
    let droneLon: Int // FIXME: RENAME THIS, horrible!
    let altitudePressure: Int
    let altitudeGeodetic: Int
    let height: Int
    let horizontalAccuracy: Int
    let verticalAccuracy: Int
    let baroAccuracy: Int
    let speedAccuracy: Int
    let timestamp: Int
    let timeAccuracy: Int
    let distance: Double
    
    static let LAT_LONG_MULTIPLIER = 1e-7
    static let SPEED_VERTICAL_MULTIPLIER = 0.5
    
    init(
        status: Int,
        heightType: Int,
        ewDirection: Int,
        speedMult: Int,
        direction: Int,
        speedHori: Int,
        speedVert: Int,
        droneLat: Int,
        droneLon: Int,
        altitudePressure: Int,
        altitudeGeodetic: Int,
        height: Int,
        horizontalAccuracy: Int,
        verticalAccuracy: Int,
        baroAccuracy: Int,
        speedAccuracy: Int,
        timestamp: Int,
        timeAccuracy: Int,
        distance: Double
    ) {
        self.status = status
        self.heightType = heightType
        self.ewDirection = ewDirection
        self.speedMult = speedMult
        self.direction = direction
        self.speedHori = speedHori
        self.speedVert = speedVert
        self.droneLat = droneLat
        self.droneLon = droneLon
        self.altitudePressure = altitudePressure
        self.altitudeGeodetic = altitudeGeodetic
        self.height = height
        self.horizontalAccuracy = horizontalAccuracy
        self.verticalAccuracy = verticalAccuracy
        self.baroAccuracy = baroAccuracy
        self.speedAccuracy = speedAccuracy
        self.timestamp = timestamp
        self.timeAccuracy = timeAccuracy
        self.distance = distance
    }
    
    func getType() -> OdidMessageType {
        return .LOCATION
    }
    
    func toJson() -> Dictionary<String, Any> {
        return [
            "status": status,
            "heightType": heightType,
            "direction": getDirection(),
            "speedHorizontal": getSpeedHorizontal(),
            "speedVertical": getSpeedVertical(),
            "latitude": getLatitude(),
            "longitude": getLongitude(),
            "altitudePressure": getAltitudePressure(),
            "altitudeGeodetic": getAltitudeGeodetic(),
            "height": getHeight(),
            "accuracyHorizontal": horizontalAccuracy,
            "accuracyVertical": verticalAccuracy,
            "accuracyBaro": baroAccuracy,
            "accuracySpeed": speedAccuracy,
            "locationTimestamp": timestamp,
            "timeAccuracy": getTimeAccuracy(),
            "distance": distance,
        ]
    }
    
    func getDirection() -> Double {
        return decodeDirection(value: direction, ew: ewDirection)
    }
    
    func getSpeedHorizontal() -> Double {
        return decodeSpeed(value: speedHori, multiplier: speedMult)
    }
    
    func getSpeedVertical() -> Double {
        return decodeSpeed(value: speedVert, multiplier: speedMult)
    }
    
    func getLatitude() -> Double {
        return LocationMessage.LAT_LONG_MULTIPLIER * Double(droneLat)
    }
    
    func getLongitude() -> Double {
        return LocationMessage.LAT_LONG_MULTIPLIER * Double(droneLon)
    }
    
    func getAltitudePressure() -> Double {
        return decodeAltitude(value: altitudePressure)
    }
    
    func getAltitudeGeodetic() -> Double {
        return decodeAltitude(value: altitudeGeodetic)
    }
    
    func getHeight() -> Double {
        return decodeAltitude(value: height)
    }
    
    func getTimeAccuracy() -> Double {
        return Double(timeAccuracy) * 0.1
    }
    
    func decodeSpeed(value: Int, multiplier: Int) -> Double {
        return multiplier == 0 ? Double(value) * 0.25 : Double(value) * 0.75 + 255 * 0.25 // 🤨
    }
    
    func decodeDirection(value: Int, ew: Int) -> Double {
        return Double(ewDirection == 0 ? (direction ?? 0) : (direction ?? 0) + 180) // FIXME
    }
    
    func decodeAltitude(value: Int) -> Double {
        return Double(value) / 2 - 1000
    }
    
    static func fromData(_ data: Data) -> LocationMessage {
        let bytes = Array(data)
        let dataSlice = Data(bytes)
        let meta = bytes[0]
        
        return LocationMessage(
            status: Int((meta & 0xF0) >> 4),
            heightType: Int((meta & 0x04) >> 2),
            ewDirection: Int((meta & 0x02) >> 1),
            speedMult: Int((meta & 0x01)),
            direction: Int(dataSlice[1] & 0xFF),
            speedHori: Int(dataSlice[2] & 0xFF),
            speedVert: Int(dataSlice[3]),
            droneLat: Int(dataSlice[4...7].uint32), // FIXME
            droneLon: Int(dataSlice[8...11].uint32), // FIXME
            altitudePressure: Int(dataSlice[12...13].uint16), // FIXME
            altitudeGeodetic: Int(dataSlice[14...15].uint16), // FIXME
            height: Int(dataSlice[16...17].uint16), // FIXME
            horizontalAccuracy: Int(dataSlice[18] & 0x0F),
            verticalAccuracy: Int((dataSlice[18] & 0xF0) >> 4),
            baroAccuracy: Int(dataSlice[19] & 0x0F),
            speedAccuracy: Int((dataSlice[19] & 0xF0) >> 4),
            timestamp: Int(dataSlice[20...21].uint16), // FIXME
            timeAccuracy: Int(dataSlice[22] & 0x0F),
            distance: 0.0
        )
    }
}
