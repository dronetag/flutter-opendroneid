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

    override fun buildPayload(rawData: ByteArray, receivedTimestamp: Long, metadata: Pigeon.ODIDMetadata): Pigeon.ODIDPayload {
        val builder = Pigeon.ODIDPayload.Builder().apply {
            setRawData(rawData)
            setReceivedTimestamp(receivedTimestamp)
            setMetadata(metadata)
        }

        return builder.build()
    }
    
    /// receive data and metadata, create [ODIDPayload] and sent to stream
    fun receiveData(
        data: ByteArray, metadata: Pigeon.ODIDMetadata,
    ) {
        val payload = buildPayload(
            data, System.currentTimeMillis(), metadata,
        )

        odidPayloadStreamHandler.send(payload.toList() as Any)        
    }

    /// returns ByteArray without first offset elements
    inline fun offsetData(data: ByteArray, offset: Int) : ByteArray = data.copyOfRange(offset, data.size)

    /// returns ByteArray with bytes from start to end
    inline fun getDataFromIndex(data: ByteArray, start: Int, end: Int) : ByteArray = data.copyOfRange(start, end)

    /// Converts a duration in milliseconds to a frequency in Megahertz.
    fun durationToFrequencyMHz(durationMs: Long): Double {
        // Check if the input is positive
        if (durationMs <= 0) {
            return 0.0
        }

        // Convert milliseconds to seconds
        val durationSeconds = durationMs / 1000.0

        // Calculate frequency in Hertz
        val frequencyHz = 1.0 / durationSeconds

        // Convert frequency from Hertz to Megahertz
        val frequencyMHz = frequencyHz / 1_000_000.0

        return frequencyMHz
    }
}