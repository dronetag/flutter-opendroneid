package cz.dronetag.flutter_opendroneid.models

import java.nio.ByteBuffer
import kotlin.experimental.and

class LocationMessage(
    val status: Int,
    val heightType: Int,
    val ewDirection: Int,
    val speedMult: Int,
    val direction: Int,
    val speedHori: Int,
    val speedVert: Int,
    val droneLat: Int, // FIXME: RENAME THIS, horrible!
    val droneLon: Int, // FIXME: RENAME THIS, horrible!
    val altitudePressure: Int,
    val altitudeGeodetic: Int,
    val height: Int,
    val horizontalAccuracy: Int,
    val verticalAccuracy: Int,
    val baroAccuracy: Int,
    val speedAccuracy: Int,
    val timestamp: Int,
    val timeAccuracy: Int,
    val distance: Double,
    override val type: OdidMessage.Type = OdidMessage.Type.LOCATION
) : OdidMessage {

    companion object {
        const val LAT_LONG_MULTIPLIER = 1e-7
        const val SPEED_VERTICAL_MULTIPLIER = 0.5

        fun fromBuffer(byteBuffer: ByteBuffer): LocationMessage {
            val b = byteBuffer.get().toInt()

            // FIXME: refactor!
            val status = b and 0xF0 shr 4
            val heightType = b and 0x04 shr 2
            val ewDirection = b and 0x02 shr 1
            val speedMult = b and 0x01
            val direction = (byteBuffer.get() and 0xFF.toByte()).toInt()
            val speedHori = (byteBuffer.get() and 0xFF.toByte()).toInt()
            val speedVert = byteBuffer.get().toInt()
            val droneLat = byteBuffer.int
            val droneLon = byteBuffer.int
            val altitudePressure = byteBuffer.short.toInt()
            val altitudeGeodetic = byteBuffer.short.toInt()
            val height = byteBuffer.short.toInt()
            val horiVertAccuracy = byteBuffer.get().toInt()
            val horizontalAccuracy = horiVertAccuracy and 0x0F
            val verticalAccuracy = horiVertAccuracy and 0xF0 shr 4
            val speedBaroAccuracy = byteBuffer.get().toInt()
            val baroAccuracy = speedBaroAccuracy and 0xF0 shr 4
            val speedAccuracy = speedBaroAccuracy and 0x0F
            val timestamp = (byteBuffer.short and 0xFFFF.toShort()).toInt()
            val timeAccuracy = (byteBuffer.get() and 0x0F).toInt()

//        if (location.droneLat != 0 && location.droneLon != 0) {
//            val droneLoc = android.location.Location("")
//            droneLoc.latitude = location.getLatitude
//            droneLoc.longitude = location.getLongitude
//            if (receiverLocation != null)
//                location.distance = receiverLocation!!.distanceTo(droneLoc)
//        }

            return LocationMessage(
                status, heightType, ewDirection, speedMult, direction,
                speedHori, speedVert, droneLat, droneLon, altitudePressure,
                altitudeGeodetic, height, horizontalAccuracy, verticalAccuracy,
                baroAccuracy, speedAccuracy, timestamp, timeAccuracy, 0.0,
                OdidMessage.Type.LOCATION
            )
        }
    }

    override fun toJson(): MutableMap<String, Any> {
        return mutableMapOf(
            "status" to status,
            "heightType" to heightType,
            "direction" to getDirection,
            "speedHorizontal" to getSpeedHorizontal,
            "speedVertical" to getSpeedVertical,
            "latitude" to getLatitude,
            "longitude" to getLongitude,
            "altitudePressure" to getAltitudePressure,
            "altitudeGeodetic" to getAltitudeGeodetic,
            "height" to getHeight,
            "accuracyHorizontal" to horizontalAccuracy,
            "accuracyVertical" to verticalAccuracy,
            "accuracyBaro" to baroAccuracy,
            "accuracySpeed" to speedAccuracy,
            "locationTimestamp" to timestamp,
            "timeAccuracy" to getTimeAccuracy,
            "distance" to distance
        )
    }

    private val getDirection: Double
        get() = calcDirection(direction, ewDirection)

    private val getSpeedHorizontal: Double
        get() = calcSpeed(speedHori, speedMult)

    private val getSpeedVertical: Double
        get() = SPEED_VERTICAL_MULTIPLIER * speedVert

    val getLatitude: Double
        get() = LAT_LONG_MULTIPLIER * droneLat
    val getLongitude: Double
        get() = LAT_LONG_MULTIPLIER * droneLon

    private val getAltitudePressure: Double
        get() = calcAltitude(altitudePressure)


    private val getAltitudeGeodetic: Double
        get() = calcAltitude(altitudeGeodetic)


    private val getHeight: Double
        get() = calcAltitude(height)


    private val getTimeAccuracy: Double
        get() = timeAccuracy * 0.1


    private fun calcSpeed(value: Int, mult: Int): Double {
        return if (mult == 0) value * 0.25 else value * 0.75 + 255 * 0.25
    }

    private fun calcDirection(value: Int, EW: Int): Double {
        return if (EW == 0) value.toDouble() else (value + 180).toDouble()
    }

    private fun calcAltitude(value: Int): Double {
        return value.toDouble() / 2 - 1000
    }

}