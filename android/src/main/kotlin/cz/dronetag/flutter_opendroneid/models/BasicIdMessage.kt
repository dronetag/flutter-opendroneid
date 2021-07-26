package cz.dronetag.flutter_opendroneid.models

import cz.dronetag.flutter_opendroneid.OdidMessageHandler
import java.nio.ByteBuffer

class BasicIdMessage(
    var idType: Int,
    var uaType: Int,
    var uasId: String,
    override val type: OdidMessage.Type = OdidMessage.Type.BASIC_ID
) : OdidMessage {
    override fun toJson(): MutableMap<String, Any> {
        return mutableMapOf("idType" to idType, "uaType" to uaType, "uasId" to uasId)
    }

    companion object {
        fun fromBuffer(byteBuffer: ByteBuffer): BasicIdMessage {
            val type: Int = byteBuffer.get().toInt()
            val idType = type and 0xF0 shr 4
            val uaType = type and 0x0F
            var uasId = ByteArray(OdidMessageHandler.MAX_ID_BYTE_SIZE)
            byteBuffer.get(uasId, 0, OdidMessageHandler.MAX_ID_BYTE_SIZE)


            return BasicIdMessage(
                idType, uaType, String(uasId).trim()
            )
        }
    }
}