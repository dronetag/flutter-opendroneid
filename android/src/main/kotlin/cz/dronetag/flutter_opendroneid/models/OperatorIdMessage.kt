package cz.dronetag.flutter_opendroneid.models

import cz.dronetag.flutter_opendroneid.OdidMessageHandler
import java.nio.ByteBuffer

class OperatorIdMessage(
    var idType: Int,
    var operatorId: String,
    override val type: OdidMessage.Type = OdidMessage.Type.OPERATOR_ID
) : OdidMessage {
    override fun toJson(): MutableMap<String, Any> {
        return mutableMapOf("idType" to idType, "operatorId" to operatorId)
    }

    companion object {
        fun fromBuffer(byteBuffer: ByteBuffer): OperatorIdMessage {
            val type: Int = byteBuffer.get().toInt()
            val operatorId = ByteArray(OdidMessageHandler.MAX_ID_BYTE_SIZE)
            byteBuffer.get(operatorId, 0, OdidMessageHandler.MAX_ID_BYTE_SIZE)

            var operatorIdString = String(operatorId)

            if (operatorIdString.contains('\u0000')) {
                operatorIdString = operatorIdString.split('\u0000').first()
            }

            return OperatorIdMessage(
                type, operatorIdString
            )
        }
    }
}