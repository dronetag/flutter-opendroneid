import Foundation

class LocationMessage: OdidMessage {
    let status: Int
    let heightType: Int
    let direction: Int
    let speedHori: Double
    let speedVert: Double
    let latitude: Double
    let longitude: Double
    let altitudePressure: Double
    let altitudeGeodetic: Double
    let height: Double
    let horizontalAccuracy: Int
    let verticalAccuracy: Int
    let baroAccuracy: Int
    let speedAccuracy: Int
    let timestamp: Int
    let timeAccuracy: Double
    let distance: Double
    
    static let LAT_LONG_MULTIPLIER = 1e-7
    
    init(
        status: Int,
        heightType: Int,
        direction: Int,
        speedHori: Double,
        speedVert: Double,
        latitude: Double,
        longitude: Double,
        altitudePressure: Double,
        altitudeGeodetic: Double,
        height: Double,
        horizontalAccuracy: Int,
        verticalAccuracy: Int,
        baroAccuracy: Int,
        speedAccuracy: Int,
        timestamp: Int,
        timeAccuracy: Double,
        distance: Double
    ) {
        self.status = status
        self.heightType = heightType
        self.direction = direction
        self.speedHori = speedHori
        self.speedVert = speedVert
        self.latitude = latitude
        self.longitude = longitude
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
            "direction": direction,
            "speedHorizontal": speedHori,
            "speedVertical": speedVert,
            "latitude": latitude,
            "longitude": longitude,
            "altitudePressure": altitudePressure,
            "altitudeGeodetic": altitudeGeodetic,
            "height": height,
            "accuracyHorizontal": horizontalAccuracy,
            "accuracyVertical": verticalAccuracy,
            "accuracyBaro": baroAccuracy,
            "accuracySpeed": speedAccuracy,
            "locationTimestamp": timestamp,
            "timeAccuracy": timeAccuracy,
            "distance": distance,
        ]
    }
    
    static func decodeSpeed(value: Int, multiplier: Int) -> Double {
        return multiplier == 0 ? Double(value) * 0.25 : Double(value) * 0.75 + 255 * 0.25 // 🤨
    }
    
    static func decodeDirection(value: Int, ew: Int) -> Int {
        return ew == 0 ? value : (value + 180)
    }
    
    static func decodeAltitude(value: Int) -> Double {
        return Double(value) / 2 - 1000
    }
    
    static func fromData(_ data: Data) -> LocationMessage {
        let bytes = Array(data)
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
        
        return LocationMessage(
            status: status,
            heightType: heightType,
            direction: decodeDirection(value: direction, ew: ewDirection),
            speedHori: decodeSpeed(value: speedHori, multiplier: speedMult),
            speedVert: decodeSpeed(value: speedVert, multiplier: speedMult),
            latitude: LocationMessage.LAT_LONG_MULTIPLIER * Double(latitude),
            longitude: LocationMessage.LAT_LONG_MULTIPLIER * Double(longitude),
            altitudePressure: decodeAltitude(value: altitudePressure),
            altitudeGeodetic: decodeAltitude(value: altitudeGeodetic),
            height: decodeAltitude(value: height),
            horizontalAccuracy: horizontalAccuracy,
            verticalAccuracy: verticalAccuracy,
            baroAccuracy: baroAccuracy,
            speedAccuracy: speedAccuracy,
            timestamp: timestamp,
            timeAccuracy: Double(timeAccuracy) * 0.1,
            distance: 0.0
        )
    }
}
