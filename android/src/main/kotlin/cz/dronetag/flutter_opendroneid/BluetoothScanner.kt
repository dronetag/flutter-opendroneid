package cz.dronetag.flutter_opendroneid

import android.bluetooth.BluetoothAdapter
import android.bluetooth.le.*
import android.os.Build
import android.os.ParcelUuid
import cz.dronetag.flutter_opendroneid.models.BasicIdMessage
import cz.dronetag.flutter_opendroneid.models.LocationMessage
import cz.dronetag.flutter_opendroneid.models.OdidMessage
import io.flutter.Log
import java.util.*

class BluetoothScanner(
    private val messagesHandler: StreamHandler,
    private val bluetoothStateHandler: StreamHandler
) {
    val bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
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
        Log.d("scanner", "startScan begin")
    }

    fun cancel() {
        if (!bluetoothAdapter.isEnabled) return
        bluetoothAdapter.bluetoothLeScanner.stopScan(scanCallback)
    }

    fun getAdapterState(): Int {
        val state = bluetoothAdapter.state

        return when (state) {
            BluetoothAdapter.STATE_OFF -> 4
            BluetoothAdapter.STATE_ON -> 5
            BluetoothAdapter.STATE_TURNING_OFF -> 1
            BluetoothAdapter.STATE_TURNING_ON -> 1
            else -> 0
        }
    }

    private val scanCallback: ScanCallback = object : ScanCallback() {
        override fun onScanResult(callbackType: Int, result: ScanResult) {
            Log.d("scanner", "scanResult received")
            val scanRecord: ScanRecord = result.scanRecord ?: return
            val bytes = scanRecord.bytes ?: return
            val receivedMessage: OdidMessage? = messageHandler.receiveDataBluetooth(bytes)
            receivedMessage ?: return

            Log.d("scanner", "parsing scan result...")
            val json = receivedMessage.toJson()

            json["type"] = receivedMessage.type.ordinal
            json["macAddress"] = result.device.address
            json["source"] = OdidMessage.Source.BLUETOOTH_LEGACY.ordinal
            json["rssi"] = result.rssi

            Log.d("scanner", json.toString())

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