package cz.dronetag.flutter_opendroneid

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/// Common base for ODID scanners.
///
/// Derived scanners call [receiveData] with raw bytes and radio metadata. The
/// payload is timestamped here and forwarded through [OdidSink]; no platform
/// channel or event sink is involved.
abstract class ODIDScanner(
    private val sink: OdidSink,
) {

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

    fun buildPayload(
        rawData: ByteArray,
        receivedTimestamp: Long,
        metadata: ODIDMetadata,
    ): ODIDPayload = ODIDPayload(rawData, receivedTimestamp, metadata)

    /// Creates an [ODIDPayload] with the current time and sends it to Dart.
    fun receiveData(
        data: ByteArray, metadata: ODIDMetadata,
    ) {
        val payload = buildPayload(
            data, System.currentTimeMillis(), metadata,
        )

        sink.onPayload(payload)
    }

    /// Returns the bytes after skipping the first [offset] elements.
    inline fun offsetData(data: ByteArray, offset: Int): ByteArray =
        data.copyOfRange(offset, data.size)

    /// Returns the bytes in the half-open range `[start, end)`.
    inline fun getDataFromIndex(data: ByteArray, start: Int, end: Int): ByteArray =
        data.copyOfRange(start, end)
}
