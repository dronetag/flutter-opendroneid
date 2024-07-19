package cz.dronetag.flutter_opendroneid

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/// Contains common functinality for ODID scanners.
/// Derived scanners should use receiveData method that takes raw data and metadata
/// and sends it to stream
/// Creates [ODIDPayload] instances implementing Pigeon PayloadAPI
abstract class ODIDScanner(
    private val odidPayloadStreamHandler: StreamHandler
) : Pigeon.PayloadApi {

    companion object {
        const val MAX_MESSAGE_SIZE = 25
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

    override fun buildPayload(rawData: ByteArray, source: Pigeon.MessageSource, macAddress: String, btName: String?, rssi: Long, receivedTimestamp: Long): Pigeon.ODIDPayload {
        val builder = Pigeon.ODIDPayload.Builder()

        builder.setRawData(rawData)
        builder.setReceivedTimestamp(receivedTimestamp)
        builder.setMacAddress(macAddress)
        builder.setSource(source)
        builder.setRssi(rssi)
        builder.setBtName(btName)

        return builder.build()
    }
    
    /// receive data and metadata, create [ODIDPayload] and sent to stream
    fun receiveData(
        data: ByteArray, macAddress: String, source: Pigeon.MessageSource, rssi: Long = 0, btName: String? = null,
    ) {
        val payload = buildPayload(
            data, source, macAddress, btName, rssi, System.currentTimeMillis()
        )

        odidPayloadStreamHandler.send(payload.toList() as Any)        
    }

    /// returns ByteArray without first offset elements
    inline fun offsetData(data: ByteArray, offset: Int) : ByteArray = data.copyOfRange(offset, data.size)

    /// returns ByteArray with bytes from start to end
    inline fun getDataFromIndex(data: ByteArray, start: Int, end: Int) : ByteArray = data.copyOfRange(start, end)
}