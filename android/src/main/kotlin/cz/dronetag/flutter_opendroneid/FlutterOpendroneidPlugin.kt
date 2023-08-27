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

    private val odidPayloadStreamHandler = StreamHandler()
    private val bluetoothStateStreamHandler = StreamHandler()
    private val wifiStateStreamHandler = StreamHandler()

    private var scanner: BluetoothScanner =
            BluetoothScanner(
                    odidPayloadStreamHandler, bluetoothStateStreamHandler,
            )
    private lateinit var wifiScanner: WifiScanner
    private lateinit var wifiNaNScanner: WifiNaNScanner

    @RequiresApi(Build.VERSION_CODES.O)
    override fun onAttachedToEngine(
            @NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding
    ) {
        Pigeon.Api.setup(flutterPluginBinding.binaryMessenger, this)

        StreamHandler.bindMultipleHandlers(
                flutterPluginBinding.binaryMessenger,
                mapOf(
                    "flutter_odid_data" to odidPayloadStreamHandler,
                    "flutter_odid_bt_state" to bluetoothStateStreamHandler,
                    "flutter_odid_wifi_state" to wifiStateStreamHandler
                )
        )

        context = flutterPluginBinding.applicationContext

        val wifiManager: WifiManager? =
                context.getSystemService(Context.WIFI_SERVICE) as WifiManager?
        val wifiAwareManager: WifiAwareManager? =
                context.getSystemService(Context.WIFI_AWARE_SERVICE) as WifiAwareManager?


        wifiScanner =
                WifiScanner(
                        odidPayloadStreamHandler, wifiStateStreamHandler, wifiManager, context
                )
        wifiNaNScanner =
                WifiNaNScanner(
                        odidPayloadStreamHandler, wifiStateStreamHandler, wifiAwareManager, context
                )
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        binding.activity.registerReceiver(
                scanner.adapterStateReceiver,
                IntentFilter(BluetoothAdapter.ACTION_STATE_CHANGED)
        )
        binding.activity.registerReceiver(
            wifiScanner.adapterStateReceiver,
            IntentFilter(WifiManager.ACTION_WIFI_SCAN_AVAILABILITY_CHANGED)
        )
        boundActivity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        boundActivity?.unregisterReceiver(scanner.adapterStateReceiver)
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {}

    override fun onDetachedFromActivity() {}

    @RequiresApi(Build.VERSION_CODES.O)
    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        Pigeon.Api.setup(binding.binaryMessenger, null)
        scanner.cancel()
        wifiScanner.cancel()
        wifiNaNScanner.cancel()
        StreamHandler.clearMultipleHandlers(
            binding.binaryMessenger,
            listOf(
                "flutter_odid_data",
                "flutter_odid_bt_state",
                "flutter_odid_wifi_state",
            )
        )
    }

    @RequiresApi(Build.VERSION_CODES.O)
    override fun startScanBluetooth(result: Pigeon.Result<Void>) {
        scanner.scan()
        result.success(null)
    }

    override fun startScanWifi(result: Pigeon.Result<Void>) {
        wifiScanner.scan()
        wifiNaNScanner.scan()
        result.success(null)
    }

    override fun stopScanBluetooth(result: Pigeon.Result<Void>) {
        scanner.cancel()
        result.success(null)
    }

    @RequiresApi(Build.VERSION_CODES.O)
    override fun stopScanWifi(result: Pigeon.Result<Void>) {
        wifiScanner.cancel()
        wifiNaNScanner.cancel()
        result.success(null)
    }

    override fun setBtScanPriority(priority: Pigeon.ScanPriority, result: Pigeon.Result<Void>) {
        scanner.setScanPriority(priority)
        result.success(null)
    }

    override fun isScanningBluetooth(result: Pigeon.Result<Boolean>){
      result.success(scanner.isScanning)
    }

    override fun isScanningWifi(result: Pigeon.Result<Boolean>){
        result.success(wifiScanner.isScanning || wifiNaNScanner.isScanning)
    }

    override fun bluetoothState(result: Pigeon.Result<Long>){
        result.success(scanner.getAdapterState().toLong())
    }

    override fun wifiState(result: Pigeon.Result<Long>){
        result.success(wifiScanner.getAdapterState().toLong())
    }

    @RequiresApi(Build.VERSION_CODES.O)
    override fun btExtendedSupported(result: Pigeon.Result<Boolean>) {
        result.success(scanner.isBtExtendedSupported());
    }

    @RequiresApi(Build.VERSION_CODES.O)
    override fun btMaxAdvDataLen(result: Pigeon.Result<Long>) {
        result.success(scanner.maxAdvDataLen().toLong());
    }

    override fun wifiNaNSupported(result: Pigeon.Result<Boolean>) {
        result.success(wifiNaNScanner.isWifiAwareSupported());
    }
}
