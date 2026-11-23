package cz.dronetag.flutter_opendroneid

import android.os.Handler
import android.os.Looper
import io.flutter.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin

/**
 * Receives scanner events and forwards them to the Dart `OdidScannerFlutterApi`.
 *
 * Implementations must be safe to call from scanner threads; [FlutterApiSink]
 * marshals to the platform main thread.
 */
interface OdidSink {
    fun onPayload(payload: ODIDPayload)
    fun onBluetoothScanActive(isActive: Boolean)
    fun onWifiScanActive(isActive: Boolean)
}

/**
 * Resolves the Dart callback for each event instead of caching it.
 *
 * Pigeon keeps Dart registrations in process memory and a hot restart replaces
 * them; looking up per event picks up the new isolate. Calls are marshalled to
 * the main looper because Flutter API callbacks must run on the thread that
 * registered them, and failures from a stale registration are logged instead of
 * crashing the scanner.
 */
class FlutterApiSink(
    private val binding: FlutterPlugin.FlutterPluginBinding,
) : OdidSink {
    private val mainHandler = Handler(Looper.getMainLooper())

    private fun onMain(block: () -> Unit) {
        if (Looper.myLooper() == Looper.getMainLooper()) block() else mainHandler.post(block)
    }

    private fun withApi(block: (OdidScannerFlutterApi) -> Unit) {
        onMain {
            val api = OdidScannerFlutterApiRegistrar().getInstance(binding)
            if (api == null) {
                Log.w("FlutterOpenDroneId", "Dropping native callback: no Dart API registered")
                return@onMain
            }
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
