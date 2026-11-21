package cz.dronetag.flutter_opendroneid

import android.os.Handler
import android.os.Looper
import io.flutter.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin

interface OdidSink {
    fun onPayload(payload: ODIDPayload)
    fun onBluetoothScanActive(isActive: Boolean)
    fun onWifiScanActive(isActive: Boolean)
}

class FlutterApiSink(
    private val binding: FlutterPlugin.FlutterPluginBinding,
) : OdidSink {
    private val mainHandler = Handler(Looper.getMainLooper())

    private fun onMain(block: () -> Unit) {
        if (Looper.myLooper() == Looper.getMainLooper()) block() else mainHandler.post(block)
    }

    private fun withApi(block: (OdidScannerFlutterApi) -> Unit) {
        onMain {
            val api = OdidScannerFlutterApiRegistrar().getInstance(binding) ?: return@onMain
            try {
                block(api)
            } catch (error: Throwable) {
                // A stale registration can survive a hot restart; never crash the scanner.
                Log.w("FlutterOpenDroneId", "Dropping native callback", error)
            }
        }
    }

    override fun onPayload(payload: ODIDPayload) = withApi { it.onOdidPayload(payload) }

    override fun onBluetoothScanActive(isActive: Boolean) =
        withApi { it.onBluetoothScanActive(isActive) }

    override fun onWifiScanActive(isActive: Boolean) =
        withApi { it.onWifiScanActive(isActive) }
}
