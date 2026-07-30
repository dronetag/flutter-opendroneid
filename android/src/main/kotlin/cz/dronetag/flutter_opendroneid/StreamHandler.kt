package cz.dronetag.flutter_opendroneid

import android.os.Handler
import android.os.Looper

interface OdidPayloadSink {
    fun send(payload: ODIDPayload)
}

interface BooleanStateSink {
    fun send(state: Boolean)
}

private val mainHandler = Handler(Looper.getMainLooper())

class BluetoothOdidPayloadStreamHandler : StreamOdidPayloadBtStreamHandler(), OdidPayloadSink {
    private var sink: PigeonEventSink<ODIDPayload>? = null

    override fun onListen(p0: Any?, sink: PigeonEventSink<ODIDPayload>) {
        this.sink = sink
    }

    override fun onCancel(p0: Any?) {
        sink = null
    }

    override fun send(payload: ODIDPayload) {
        mainHandler.post { sink?.success(payload) }
    }
}

class WifiOdidPayloadStreamHandler : StreamOdidPayloadWifiStreamHandler(), OdidPayloadSink {
    private var sink: PigeonEventSink<ODIDPayload>? = null

    override fun onListen(p0: Any?, sink: PigeonEventSink<ODIDPayload>) {
        this.sink = sink
    }

    override fun onCancel(p0: Any?) {
        sink = null
    }

    override fun send(payload: ODIDPayload) {
        mainHandler.post { sink?.success(payload) }
    }
}

class BluetoothStateStreamHandler : StreamBluetoothStateStreamHandler(), BooleanStateSink {
    private var sink: PigeonEventSink<Boolean>? = null

    override fun onListen(p0: Any?, sink: PigeonEventSink<Boolean>) {
        this.sink = sink
    }

    override fun onCancel(p0: Any?) {
        sink = null
    }

    override fun send(state: Boolean) {
        mainHandler.post { sink?.success(state) }
    }
}

class WifiStateStreamHandler : StreamWifiStateStreamHandler(), BooleanStateSink {
    private var sink: PigeonEventSink<Boolean>? = null

    override fun onListen(p0: Any?, sink: PigeonEventSink<Boolean>) {
        this.sink = sink
    }

    override fun onCancel(p0: Any?) {
        sink = null
    }

    override fun send(state: Boolean) {
        mainHandler.post { sink?.success(state) }
    }
}
