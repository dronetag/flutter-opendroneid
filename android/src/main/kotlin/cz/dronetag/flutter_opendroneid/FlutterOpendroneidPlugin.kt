package cz.dronetag.flutter_opendroneid

import androidx.annotation.NonNull
import io.flutter.Log

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** FlutterOpendroneidPlugin */
class FlutterOpendroneidPlugin: FlutterPlugin, MethodCallHandler {
  var isScanning = false

  private lateinit var channel: MethodChannel

  private val messagesStreamHandler = StreamHandler()
  private val bluetoothStateStreamHandler = StreamHandler()

  private lateinit var scanner: BluetoothScanner

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_odid")
    channel.setMethodCallHandler(this)

    StreamHandler.bindMultipleHandlers(flutterPluginBinding.binaryMessenger, mapOf(
      "flutter_odid_messages" to messagesStreamHandler,
      "flutter_odid_bt_state" to bluetoothStateStreamHandler
    ))

    scanner = BluetoothScanner(
        messagesStreamHandler, bluetoothStateStreamHandler
    )
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "start_scan" -> startScan()
      "stop_scan" -> stopScan()
      "is_scanning" -> result.success(isScanning)
      "bluetooth_state" -> result.success(scanner.getAdapterState())
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

  private fun startScan() {
    scanner.scan()
    isScanning = true
    Log.d("plugin", "Started scanning")
  }

  private fun stopScan() {
    scanner.cancel()
    isScanning = false
    Log.d("plugin", "Scan was stopped")
  }
}
