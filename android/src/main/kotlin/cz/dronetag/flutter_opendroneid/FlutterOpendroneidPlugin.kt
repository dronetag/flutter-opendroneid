package cz.dronetag.flutter_opendroneid

import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.content.Context
import android.content.IntentFilter
import android.net.wifi.WifiManager
import android.net.wifi.aware.WifiAwareManager
import android.os.Build
import androidx.annotation.NonNull
import androidx.annotation.RequiresApi
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding

/**
 * Android host implementation of the Pigeon `OdidScannerHostApi`.
 *
 * The plugin registers itself with the generated `OdidScannerHostApiRegistrar`
 * on engine attach and unregisters that exact instance on detach. Scanner
 * events flow through [FlutterApiSink] directly to Dart; no event channels are
 * used. `initialize` must run on the platform main thread because it registers
 * broadcast receivers against the current [Activity].
 */
class FlutterOpendroneidPlugin : FlutterPlugin, ActivityAware, OdidScannerHostApi {

    private lateinit var sink: FlutterApiSink

    private var boundActivity: Activity? = null
    private var context: Context? = null

    private var bluetoothScanner: BluetoothScanner? = null
    private var wifiScanner: WifiScanner? = null
    private var wifiNaNScanner: WifiNaNScanner? = null

    /**
     * Creates the callback sink and registers this instance for the engine.
     */
    @RequiresApi(Build.VERSION_CODES.O)
    override fun onAttachedToEngine(
            @NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding
    ) {
        sink = FlutterApiSink(flutterPluginBinding)
        OdidScannerHostApiRegistrar().register(this, flutterPluginBinding)
        context = flutterPluginBinding.applicationContext
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        boundActivity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {}

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {}

    override fun onDetachedFromActivity() {
        bluetoothScanner?.let {
            boundActivity?.unregisterReceiver(it.adapterStateReceiver)
        }
        wifiScanner?.let {
            boundActivity?.unregisterReceiver(it.adapterStateReceiver)
        }
    }

    /**
     * Unregisters this instance, stops every scanner, and drops references.
     */
    @RequiresApi(Build.VERSION_CODES.O)
    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        OdidScannerHostApiRegistrar().unregister(this, binding)
        if (bluetoothScanner?.isScanning == true)
            bluetoothScanner?.cancel()
        if (wifiScanner?.isScanning == true)
            wifiScanner?.cancel()
        if (wifiNaNScanner?.isScanning == true)
            wifiNaNScanner?.cancel()
        bluetoothScanner = null
        wifiScanner = null
        wifiNaNScanner = null
    }

    override fun initialize() {
        if (context == null || boundActivity == null) {
            notAttached()
        }

        val wifiManager: WifiManager? =
            context!!.getSystemService(Context.WIFI_SERVICE) as WifiManager?
        val wifiAwareManager: WifiAwareManager? =
            context!!.getSystemService(Context.WIFI_AWARE_SERVICE) as WifiAwareManager?

        wifiScanner = WifiScanner(sink, wifiManager, context!!)
        wifiNaNScanner = WifiNaNScanner(sink, wifiAwareManager, context!!)
        bluetoothScanner = BluetoothScanner(sink)

        boundActivity!!.registerReceiver(
            bluetoothScanner!!.adapterStateReceiver,
            IntentFilter(BluetoothAdapter.ACTION_STATE_CHANGED)
        )
        boundActivity!!.registerReceiver(
            wifiScanner!!.adapterStateReceiver,
            IntentFilter(WifiManager.ACTION_WIFI_SCAN_AVAILABILITY_CHANGED)
        )
    }

    override fun isInitialized(): Boolean =
        bluetoothScanner != null && wifiScanner != null && wifiNaNScanner != null

    @RequiresApi(Build.VERSION_CODES.O)
    override fun startScanBluetooth(serviceUuid: String?) {
        val scanner = bluetoothScanner ?: notInitialized()
        scanner.setServiceUuid(serviceUuid)
        scanner.scan()
    }

    override fun startScanWifi() {
        val wifi = wifiScanner ?: notInitialized()
        val nan = wifiNaNScanner ?: notInitialized()
        wifi.scan()
        nan.scan()
    }

    override fun stopScanBluetooth() {
        (bluetoothScanner ?: notInitialized()).cancel()
    }

    @RequiresApi(Build.VERSION_CODES.O)
    override fun stopScanWifi() {
        (wifiScanner ?: notInitialized()).cancel()
        (wifiNaNScanner ?: notInitialized()).cancel()
    }

    override fun setBtScanPriority(priority: ScanPriority) {
        (bluetoothScanner ?: notInitialized()).setScanPriority(priority)
    }

    override fun setBtServiceUuid(serviceUuid: String?) {
        (bluetoothScanner ?: notInitialized()).setServiceUuid(serviceUuid)
    }

    override fun isScanningBluetooth(): Boolean =
        (bluetoothScanner ?: notInitialized()).isScanning

    override fun isScanningWifi(): Boolean {
        val wifi = wifiScanner ?: notInitialized()
        val nan = wifiNaNScanner ?: notInitialized()
        return wifi.isScanning || nan.isScanning
    }

    @RequiresApi(Build.VERSION_CODES.O)
    override suspend fun bluetoothState(): Long =
        (bluetoothScanner ?: notInitialized()).getAdapterState().toLong()

    override fun wifiState(): Long =
        (wifiScanner ?: notInitialized()).getAdapterState().toLong()

    @RequiresApi(Build.VERSION_CODES.O)
    override fun btExtendedSupported(): Boolean =
        (bluetoothScanner ?: notInitialized()).isBtExtendedSupported()

    @RequiresApi(Build.VERSION_CODES.O)
    override fun btMaxAdvDataLen(): Long =
        (bluetoothScanner ?: notInitialized()).maxAdvDataLen().toLong()

    override fun wifiNaNSupported(): Boolean =
        (wifiNaNScanner ?: notInitialized()).isWifiAwareSupported()

    /** Error thrown when a host method runs before [initialize]. */
    private fun notInitialized(): Nothing = throw FlutterError(
        "uninitialized",
        "Plugin was not initialized",
        "Call the initialize method before using the plugin",
    )

    /** Error thrown when [initialize] runs without an attached Activity. */
    private fun notAttached(): Nothing = throw FlutterError(
        "uninitialized",
        "Unable to initialize, plugin was not attached to activity",
        null,
    )
}
