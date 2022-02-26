package cz.dronetag.flutter_opendroneid

import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.content.Context
import android.content.IntentFilter
import android.net.wifi.WifiManager
import android.net.wifi.aware.WifiAwareManager
import androidx.annotation.NonNull
import io.flutter.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** FlutterOpendroneidPlugin */
class FlutterOpendroneidPlugin : FlutterPlugin, ActivityAware, Pigeon.Api {
    private var boundActivity: Activity? = null

    private lateinit var context: Context
    private lateinit var activity: Activity

    private val basicStreamHandler = StreamHandler()
    private val locationStreamHandler = StreamHandler()
    private val operatorIdStreamHandler = StreamHandler()
    private val bluetoothStateStreamHandler = StreamHandler()
    private val scanStateStreamHandler = StreamHandler()

    private var scanner: BluetoothScanner =
            BluetoothScanner(
                    basicStreamHandler, locationStreamHandler, operatorIdStreamHandler,
                    bluetoothStateStreamHandler,
                    scanStateStreamHandler,
            )
    private lateinit var wifiScanner: WifiScanner
    private lateinit var wifiNaNScanner: WifiNaNScanner

    override fun onAttachedToEngine(
            @NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding
    ) {
        Pigeon.Api.setup(flutterPluginBinding.binaryMessenger, this)

        StreamHandler.bindMultipleHandlers(
                flutterPluginBinding.binaryMessenger,
                mapOf(
                        "flutter_basic_messages" to basicStreamHandler,
                        "flutter_location_messages" to locationStreamHandler,
                        "flutter_operatorid_messages" to operatorIdStreamHandler,
                        "flutter_odid_bt_state" to bluetoothStateStreamHandler,
                        "flutter_odid_scan_state" to scanStateStreamHandler
                )
        )

        context = flutterPluginBinding.applicationContext

        val wifiManager: WifiManager? =
                context.getSystemService(Context.WIFI_SERVICE) as WifiManager?
        val wifiAwareManager: WifiAwareManager? =
                context.getSystemService(Context.WIFI_AWARE_SERVICE) as WifiAwareManager?


        wifiScanner =
                WifiScanner(
                        basicStreamHandler, locationStreamHandler, operatorIdStreamHandler,
                        bluetoothStateStreamHandler,
                        wifiManager,
                        context
                )
        wifiNaNScanner =
                WifiNaNScanner(
                        basicStreamHandler, locationStreamHandler, operatorIdStreamHandler,
                        bluetoothStateStreamHandler,
                        wifiAwareManager,
                        context
                )
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        binding.activity.registerReceiver(
                scanner.adapterStateReceiver,
                IntentFilter(BluetoothAdapter.ACTION_STATE_CHANGED)
        )
        boundActivity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        boundActivity?.unregisterReceiver(scanner.adapterStateReceiver)
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {}

    override fun onDetachedFromActivity() {}

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        Pigeon.Api.setup(binding.binaryMessenger, null)
        scanner.cancel()
        wifiScanner.cancel()
        StreamHandler.clearMultipleHandlers(
                binding.binaryMessenger,
                listOf(
                        "flutter_basic_messages",
                        "flutter_location_messages",
                        "flutter_operatorid_messages",
                        "flutter_odid_bt_state",
                        "flutter_odid_scan_state",
                )
        )
    }

    override fun startScanBluetooth(result: Pigeon.Result<Void>) {
        scanner.scan()
        Log.d("plugin", "Started scanning Bt")
        result.success(null)
    }

    override fun startScanWifi(result: Pigeon.Result<Void>) {
        wifiScanner.scan()
        wifiNaNScanner.scan()
        Log.d("plugin", "Started scanning WiFi")
        result.success(null)
    }

    override fun stopScanBluetooth(result: Pigeon.Result<Void>) {
        scanner.cancel()
        Log.d("plugin", "Bt Scan was stopped")
        result.success(null)
    }

    override fun stopScanWifi(result: Pigeon.Result<Void>) {
        wifiScanner.cancel()
        wifiNaNScanner.cancel()
        Log.d("plugin", "Wifi Scan was stopped")
        result.success(null)
    }

    override fun isScanningBluetooth(result: Pigeon.Result<Boolean>){
      result.success(scanner.isScanning)
    }

    override fun isScanningWifi(result: Pigeon.Result<Boolean>){
        result.success(wifiScanner.isScanning)
    }

    override fun bluetoothState(result: Pigeon.Result<Long>){
        result.success(scanner.getAdapterState().toLong())
    }

    override fun setAutorestartBluetooth(enable: Boolean?, result: Pigeon.Result<Void>) {
        scanner.shouldAutoRestart = enable ?: false
        result.success(null)
    }
}
