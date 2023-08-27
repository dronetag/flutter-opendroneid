package cz.dronetag.flutter_opendroneid

import java.nio.ByteBuffer
import java.nio.ByteOrder
import kotlin.experimental.and
import io.flutter.Log

class OdidPayloadHandler : Pigeon.PayloadApi {

    override fun getPayload(rawData: ByteArray, source: Pigeon.MessageSource, macAddress: String, rssi: Long, receivedTimestamp: Long): Pigeon.ODIDPayload {
        val builder = Pigeon.ODIDPayload.Builder()

        builder.setRawData(rawData)
        builder.setReceivedTimestamp(receivedTimestamp)
        builder.setMacAddress(macAddress)
        builder.setSource(source)
        builder.setRssi(rssi)

        return builder.build()
    }
}
