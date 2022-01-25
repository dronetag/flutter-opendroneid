package cz.dronetag.flutter_opendroneid

import android.bluetooth.BluetoothAdapter
import android.bluetooth.le.*
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.ParcelUuid
import cz.dronetag.flutter_opendroneid.models.BasicIdMessage
import cz.dronetag.flutter_opendroneid.models.LocationMessage
import cz.dronetag.flutter_opendroneid.models.OdidMessage
import io.flutter.Log
import java.util.*

class BluetoothScanner(
        private val messagesHandler: StreamHandler,
        private val bluetoothStateHandler: StreamHandler,
        private val scanStateHandler: StreamHandler,
) {
    var isScanning = false
        get() = field
        set(value) {
            field = value
            scanStateHandler.send(value)
        }
    var shouldAutoRestart = false
    val bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
    /* OpenDroneID Bluetooth beacons identify themselves by setting the GAP AD Type to
    * "Service Data - 16-bit UUID" and the value to 0xFFFA for ASTM International, ASTM Remote ID.
    * https://www.bluetooth.com/specifications/assigned-numbers/ -> "Generic Access Profile"
    * https://www.bluetooth.com/specifications/assigned-numbers/ -> "16-bit UUIDs"
    * Vol 3, Part B, Section 2.5.1 of the Bluetooth 5.1 Core Specification
    * The AD Application Code is set to 0x0D = Open Drone ID.
    */
    private val serviceUuid = UUID.fromString("0000fffa-0000-1000-8000-00805f9b34fb")
    private val serviceParcelUuid = ParcelUuid(serviceUuid)
    private val odidAdCode = byteArrayOf(0x0D.toByte())

    private val messageHandler = OdidMessageHandler()

    fun scan() {
        if (!bluetoothAdapter.isEnabled) return
        val bluetoothLeScanner: BluetoothLeScanner = bluetoothAdapter.bluetoothLeScanner
        val builder: ScanFilter.Builder = ScanFilter.Builder()
        builder.setServiceData(serviceParcelUuid, odidAdCode)
        val scanFilters: MutableList<ScanFilter> = ArrayList()
        scanFilters.add(builder.build())

        var scanSettings = ScanSettings.Builder()
                .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
                .build()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
                bluetoothAdapter.isLeCodedPhySupported &&
                bluetoothAdapter.isLeExtendedAdvertisingSupported
        ) {
            scanSettings = ScanSettings.Builder()
                    .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
                    .setLegacy(false)
                    .setPhy(ScanSettings.PHY_LE_ALL_SUPPORTED)
                    .build()
        }

        bluetoothLeScanner.startScan(scanFilters, scanSettings, scanCallback)
        Log.d("scanner", "Started OpenDroneID messages scan")
        isScanning = true
    }

    fun cancel() {
        isScanning = false
        if (!bluetoothAdapter.isEnabled) return
        bluetoothAdapter.bluetoothLeScanner.stopScan(scanCallback)
    }

    fun getAdapterState(): Int {
        return when (bluetoothAdapter.state) {
            BluetoothAdapter.STATE_OFF -> 4
            BluetoothAdapter.STATE_ON -> 5
            BluetoothAdapter.STATE_TURNING_OFF -> 1
            BluetoothAdapter.STATE_TURNING_ON -> 1
            else -> 0
        }
    }

    val adapterStateReceiver: BroadcastReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val rawState = bluetoothAdapter.state
            val commonState = getAdapterState()
            bluetoothStateHandler.send(commonState)

            if (rawState == BluetoothAdapter.STATE_OFF || rawState == BluetoothAdapter.STATE_TURNING_OFF) {
                if (bluetoothAdapter.isEnabled) bluetoothAdapter.bluetoothLeScanner.stopScan(scanCallback)
                isScanning = false
            } else if ((rawState == BluetoothAdapter.STATE_ON)
                    && !isScanning && shouldAutoRestart) {
                cancel()
                scan()
            }
        }
    }

    private val scanCallback: ScanCallback = object : ScanCallback() {
        override fun onScanResult(callbackType: Int, result: ScanResult) {
            val scanRecord: ScanRecord = result.scanRecord ?: return
            val bytes = scanRecord.bytes ?: return
            val receivedMessage: OdidMessage? = messageHandler.receiveDataBluetooth(bytes)
            receivedMessage ?: return

            val json = receivedMessage.toJson()

            json["type"] = receivedMessage.type.ordinal
            json["macAddress"] = result.device.address
            json["source"] = OdidMessage.Source.BLUETOOTH_LEGACY.ordinal
            json["rssi"] = result.rssi

            messagesHandler.send(json)
        }

        override fun onBatchScanResults(results: List<ScanResult?>?) {
            Log.e("scanner", "Got batch scan results, unable to handle")
        }

        override fun onScanFailed(errorCode: Int) {
            Log.e("scanner", "Scan failed: $errorCode")
        }
    }
}