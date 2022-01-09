package cz.dronetag.flutter_opendroneid

import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import androidx.annotation.NonNull
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

  private val messagesStreamHandler = StreamHandler()
  private val bluetoothStateStreamHandler = StreamHandler()
  private val scanStateStreamHandler = StreamHandler()

  private var scanner: BluetoothScanner = BluetoothScanner(
          messagesStreamHandler, bluetoothStateStreamHandler, scanStateStreamHandler,
  )

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_odid")
    channel.setMethodCallHandler(this)

    StreamHandler.bindMultipleHandlers(flutterPluginBinding.binaryMessenger, mapOf(
      "flutter_odid_messages" to messagesStreamHandler,
      "flutter_odid_bt_state" to bluetoothStateStreamHandler,
      "flutter_odid_scan_state" to scanStateStreamHandler,
    ))

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

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    scanner.cancel()
    channel.setMethodCallHandler(null)
    StreamHandler.clearMultipleHandlers(binding.binaryMessenger, listOf(
      "flutter_odid_basicid",
      "flutter_odid_location",
      "flutter_odid_bt_state"
    ))
  }

  private fun startScan(@NonNull result: Result) {
    scanner.scan()
    Log.d("plugin", "Started scanning")
    result.success(null)
  }

  private fun stopScan(@NonNull result: Result) {
    scanner.cancel()
    Log.d("plugin", "Scan was stopped")
    result.success(null)
  }

  private fun setAutorestart(enable: Boolean?, @NonNull result: Result) {
    scanner.shouldAutoRestart = enable ?: false
    result.success(null)
  }
}
