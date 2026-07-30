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

/** FlutterOpendroneidPlugin */
class FlutterOpendroneidPlugin : FlutterPlugin, ActivityAware, Api {
    private val bluetoothOdidPayloadStreamHandler = BluetoothOdidPayloadStreamHandler()
    private val wifiOdidPayloadStreamHandler = WifiOdidPayloadStreamHandler()
    private val bluetoothStateStreamHandler = BluetoothStateStreamHandler()
    private val wifiStateStreamHandler = WifiStateStreamHandler()

    private var boundActivity: Activity? = null
    private var context: Context? = null

    private var bluetoothScanner: BluetoothScanner? = null
    private var wifiScanner: WifiScanner? = null
    private var wifiNaNScanner: WifiNaNScanner? = null

    private var receiversRegistered = false

    @RequiresApi(Build.VERSION_CODES.O)
    override fun onAttachedToEngine(
        flutterPluginBinding: FlutterPlugin.FlutterPluginBinding
    ) {
        Api.setUp(flutterPluginBinding.binaryMessenger, this)

        StreamOdidPayloadBtStreamHandler.register(
            flutterPluginBinding.binaryMessenger, bluetoothOdidPayloadStreamHandler
        )
        StreamOdidPayloadWifiStreamHandler.register(
            flutterPluginBinding.binaryMessenger, wifiOdidPayloadStreamHandler
        )
        StreamBluetoothStateStreamHandler.register(
            flutterPluginBinding.binaryMessenger, bluetoothStateStreamHandler
        )
        StreamWifiStateStreamHandler.register(
            flutterPluginBinding.binaryMessenger, wifiStateStreamHandler
        )

        context = flutterPluginBinding.applicationContext
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        boundActivity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {}

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {}

    override fun onDetachedFromActivity() {
        if (!receiversRegistered) return
        receiversRegistered = false
        bluetoothScanner?.let{
            boundActivity?.unregisterReceiver(it.adapterStateReceiver)
        }
        wifiScanner?.let{
            boundActivity?.unregisterReceiver(it.adapterStateReceiver)
        }
    }

    @RequiresApi(Build.VERSION_CODES.O)
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        Api.setUp(binding.binaryMessenger, null)
        if(bluetoothScanner?.isScanning == true)
            bluetoothScanner?.cancel()
        if(wifiScanner?.isScanning == true)
            wifiScanner?.cancel()
        if(wifiNaNScanner?.isScanning == true)
            wifiNaNScanner?.cancel()
    }

    override fun initialize(callback: (Result<Unit>) -> Unit) {
        if(context == null || boundActivity == null) {
            return callback(Result.failure(PluginNotAttachedException()))
        }
        
        val wifiManager: WifiManager? =
            context!!.getSystemService(Context.WIFI_SERVICE) as WifiManager?
        val wifiAwareManager: WifiAwareManager? =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context!!.getSystemService(Context.WIFI_AWARE_SERVICE) as WifiAwareManager?
            } else {
                TODO("VERSION.SDK_INT < O")
            }

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
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            boundActivity!!.registerReceiver(
                wifiScanner!!.adapterStateReceiver,
                IntentFilter(WifiManager.ACTION_WIFI_SCAN_AVAILABILITY_CHANGED)
            )
        }
        receiversRegistered = true

        callback(Result.success(Unit))
    }

    override fun isInitialized(callback: (Result<Boolean>) -> Unit) {
        callback(Result.success(bluetoothScanner != null && wifiScanner != null && wifiNaNScanner != null))
    }

    @RequiresApi(Build.VERSION_CODES.O)
    override fun startScanBluetooth(serviceUuid: String?, callback: (Result<Unit>) -> Unit) {
        bluetoothScanner?.let {
            it.setServiceUuid(serviceUuid)
            it.scan()

            return callback(Result.success(Unit))
        }
        return callback(Result.failure(PluginNotInitializedException()))
    }

    override fun startScanWifi(callback: (Result<Unit>) -> Unit) {
        if(wifiScanner == null || wifiNaNScanner == null) {
            return callback(Result.failure(PluginNotInitializedException()))
        }
        wifiScanner!!.scan()
        wifiNaNScanner!!.scan()
        callback(Result.success(Unit))
    }

    override fun stopScanBluetooth(callback: (Result<Unit>) -> Unit) {
        bluetoothScanner?.let {
            it.cancel()
            return callback(Result.success(Unit))
        }
        return callback(Result.failure(PluginNotInitializedException()))
    }

    @RequiresApi(Build.VERSION_CODES.O)
    override fun stopScanWifi(callback: (Result<Unit>) -> Unit) {
        if(wifiScanner == null || wifiNaNScanner == null) {
            return callback(Result.failure(PluginNotInitializedException()))
        }
        wifiScanner!!.cancel()
        wifiNaNScanner!!.cancel()
        return callback(Result.success(Unit))
    }

    override fun setBtScanPriority(priority: ScanPriority, callback: (Result<Unit>) -> Unit) {
        bluetoothScanner?.let {
            it.setScanPriority(priority)
            return callback(Result.success(Unit))
        }
        return callback(Result.failure(PluginNotInitializedException()))
    }

    override fun setBtServiceUuid(serviceUuid: String?, callback: (Result<Unit>) -> Unit) {
        bluetoothScanner?.let {
            it.setServiceUuid(serviceUuid)
            return callback(Result.success(Unit))
        }
        return callback(Result.failure(PluginNotInitializedException()))
    }

    override fun isScanningBluetooth(callback: (Result<Boolean>) -> Unit){
        bluetoothScanner?.let {
            return callback(Result.success(it.isScanning))
        }
        return callback(Result.failure(PluginNotInitializedException()))
    }

    override fun isScanningWifi(callback: (Result<Boolean>) -> Unit){
        if(wifiScanner == null || wifiNaNScanner == null) {
            return callback(Result.failure(PluginNotInitializedException()))
        }
        return callback(Result.success(wifiScanner!!.isScanning || wifiNaNScanner!!.isScanning))
    }

    override fun bluetoothState(callback: (Result<Long>) -> Unit){
        bluetoothScanner?.let {
            return callback(Result.success(it.getAdapterState().toLong()))
        }
        return callback(Result.failure(PluginNotInitializedException()))
    }

    override fun wifiState(callback: (Result<Long>) -> Unit){
        wifiScanner?.let {
            return callback(Result.success(it.getAdapterState().toLong()))
        }
        return callback(Result.failure(PluginNotInitializedException()))
    }

    @RequiresApi(Build.VERSION_CODES.O)
    override fun btExtendedSupported(callback: (Result<Boolean>) -> Unit) {
        bluetoothScanner?.let {
            return callback(Result.success(it.isBtExtendedSupported()))
        }
        return callback(Result.failure(PluginNotInitializedException()))
    }

    @RequiresApi(Build.VERSION_CODES.O)
    override fun btMaxAdvDataLen(callback: (Result<Long>) -> Unit) {
        bluetoothScanner?.let {
            return callback(Result.success(it.maxAdvDataLen().toLong()))
        }
        return callback(Result.failure(PluginNotInitializedException()))
    }

    override fun wifiNaNSupported(callback: (Result<Boolean>) -> Unit) {
        wifiNaNScanner?.let {
            return callback(Result.success(it.isWifiAwareSupported()))
        }
        return callback(Result.failure(PluginNotInitializedException()))
    }
}
