package cz.dronetag.flutter_opendroneid

import android.os.Build
import android.util.Log
import androidx.annotation.RequiresApi
import cz.dronetag.flutter_opendroneid.models.BasicIdMessage
import cz.dronetag.flutter_opendroneid.models.LocationMessage
import cz.dronetag.flutter_opendroneid.models.OdidMessage
import cz.dronetag.flutter_opendroneid.models.OperatorIdMessage
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.sql.Time
import java.text.DateFormat
import kotlin.experimental.and

class OdidMessageHandler: Pigeon.MessageApi {
//    private var receiverLocation: android.location.Location? = null
//    private var locationRequest = LocationRequest.create()
//    private var locationCallback = object : LocationCallback() {
//        override fun onLocationResult(locationResult: LocationResult) {
//            for (location in locationResult.locations) {
//                if (location != null) {
//                    receiverLocation = location
//                }
//            }
//        }
//    }

    companion object {
        const val MAX_MESSAGE_SIZE = 25
        const val MAX_ID_BYTE_SIZE = 20
    }


    override fun fromBufferBasic(payload: ByteArray, offset: Long, macAddress: String): Pigeon.BasicIdMessage? {
        if (payload.size < offset + MAX_MESSAGE_SIZE) return null
        val byteBuffer = ByteBuffer.wrap(payload, offset.toInt(), MAX_MESSAGE_SIZE)
        byteBuffer.order(ByteOrder.LITTLE_ENDIAN)
        val b: Int = (byteBuffer.get() and 0xFF.toByte()).toInt()
        return parseBasicMessage(byteBuffer, macAddress)
    }

    override fun fromBufferLocation(payload: ByteArray, offset: Long, macAddress: String): Pigeon.LocationMessage? {
        if (payload.size < offset + MAX_MESSAGE_SIZE) return null
        val byteBuffer = ByteBuffer.wrap(payload, offset.toInt(), MAX_MESSAGE_SIZE)
        byteBuffer.order(ByteOrder.LITTLE_ENDIAN)
        val b: Int = (byteBuffer.get() and 0xFF.toByte()).toInt()
        return parseLocationMessage(byteBuffer, macAddress)
    }

    override fun fromBufferOperatorId(payload: ByteArray, offset: Long, macAddress: String): Pigeon.OperatorIdMessage? {
        if (payload.size < offset + MAX_MESSAGE_SIZE) return null
        val byteBuffer = ByteBuffer.wrap(payload, offset.toInt(), MAX_MESSAGE_SIZE)
        byteBuffer.order(ByteOrder.LITTLE_ENDIAN)
        val b: Int = (byteBuffer.get() and 0xFF.toByte()).toInt()
        return parseOperatorIdMessage(byteBuffer, macAddress)
    }

    override fun determineMessageType(payload: ByteArray, offset: Long): Long? {
        if (payload.size < offset + MAX_MESSAGE_SIZE) return null

        val byteBuffer =
                ByteBuffer.wrap(payload, offset.toInt(), MAX_MESSAGE_SIZE)
        byteBuffer.order(ByteOrder.LITTLE_ENDIAN)

        val b: Int = (byteBuffer.get() and 0xFF.toByte()).toInt()
        val typeData = b and 0xF0 shr 4
        if (typeData > 5) return null
        return typeData.toLong()
    }

    private fun parseBasicMessage(byteBuffer: ByteBuffer, , macAddress: String): Pigeon.BasicIdMessage {
        val builder = Pigeon.BasicIdMessage.Builder();
        val type: Int = byteBuffer.get().toInt()
        val uasId = ByteArray(OdidMessageHandler.MAX_ID_BYTE_SIZE)
        var uasIdStr = String(uasId)

        builder.setReceivedTimestamp(System.currentTimeMillis())
        builder.setIdType(Pigeon.IdType.values()[type and 0xF0 shr 4])
        builder.setUaType(Pigeon.UaType.values()[type and 0x0F])
        builder.setMacAddress(macAddress)
        byteBuffer.get(uasId, 0, OdidMessageHandler.MAX_ID_BYTE_SIZE)
        if (uasIdStr.contains('\u0000')) {
            uasIdStr = uasIdStr.split('\u0000').first()
        }
        builder.setUasId(uasIdStr)
        return builder.build()
    }

    private fun parseLocationMessage(byteBuffer: ByteBuffer, macAddress: String): Pigeon.LocationMessage {
        val builder = Pigeon.LocationMessage.Builder();
        val b = byteBuffer.get().toInt()
        val status = b and 0xF0 shr 4
        val heightType = b and 0x04 shr 2
        val ewDirection = b and 0x02 shr 1
        val speedMult = b and 0x01
        val LAT_LONG_MULTIPLIER = 1e-7

        builder.setMacAddress(macAddress)
        builder.setReceivedTimestamp(System.currentTimeMillis())
        builder.setDirection(
                calcDirection((byteBuffer.get() and 0xFF.toByte()).toInt(), ewDirection).toLong())
        builder.setSpeedHorizontal(calcSpeed((byteBuffer.get() and 0xFF.toByte()).toInt(), speedMult))
        builder.setSpeedVertical(calcSpeed(byteBuffer.get().toInt(), speedMult))
        val lat = LAT_LONG_MULTIPLIER * byteBuffer.int
        builder.setLatitude(lat)
        builder.setLongitude(LAT_LONG_MULTIPLIER * byteBuffer.int)
        builder.setAltitudePressure(calcAltitude(byteBuffer.short.toUShort().toInt()))
        builder.setAltitudeGeodetic(calcAltitude(byteBuffer.short.toUShort().toInt()))
        builder.setHeight(calcAltitude(byteBuffer.short.toUShort().toInt()))
        val horiVertAccuracy = byteBuffer.get().toInt()
        builder.setHorizontalAccuracy(Pigeon.HorizontalAccuracy.values()[horiVertAccuracy and 0x0F])
        builder.setVerticalAccuracy(Pigeon.VerticalAccuracy.values()[horiVertAccuracy and 0xF0 shr 4])
        val speedBaroAccuracy = byteBuffer.get().toInt()
        builder.setBaroAccuracy(Pigeon.VerticalAccuracy.values()[speedBaroAccuracy and 0xF0 shr 4])
        builder.setSpeedAccuracy(speedAccToEnum(speedBaroAccuracy and 0x0F))
        builder.setTime(byteBuffer.short.toUShort().toLong())
        builder.setTimeAccuracy((byteBuffer.get() and 0x0F).toInt() * 0.1)
        builder.setStatus(Pigeon.AircraftStatus.values()[status])
        builder.setHeightType(Pigeon.HeightType.values()[heightType])
        return builder.build()
    }

    private fun parseOperatorIdMessage(byteBuffer: ByteBuffer, macAddress: String): Pigeon.OperatorIdMessage {
        val builder = Pigeon.OperatorIdMessage.Builder();
        builder.setMacAddress(macAddress)
        builder.setReceivedTimestamp(System.currentTimeMillis())
        val type: Int = byteBuffer.get().toInt()
        val operatorId = ByteArray(OdidMessageHandler.MAX_ID_BYTE_SIZE)

        byteBuffer.get(operatorId, 0, OdidMessageHandler.MAX_ID_BYTE_SIZE)
        var operatorIdStr =  String(operatorId);

        if (operatorIdStr.contains('\u0000')) {
            operatorIdStr = operatorIdStr.split('\u0000').first()
        }
        builder.setOperatorId(operatorIdStr)

        return builder.build()
    }

    private fun calcSpeed(value: Int, mult: Int): Double {
        return if (mult == 0) value * 0.25 else value * 0.75 + 255 * 0.25
    }

    private fun speedAccToEnum(acc: Int): Pigeon.SpeedAccuracy {
        if(acc == 10)   
            return Pigeon.SpeedAccuracy.meter_per_second_10
        else if(acc == 3)   
            return Pigeon.SpeedAccuracy.meter_per_second_3
        else if(acc == 1)   
            return Pigeon.SpeedAccuracy.meter_per_second_1
        //meter_per_second_0_3
        return Pigeon.SpeedAccuracy.Unknown
    }

    private fun calcDirection(value: Int, EW: Int): Int {
        return if (EW == 0) value else (value + 180)
    }

    private fun calcAltitude(value: Int): Double {
        return value.toDouble() / 2 - 1000
    }

    // to-do: remove

    fun receiveDataBluetooth(data: ByteArray): OdidMessage? {
        return parseAdvertisingData(data, 6)
    }

    fun receiveDataWifiBeacon(data: ByteArray): OdidMessage? {
        return parseAdvertisingData(data, 1)
    }

    private fun parseAdvertisingData(payload: ByteArray, offset: Int): OdidMessage? {
        if (offset <= 0 || payload.size < offset + MAX_MESSAGE_SIZE) return null

        return parseMessage(payload, offset)
    }

    private fun parseMessage(payload: ByteArray, offset: Int): OdidMessage? {
        if (payload.size < offset + MAX_MESSAGE_SIZE) return null
        val byteBuffer = ByteBuffer.wrap(payload, offset, MAX_MESSAGE_SIZE)
        byteBuffer.order(ByteOrder.LITTLE_ENDIAN)

        val header = OdidMessage.Header()
        val b: Int = (byteBuffer.get() and 0xFF.toByte()).toInt()
        val type = b and 0xF0 shr 4
        if (type > 5) return null
        header.type = OdidMessage.Type.values()[type]
        header.version = b and 0x0F

        return when (header.type) {
            OdidMessage.Type.BASIC_ID -> BasicIdMessage.fromBuffer(byteBuffer)
            OdidMessage.Type.LOCATION -> LocationMessage.fromBuffer(byteBuffer)
            OdidMessage.Type.OPERATOR_ID -> OperatorIdMessage.fromBuffer(byteBuffer)
            else -> null
        }
    }

//    private fun getReceiverLocation() {
//        locationProvider.lastLocation.addOnSuccessListener { location: android.location.Location? ->
//            if (location != null) {
//                receiverLocation = location
//            } else {
//                locationProvider.requestLocationUpdates(
//                        locationRequest,
//                        locationCallback,
//                        null
//                )
//            }
//        }
//    }
}