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


    override fun fromBufferBasic(payload: ByteArray, offset: Long): Pigeon.BasicIdMessage? {
        if (payload.size < offset + MAX_MESSAGE_SIZE) return null
        val byteBuffer = ByteBuffer.wrap(payload, offset.toInt(), MAX_MESSAGE_SIZE)
        byteBuffer.order(ByteOrder.LITTLE_ENDIAN)
        return parseBasicMessage(byteBuffer)
    }

    override fun fromBufferLocation(payload: ByteArray, offset: Long): Pigeon.LocationMessage? {
        if (payload.size < offset + MAX_MESSAGE_SIZE) return null
        val byteBuffer = ByteBuffer.wrap(payload, offset.toInt(), MAX_MESSAGE_SIZE)
        byteBuffer.order(ByteOrder.LITTLE_ENDIAN)
        return parseLocationMessage(byteBuffer)
    }

    override fun fromBufferOperatorId(payload: ByteArray, offset: Long): Pigeon.OperatorIdMessage? {
        if (payload.size < offset + MAX_MESSAGE_SIZE) return null
        val byteBuffer = ByteBuffer.wrap(payload, offset.toInt(), MAX_MESSAGE_SIZE)
        byteBuffer.order(ByteOrder.LITTLE_ENDIAN)
        return parseOperatorIdMessage(byteBuffer)
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

    private fun parseBasicMessage(byteBuffer: ByteBuffer): Pigeon.BasicIdMessage {
        val builder = Pigeon.BasicIdMessage.Builder();
        val type: Int = byteBuffer.get().toInt()
        val uasId = ByteArray(OdidMessageHandler.MAX_ID_BYTE_SIZE)
        var uasIdStr = String(uasId)

        builder.setReceivedTimestamp(System.currentTimeMillis())
        builder.setIdType(Pigeon.IdType.values()[type and 0xF0 shr 4])
        builder.setUaType(Pigeon.UaType.values()[type and 0x0F])
        builder.setMacAddress("Unknown")
        byteBuffer.get(uasId, 0, OdidMessageHandler.MAX_ID_BYTE_SIZE)
        if (uasIdStr.contains('\u0000')) {
            uasIdStr = uasIdStr.split('\u0000').first()
        }
        builder.setUasId(uasIdStr)
        return builder.build()
    }

    private fun parseLocationMessage(byteBuffer: ByteBuffer): Pigeon.LocationMessage {
        val builder = Pigeon.LocationMessage.Builder();
        builder.setMacAddress("Unknown")
        builder.setReceivedTimestamp(System.currentTimeMillis())
        val message = builder.build()
        val b = byteBuffer.get().toInt()
        val status = b and 0xF0 shr 4
        val heightType = b and 0x04 shr 2
        val ewDirection = b and 0x02 shr 1
        val speedMult = b and 0x01
        val LAT_LONG_MULTIPLIER = 1e-7

        message.direction =
                calcDirection((byteBuffer.get() and 0xFF.toByte()).toInt(), ewDirection).toLong()

        message.speedHorizontal = calcSpeed((byteBuffer.get() and 0xFF.toByte()).toInt(), speedMult)
        message.speedVertical = calcSpeed(byteBuffer.get().toInt(), speedMult)

        message.latitude = LAT_LONG_MULTIPLIER * byteBuffer.int
        message.longitude = LAT_LONG_MULTIPLIER * byteBuffer.int

        message.altitudePressure = calcAltitude(byteBuffer.short.toUShort().toInt())
        message.altitudeGeodetic = calcAltitude(byteBuffer.short.toUShort().toInt())
        message.height = calcAltitude(byteBuffer.short.toUShort().toInt())
        val horiVertAccuracy = byteBuffer.get().toInt()
        message.horizontalAccuracy = Pigeon.HorizontalAccuracy.values()[horiVertAccuracy and 0x0F]
        message.verticalAccuracy = Pigeon.VerticalAccuracy.values()[horiVertAccuracy and 0xF0 shr 4]
        val speedBaroAccuracy = byteBuffer.get().toInt()
        message.baroAccuracy = Pigeon.VerticalAccuracy.values()[speedBaroAccuracy and 0xF0 shr 4]
        // to-do: fix
        Log.d("Message Handler", "Speed accacy" + (speedBaroAccuracy and 0x0F))
        message.speedAccuracy = Pigeon.SpeedAccuracy.values()[speedBaroAccuracy and 0x0F]
        message.time = byteBuffer.short.toUShort().toLong()
        message.timeAccuracy = (byteBuffer.get() and 0x0F).toInt() * 0.1

        return message
    }

    private fun parseOperatorIdMessage(byteBuffer: ByteBuffer): Pigeon.OperatorIdMessage {
        val builder = Pigeon.OperatorIdMessage.Builder();
        builder.setMacAddress("Unknown")
        builder.setReceivedTimestamp(System.currentTimeMillis())
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