package cz.dronetag.flutter_opendroneid

import java.nio.ByteBuffer
import java.nio.ByteOrder
import kotlin.experimental.and

class OdidMessageHandler : Pigeon.MessageApi {
    companion object {
        const val MAX_MESSAGE_SIZE = 25
        const val MAX_ID_BYTE_SIZE = 20
        const val MAX_STRING_BYTE_SIZE = 23
        const val MAX_AUTH_DATA_PAGES = 16
        const val MAX_AUTH_PAGE_ZERO_SIZE = 17
        const val MAX_AUTH_PAGE_NON_ZERO_SIZE = 23
        const val MAX_AUTH_DATA =
                MAX_AUTH_PAGE_ZERO_SIZE + (MAX_AUTH_DATA_PAGES - 1) * MAX_AUTH_PAGE_NON_ZERO_SIZE
        const val MAX_MESSAGES_IN_PACK = 9
        val MAX_MESSAGE_PACK_SIZE: Int = MAX_MESSAGE_SIZE * MAX_MESSAGES_IN_PACK
        const val LAT_LONG_MULTIPLIER = 1e-7
    }

    override fun fromBufferBasic(
            payload: ByteArray,
            offset: Long,
            macAddress: String
    ): Pigeon.BasicIdMessage? {
        if (payload.size < offset + MAX_MESSAGE_SIZE) return null
        val byteBuffer = ByteBuffer.wrap(payload, offset.toInt(), MAX_MESSAGE_SIZE)
        byteBuffer.order(ByteOrder.LITTLE_ENDIAN)
        val b: Int = (byteBuffer.get() and 0xFF.toByte()).toInt()
        return parseBasicMessage(byteBuffer, macAddress)
    }

    override fun fromBufferLocation(
            payload: ByteArray,
            offset: Long,
            macAddress: String
    ): Pigeon.LocationMessage? {
        if (payload.size < offset + MAX_MESSAGE_SIZE) return null
        val byteBuffer = ByteBuffer.wrap(payload, offset.toInt(), MAX_MESSAGE_SIZE)
        byteBuffer.order(ByteOrder.LITTLE_ENDIAN)
        val b: Int = (byteBuffer.get() and 0xFF.toByte()).toInt()
        return parseLocationMessage(byteBuffer, macAddress)
    }

    override fun fromBufferOperatorId(
            payload: ByteArray,
            offset: Long,
            macAddress: String
    ): Pigeon.OperatorIdMessage? {
        if (payload.size < offset + MAX_MESSAGE_SIZE) return null
        val byteBuffer = ByteBuffer.wrap(payload, offset.toInt(), MAX_MESSAGE_SIZE)
        byteBuffer.order(ByteOrder.LITTLE_ENDIAN)
        val b: Int = (byteBuffer.get() and 0xFF.toByte()).toInt()
        return parseOperatorIdMessage(byteBuffer, macAddress)
    }

    override fun fromBufferSelfId(
            payload: ByteArray,
            offset: Long,
            macAddress: String
    ): Pigeon.SelfIdMessage? {
        if (payload.size < offset + MAX_MESSAGE_SIZE) return null
        val byteBuffer = ByteBuffer.wrap(payload, offset.toInt(), MAX_MESSAGE_SIZE)
        byteBuffer.order(ByteOrder.LITTLE_ENDIAN)
        val b: Int = (byteBuffer.get() and 0xFF.toByte()).toInt()
        return parseSelfIdMessage(byteBuffer, macAddress)
    }

    override fun fromBufferConnection(
            payload: ByteArray,
            offset: Long,
            macAddress: String
    ): Pigeon.ConnectionMessage? {
        if (payload.size < offset + MAX_MESSAGE_SIZE) return null
        val byteBuffer = ByteBuffer.wrap(payload, offset.toInt(), MAX_MESSAGE_SIZE)
        byteBuffer.order(ByteOrder.LITTLE_ENDIAN)
        val b: Int = (byteBuffer.get() and 0xFF.toByte()).toInt()
        return parseConnectionMessage(byteBuffer, macAddress)
    }

    override fun fromBufferAuthentication(
            payload: ByteArray,
            offset: Long,
            macAddress: String
    ): Pigeon.AuthenticationMessage? {
        if (payload.size < offset + MAX_MESSAGE_SIZE) return null
        val byteBuffer = ByteBuffer.wrap(payload, offset.toInt(), MAX_MESSAGE_SIZE)
        byteBuffer.order(ByteOrder.LITTLE_ENDIAN)
        val b: Int = (byteBuffer.get() and 0xFF.toByte()).toInt()
        return parseAuthenticationMessage(byteBuffer, macAddress)
    }

    override fun fromBufferSystemData(
            payload: ByteArray,
            offset: Long,
            macAddress: String
    ): Pigeon.SystemDataMessage? {
        if (payload.size < offset + MAX_MESSAGE_SIZE) return null
        val byteBuffer = ByteBuffer.wrap(payload, offset.toInt(), MAX_MESSAGE_SIZE)
        byteBuffer.order(ByteOrder.LITTLE_ENDIAN)
        val b: Int = (byteBuffer.get() and 0xFF.toByte()).toInt()
        return parseSystemDataMessage(byteBuffer, macAddress)
    }

    override fun determineMessageType(payload: ByteArray, offset: Long): Long? {
        if (payload.size < offset + MAX_MESSAGE_SIZE) return null

        val byteBuffer = ByteBuffer.wrap(payload, offset.toInt(), MAX_MESSAGE_SIZE)
        byteBuffer.order(ByteOrder.LITTLE_ENDIAN)

        val b: Int = (byteBuffer.get() and 0xFF.toByte()).toInt()
        val typeData = b and 0xF0 shr 4
        if (typeData > 5) return null
        return typeData.toLong()
    }

    private fun parseBasicMessage(
            byteBuffer: ByteBuffer,
            macAddress: String
    ): Pigeon.BasicIdMessage {
        val builder = Pigeon.BasicIdMessage.Builder()
        val type: Int = byteBuffer.get().toInt()
        val uasId = ByteArray(OdidMessageHandler.MAX_ID_BYTE_SIZE)
        builder.setReceivedTimestamp(System.currentTimeMillis())
        builder.setIdType(Pigeon.IdType.values()[type and 0xF0 shr 4])
        builder.setUaType(Pigeon.UaType.values()[type and 0x0F])
        builder.setMacAddress(macAddress)
        byteBuffer.get(uasId, 0, OdidMessageHandler.MAX_ID_BYTE_SIZE)
        var uasIdStr = String(uasId)
        if (uasIdStr.contains('\u0000')) {
            uasIdStr = uasIdStr.split('\u0000').first()
        }
        builder.setUasId(uasIdStr)
        return builder.build()
    }

    private fun parseLocationMessage(
            byteBuffer: ByteBuffer,
            macAddress: String
    ): Pigeon.LocationMessage {
        val builder = Pigeon.LocationMessage.Builder()
        val b = byteBuffer.get().toInt()
        val status = b and 0xF0 shr 4
        val heightType = b and 0x04 shr 2
        val ewDirection = b and 0x02 shr 1
        val speedMult = b and 0x01

        builder.setMacAddress(macAddress)
        builder.setReceivedTimestamp(System.currentTimeMillis())
        builder.setDirection(
                calcDirection((byteBuffer.get() and 0xFF.toByte()).toInt(), ewDirection)
        )
        builder.setSpeedHorizontal(
                calcSpeed((byteBuffer.get() and 0xFF.toByte()).toInt(), speedMult)
        )
        builder.setSpeedVertical(calcSpeed(byteBuffer.get().toInt(), speedMult))
        val lat = LAT_LONG_MULTIPLIER * byteBuffer.int
        builder.setLatitude(lat)
        builder.setLongitude(LAT_LONG_MULTIPLIER * byteBuffer.int)
        builder.setAltitudePressure(calcAltitude(byteBuffer.short.toUShort().toInt()))
        builder.setAltitudeGeodetic(calcAltitude(byteBuffer.short.toUShort().toInt()))
        builder.setHeight(calcAltitude(byteBuffer.short.toUShort().toInt()))
        val horiVertAccuracy = byteBuffer.get().toInt()
        builder.setHorizontalAccuracy(Pigeon.HorizontalAccuracy.values()[horiVertAccuracy and 0x0F])
        builder.setVerticalAccuracy(
                Pigeon.VerticalAccuracy.values()[horiVertAccuracy and 0xF0 shr 4]
        )
        val speedBaroAccuracy = byteBuffer.get().toInt()
        builder.setBaroAccuracy(Pigeon.VerticalAccuracy.values()[speedBaroAccuracy and 0xF0 shr 4])
        builder.setSpeedAccuracy(speedAccToEnum(speedBaroAccuracy and 0x0F))
        builder.setTime(byteBuffer.short.toUShort().toLong())
        builder.setTimeAccuracy((byteBuffer.get() and 0x0F).toInt() * 0.1)
        builder.setStatus(Pigeon.AircraftStatus.values()[status])
        builder.setHeightType(Pigeon.HeightType.values()[heightType])
        return builder.build()
    }

    private fun parseOperatorIdMessage(
            byteBuffer: ByteBuffer,
            macAddress: String
    ): Pigeon.OperatorIdMessage {
        val builder = Pigeon.OperatorIdMessage.Builder()
        builder.setMacAddress(macAddress)
        builder.setReceivedTimestamp(System.currentTimeMillis())
        val type: Int = byteBuffer.get().toInt()
        val operatorId = ByteArray(OdidMessageHandler.MAX_ID_BYTE_SIZE)

        byteBuffer.get(operatorId, 0, OdidMessageHandler.MAX_ID_BYTE_SIZE)
        var operatorIdStr = String(operatorId)

        if (operatorIdStr.contains('\u0000')) {
            operatorIdStr = operatorIdStr.split('\u0000').first()
        }
        builder.setOperatorId(operatorIdStr)

        return builder.build()
    }

    private fun parseSelfIdMessage(
            byteBuffer: ByteBuffer,
            macAddress: String
    ): Pigeon.SelfIdMessage {
        val builder = Pigeon.SelfIdMessage.Builder()
        var opDesc: String = ""
        var it = 0
        builder.setMacAddress(macAddress)
        builder.setReceivedTimestamp(System.currentTimeMillis())
        builder.setDescriptionType((byteBuffer.get() and 0xFF.toByte()).toLong())
        while (it++ < MAX_STRING_BYTE_SIZE) {
            opDesc += byteBuffer.get().toChar()
        }
        builder.setOperationDescription(opDesc)
        return builder.build()
    }

    private fun parseAuthenticationMessage(
            byteBuffer: ByteBuffer,
            macAddress: String
    ): Pigeon.AuthenticationMessage {
        val builder = Pigeon.AuthenticationMessage.Builder()
        builder.setMacAddress(macAddress)
        builder.setReceivedTimestamp(System.currentTimeMillis())
        val type = byteBuffer.get().toInt()
        val authType = type and 0xF0 shr 4
        val authDataPage: Long = (type and 0x0F).toLong()
        var authLength: Long = 0
        var authTimestamp: Long = 0
        var authLastPageIndex: Long = 0
        var authData: String = ""

        var offset: Long = 0
        var amount: Int = MAX_AUTH_PAGE_ZERO_SIZE
        if (authDataPage === 0L) {
            authLastPageIndex = (byteBuffer.get() and 0xFF.toByte()).toLong()
            authLength = (byteBuffer.get() and 0xFF.toByte()).toLong()
            authTimestamp = (byteBuffer.int and 0xFFFFFFFFL.toInt()).toLong()
            // For an explanation, please see the description for struct ODID_Auth_data in:
            // https://github.com/opendroneid/opendroneid-core-c/blob/master/libopendroneid/opendroneid.h
            val len: Long =
                    (authLastPageIndex * MAX_AUTH_PAGE_NON_ZERO_SIZE + MAX_AUTH_PAGE_ZERO_SIZE)
                            .toLong()
            if (authLastPageIndex >= MAX_AUTH_DATA_PAGES || authLength > len) {
                authLastPageIndex = 0
                authLength = 0
                authTimestamp = 0
            } else {
                // Display both normal authentication data and any possible additional data
                authLength = len
            }
        } else {
            offset = MAX_AUTH_PAGE_ZERO_SIZE + (authDataPage - 1) * MAX_AUTH_PAGE_NON_ZERO_SIZE
            amount = MAX_AUTH_PAGE_NON_ZERO_SIZE
        }
        if (authDataPage >= 0 && authDataPage < MAX_AUTH_DATA_PAGES)
                for (i in offset until offset + amount) authData += byteBuffer.get()
        builder.setAuthLength(authLength)
        builder.setAuthData(authData)
        builder.setAuthLastPageIndex(authLastPageIndex)
        builder.setAuthTimestamp(authTimestamp)
        builder.setAuthType(Pigeon.AuthType.values()[authType])
        builder.setAuthDataPage(authDataPage)
        return builder.build()
    }

    private fun parseConnectionMessage(
            byteBuffer: ByteBuffer,
            macAddress: String
    ): Pigeon.ConnectionMessage {
        val builder = Pigeon.ConnectionMessage.Builder()
        builder.setMacAddress(macAddress)
        builder.setReceivedTimestamp(System.currentTimeMillis())
        return builder.build()
    }

    private fun parseSystemDataMessage(
            byteBuffer: ByteBuffer,
            macAddress: String
    ): Pigeon.SystemDataMessage {
        val builder = Pigeon.SystemDataMessage.Builder()
        builder.setMacAddress(macAddress)
        builder.setReceivedTimestamp(System.currentTimeMillis())

        var b = byteBuffer.get().toInt()
        builder.setOperatorLocationType(Pigeon.OperatorLocationType.values()[b and 0x03])
        builder.setClassificationType(Pigeon.ClassificationType.values()[b and 0x1C shr 2])
        builder.setOperatorLatitude(LAT_LONG_MULTIPLIER * byteBuffer.int.toDouble())
        builder.setOperatorLongitude(LAT_LONG_MULTIPLIER * byteBuffer.int.toDouble())
        builder.setAreaCount((byteBuffer.short and 0xFFFF.toShort()).toLong())
        builder.setAreaRadius((byteBuffer.get() and 0xFF.toByte()).toLong() * 10)
        builder.setAreaCeiling((byteBuffer.short and 0xFFFF.toShort()).toDouble())
        builder.setAreaFloor((byteBuffer.short and 0xFFFF.toShort()).toDouble())
        b = byteBuffer.get().toInt()
        builder.setCategory(Pigeon.AircraftCategory.values()[b and 0xF0 shr 4])
        builder.setClassValue(Pigeon.AircraftClass.values()[b and 0x0F])
        builder.setOperatorAltitudeGeo((byteBuffer.short and 0xFFFF.toShort()).toDouble())

        return builder.build()
    }

    private fun calcSpeed(value: Int, mult: Int): Double {
        return if (mult == 0) value * 0.25 else value * 0.75 + 255 * 0.25
    }

    private fun speedAccToEnum(acc: Int): Pigeon.SpeedAccuracy {
        if (acc == 10) return Pigeon.SpeedAccuracy.meter_per_second_10
        else if (acc == 3) return Pigeon.SpeedAccuracy.meter_per_second_3
        else if (acc == 1) return Pigeon.SpeedAccuracy.meter_per_second_1
        // meter_per_second_0_3
        return Pigeon.SpeedAccuracy.Unknown
    }

    private fun calcDirection(value: Int, EW: Int): Double {
        return if (EW == 0) value.toDouble() else (value + 180).toDouble()
    }

    private fun calcAltitude(value: Int): Double {
        return value.toDouble() / 2 - 1000
    }
}
