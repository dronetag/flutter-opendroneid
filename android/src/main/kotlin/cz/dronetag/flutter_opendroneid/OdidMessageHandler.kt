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
import kotlin.experimental.and

class OdidMessageHandler {
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