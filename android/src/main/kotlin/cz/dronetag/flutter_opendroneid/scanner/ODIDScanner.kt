package cz.dronetag.flutter_opendroneid

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/// Contains common functinality for ODID scanners.
/// Derived scanners should use receiveData method that takes raw data and metadata
/// and sends it to stream
/// Creates [ODIDPayload] instances implementing Pigeon PayloadAPI
abstract class ODIDScanner(
    private val odidPayloadStreamHandler: OdidPayloadSink
) : PayloadApi {

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

    override fun buildPayload(rawData: ByteArray, receivedTimestamp: Long, metadata: ODIDMetadata): ODIDPayload {
        return ODIDPayload(rawData, receivedTimestamp, metadata)
    }
    
    /// receive data and metadata, create [ODIDPayload] and sent to stream
    fun receiveData(
        data: ByteArray, metadata: ODIDMetadata,
    ) {
        val payload = buildPayload(
            data, System.currentTimeMillis(), metadata,
        )

        odidPayloadStreamHandler.send(payload)
    }

    /// returns ByteArray without first offset elements
    inline fun offsetData(data: ByteArray, offset: Int) : ByteArray = data.copyOfRange(offset, data.size)

    /// returns ByteArray with bytes from start to end
    inline fun getDataFromIndex(data: ByteArray, start: Int, end: Int) : ByteArray = data.copyOfRange(start, end)
}
