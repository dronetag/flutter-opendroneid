package cz.dronetag.flutter_opendroneid

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/// Contains common functinality for ODID scanners 
/// Creates [ODIDPayload] instances implementin Pigeon PayloadAPI
abstract class ODIDScanner(
    val odidPayloadStreamHandler: StreamHandler
) : Pigeon.PayloadApi {

    companion object {
        const val MAX_MESSAGE_SIZE = 25
        const val BT_OFFSET = 6
        const val WIFI_BEACON_OFFSET = 5
        const val WIFI_NAN_OFFSET = 1
    }

    var isScanning = false
    get() = field
    set(value) {
        field = value
    }
    
    val adapterStateReceiver: BroadcastReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            onAdapterStateReceived()
        }
    }

    abstract fun scan()

    abstract fun cancel()

    abstract fun onAdapterStateReceived()

    override fun getPayload(rawData: ByteArray, source: Pigeon.MessageSource, macAddress: String, rssi: Long, receivedTimestamp: Long): Pigeon.ODIDPayload {
        val builder = Pigeon.ODIDPayload.Builder()

        builder.setRawData(rawData)
        builder.setReceivedTimestamp(receivedTimestamp)
        builder.setMacAddress(macAddress)
        builder.setSource(source)
        builder.setRssi(rssi)

        return builder.build()
    }
    
    /// receive data and metadata, create [ODIDPayload] and sent to stream
    fun receiveData(
        data: ByteArray, macAddress: String, source: Pigeon.MessageSource, rssi: Long = 0
    ) {
        val payload = getPayload(
            data, source, macAddress, rssi, System.currentTimeMillis()
        )

        odidPayloadStreamHandler.send(payload?.toList() as Any)        
    }

    /// returs [ByteArray] without first offset elements
    inline fun offsetData(data: ByteArray, offset: Int) : ByteArray = data.copyOfRange(offset, data.size)
}