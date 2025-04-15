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
    private val bluetoothOdidPayloadStreamHandler = StreamHandler()
    private val wifiOdidPayloadStreamHandler = StreamHandler()
    private val bluetoothStateStreamHandler = StreamHandler()
    private val wifiStateStreamHandler = StreamHandler()

    private var boundActivity: Activity? = null
    private var context: Context? = null

    private var bluetoothScanner: BluetoothScanner? = null
    private var wifiScanner: WifiScanner? = null
    private var wifiNaNScanner: WifiNaNScanner? = null

    @RequiresApi(Build.VERSION_CODES.O)
    override fun onAttachedToEngine(
            @NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding
    ) {
        Pigeon.Api.setup(flutterPluginBinding.binaryMessenger, this)

        StreamHandler.bindMultipleHandlers(
            flutterPluginBinding.binaryMessenger,
            mapOf(
                "flutter_odid_data_bt" to bluetoothOdidPayloadStreamHandler,
                "flutter_odid_data_wifi" to wifiOdidPayloadStreamHandler,
                "flutter_odid_state_bt" to bluetoothStateStreamHandler,
                "flutter_odid_state_wifi" to wifiStateStreamHandler
            )
        )

        context = flutterPluginBinding.applicationContext
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        boundActivity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {}

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {}

    override fun onDetachedFromActivity() {
        bluetoothScanner?.let{
            boundActivity?.unregisterReceiver(it.adapterStateReceiver)
        }
        wifiScanner?.let{
            boundActivity?.unregisterReceiver(it.adapterStateReceiver)
        }
    }

    @RequiresApi(Build.VERSION_CODES.O)
    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        Pigeon.Api.setup(binding.binaryMessenger, null)
        if(bluetoothScanner?.isScanning == true)
            bluetoothScanner?.cancel()
        if(wifiScanner?.isScanning == true)
            wifiScanner?.cancel()
        if(wifiNaNScanner?.isScanning == true)
            wifiNaNScanner?.cancel()
        StreamHandler.clearMultipleHandlers(
            binding.binaryMessenger,
            listOf(
                "flutter_odid_data_bt",
                "flutter_odid_data_wifi",
                "flutter_odid_state_bt",
                "flutter_odid_state_wifi",
            )
        )
    }

    override fun initialize(result: Pigeon.Result<Void>) {
        if(context == null || boundActivity == null) {
            return result.error(PluginNotAttachedException())
        }
        
        val wifiManager: WifiManager? =
            context!!.getSystemService(Context.WIFI_SERVICE) as WifiManager?
        val wifiAwareManager: WifiAwareManager? =
            context!!.getSystemService(Context.WIFI_AWARE_SERVICE) as WifiAwareManager?

        wifiScanner =
            WifiScanner(
                wifiOdidPayloadStreamHandler, wifiStateStreamHandler, wifiManager, context!!
            )
        wifiNaNScanner =
            WifiNaNScanner(
                wifiOdidPayloadStreamHandler, wifiStateStreamHandler, wifiAwareManager, context!!
            )

        bluetoothScanner = BluetoothScanner(
            bluetoothOdidPayloadStreamHandler, bluetoothStateStreamHandler,
        )

        boundActivity!!.registerReceiver(
            bluetoothScanner!!.adapterStateReceiver,
            IntentFilter(BluetoothAdapter.ACTION_STATE_CHANGED)
        )
        boundActivity!!.registerReceiver(
            wifiScanner!!.adapterStateReceiver,
            IntentFilter(WifiManager.ACTION_WIFI_SCAN_AVAILABILITY_CHANGED)
        )

        result.success(null)
    }

    override fun isInitialized(result: Pigeon.Result<Boolean>) {
        result.success(bluetoothScanner != null && wifiScanner != null && wifiNaNScanner != null)
    }

    @RequiresApi(Build.VERSION_CODES.O)
    override fun startScanBluetooth(result: Pigeon.Result<Void>) {
        bluetoothScanner?.let {
            it.scan()
            return result.success(null)
        }
        return result.error(PluginNotInitializedException())
    }

    override fun startScanWifi(result: Pigeon.Result<Void>) {
        if(wifiScanner == null || wifiNaNScanner == null) {
            return result.error(PluginNotInitializedException())
        }
        wifiScanner!!.scan()
        wifiNaNScanner!!.scan()
        result.success(null)
    }

    override fun stopScanBluetooth(result: Pigeon.Result<Void>) {
        bluetoothScanner?.let {
            it.cancel()
            return result.success(null)
        }
        return result.error(PluginNotInitializedException())
    }

    @RequiresApi(Build.VERSION_CODES.O)
    override fun stopScanWifi(result: Pigeon.Result<Void>) {
        if(wifiScanner == null || wifiNaNScanner == null) {
            return result.error(PluginNotInitializedException())
        }
        wifiScanner!!.cancel()
        wifiNaNScanner!!.cancel()
        return result.success(null)
    }

    override fun setBtScanPriority(priority: Pigeon.ScanPriority, result: Pigeon.Result<Void>) {
        bluetoothScanner?.let {
            it.setScanPriority(priority)
            return result.success(null)   
        }
        return result.error(PluginNotInitializedException())
    }

    override fun isScanningBluetooth(result: Pigeon.Result<Boolean>){
        bluetoothScanner?.let {
            return result.success(it.isScanning)
        }
        return result.error(PluginNotInitializedException())
    }

    override fun isScanningWifi(result: Pigeon.Result<Boolean>){
        if(wifiScanner == null || wifiNaNScanner == null) {
            return result.error(PluginNotInitializedException())
        }
        return result.success(wifiScanner!!.isScanning || wifiNaNScanner!!.isScanning)
    }

    override fun bluetoothState(result: Pigeon.Result<Long>){
        bluetoothScanner?.let {
            return result.success(it.getAdapterState().toLong())
        }
        return result.error(PluginNotInitializedException())
    }

    override fun wifiState(result: Pigeon.Result<Long>){
        wifiScanner?.let {
            return result.success(it.getAdapterState().toLong())
        }
        return result.error(PluginNotInitializedException())
    }

    @RequiresApi(Build.VERSION_CODES.O)
    override fun btExtendedSupported(result: Pigeon.Result<Boolean>) {
        bluetoothScanner?.let {
            return result.success(it.isBtExtendedSupported());
        }
        return result.error(PluginNotInitializedException())
    }

    @RequiresApi(Build.VERSION_CODES.O)
    override fun btMaxAdvDataLen(result: Pigeon.Result<Long>) {
        bluetoothScanner?.let {
            return result.success(it.maxAdvDataLen().toLong());
        }
        return result.error(PluginNotInitializedException())
    }

    override fun wifiNaNSupported(result: Pigeon.Result<Boolean>) {
        wifiNaNScanner?.let {
            return result.success(it.isWifiAwareSupported());
        }
        return result.error(PluginNotInitializedException())
    }
}
