package cz.dronetag.flutter_opendroneid.models

import java.nio.ByteBuffer
import kotlin.experimental.and

class LocationMessage(
    val status: Int,
    val heightType: Int,
    val direction: Int,
    val speedHori: Double,
    val speedVert: Double,
    val latitude: Double,
    val longitude: Double,
    val altitudePressure: Double,
    val altitudeGeodetic: Double,
    val height: Double,
    val horizontalAccuracy: Int,
    val verticalAccuracy: Int,
    val baroAccuracy: Int,
    val speedAccuracy: Int,
    val timestamp: Int,
    val timeAccuracy: Double,
    val distance: Double,
    override val type: OdidMessage.Type = OdidMessage.Type.LOCATION
) : OdidMessage {

    companion object {
        const val LAT_LONG_MULTIPLIER = 1e-7

        @ExperimentalUnsignedTypes
        fun fromBuffer(byteBuffer: ByteBuffer): LocationMessage {
            val b = byteBuffer.get().toInt()
            val status = b and 0xF0 shr 4
            val heightType = b and 0x04 shr 2
            val ewDirection = b and 0x02 shr 1
            val speedMult = b and 0x01

            val direction = calcDirection((byteBuffer.get() and 0xFF.toByte()).toInt(), ewDirection)

            val speedHori = calcSpeed((byteBuffer.get() and 0xFF.toByte()).toInt(), speedMult)
            val speedVert = calcSpeed(byteBuffer.get().toInt(), speedMult)

            val latitude = LAT_LONG_MULTIPLIER * byteBuffer.int
            val longitude = LAT_LONG_MULTIPLIER * byteBuffer.int

            val altitudePressure = calcAltitude(byteBuffer.short.toUShort().toInt())
            val altitudeGeodetic = calcAltitude(byteBuffer.short.toUShort().toInt())
            val height = calcAltitude(byteBuffer.short.toUShort().toInt())

            val horiVertAccuracy = byteBuffer.get().toInt()
            val horizontalAccuracy = horiVertAccuracy and 0x0F
            val verticalAccuracy = horiVertAccuracy and 0xF0 shr 4

            val speedBaroAccuracy = byteBuffer.get().toInt()
            val baroAccuracy = speedBaroAccuracy and 0xF0 shr 4
            val speedAccuracy = speedBaroAccuracy and 0x0F

            val timestamp = byteBuffer.short.toUShort().toInt()

            val timeAccuracy = (byteBuffer.get() and 0x0F).toInt() * 0.1

            return LocationMessage(
                status, heightType, direction, speedHori, speedVert, latitude, longitude, altitudePressure,
                altitudeGeodetic, height, horizontalAccuracy, verticalAccuracy,
                baroAccuracy, speedAccuracy, timestamp, timeAccuracy, 0.0,
                OdidMessage.Type.LOCATION
            )
        }

        private fun calcSpeed(value: Int, mult: Int): Double {
            return if (mult == 0) value * 0.25 else value * 0.75 + 255 * 0.25
        }

        private fun calcDirection(value: Int, EW: Int): Int {
            return if (EW == 0) value else (value + 180)
        }

        private fun calcAltitude(value: Int): Double {
            return value.toDouble() / 2 - 1000
        }
    }

    override fun toJson(): MutableMap<String, Any> {
        return mutableMapOf(
            "status" to status,
            "heightType" to heightType,
            "direction" to direction,
            "speedHorizontal" to speedHori,
            "speedVertical" to speedVert,
            "latitude" to latitude,
            "longitude" to longitude,
            "altitudePressure" to altitudePressure,
            "altitudeGeodetic" to altitudeGeodetic,
            "height" to height,
            "accuracyHorizontal" to horizontalAccuracy,
            "accuracyVertical" to verticalAccuracy,
            "accuracyBaro" to baroAccuracy,
            "accuracySpeed" to speedAccuracy,
            "locationTimestamp" to timestamp,
            "timeAccuracy" to timeAccuracy,
            "distance" to distance
        )
    }
}