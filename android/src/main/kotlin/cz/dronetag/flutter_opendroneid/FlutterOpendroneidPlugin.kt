package cz.dronetag.flutter_opendroneid

import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import androidx.annotation.NonNull
import android.net.wifi.WifiManager

import io.flutter.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** FlutterOpendroneidPlugin */
class FlutterOpendroneidPlugin: FlutterPlugin, ActivityAware, MethodCallHandler {
  private lateinit var channel: MethodChannel
  private var boundActivity: Activity? = null

  private lateinit var context: Context
  private lateinit var activity: Activity

  private val messagesStreamHandler = StreamHandler()
  private val bluetoothStateStreamHandler = StreamHandler()
  private val scanStateStreamHandler = StreamHandler()

  private var scanner: BluetoothScanner = BluetoothScanner(
          messagesStreamHandler, bluetoothStateStreamHandler, scanStateStreamHandler,
  )
  private lateinit var wifiScanner: WifiScanner

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_odid")
    channel.setMethodCallHandler(this)

    StreamHandler.bindMultipleHandlers(flutterPluginBinding.binaryMessenger, mapOf(
      "flutter_odid_messages" to messagesStreamHandler,
      "flutter_odid_bt_state" to bluetoothStateStreamHandler,
      "flutter_odid_scan_state" to scanStateStreamHandler,
    ))
    context = flutterPluginBinding.applicationContext

    val wifiManager: WifiManager? = context.getSystemService(Context.WIFI_SERVICE) as WifiManager?

    wifiScanner = WifiScanner(
      messagesStreamHandler, bluetoothStateStreamHandler, wifiManager, context
    )
  }


  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    binding.activity.registerReceiver(scanner.adapterStateReceiver, IntentFilter(BluetoothAdapter.ACTION_STATE_CHANGED))
    boundActivity = binding.activity
  }

  override fun onDetachedFromActivityForConfigChanges() {
    boundActivity?.unregisterReceiver(scanner.adapterStateReceiver)
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
  }

  override fun onDetachedFromActivity() {
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    scanner.cancel()
    wifiScanner.cancel()
    channel.setMethodCallHandler(null)
    StreamHandler.clearMultipleHandlers(binding.binaryMessenger, listOf(
      "flutter_odid_basicid",
      "flutter_odid_location",
      "flutter_odid_bt_state"
    ))
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "start_scan" -> startScan(result)
      "stop_scan" -> stopScan(result)
      "is_scanning" -> result.success(scanner.isScanning)
      "bluetooth_state" -> result.success(scanner.getAdapterState())
      "set_autorestart" -> setAutorestart(call.argument<Boolean>("enable"), result)
      else -> result.notImplemented()
    }
  }

  private fun startScan(@NonNull result: Result) {
    scanner.scan()
    wifiScanner.scan()
    Log.d("plugin", "Started scanning")
    result.success(null)
  }

  private fun stopScan(@NonNull result: Result) {
    scanner.cancel()
    wifiScanner.cancel()
    Log.d("plugin", "Scan was stopped")
    result.success(null)
  }

  private fun setAutorestart(enable: Boolean?, @NonNull result: Result) {
    scanner.shouldAutoRestart = enable ?: false
    result.success(null)
  }
}
