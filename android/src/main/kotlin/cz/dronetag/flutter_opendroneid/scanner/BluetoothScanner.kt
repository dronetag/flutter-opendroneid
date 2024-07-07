package cz.dronetag.flutter_opendroneid

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.le.*
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.ParcelUuid
import androidx.annotation.RequiresApi
import io.flutter.Log
import java.util.*
import java.nio.ByteBuffer
import java.nio.ByteOrder

class BluetoothScanner(
    odidPayloadStreamHandler: StreamHandler,
    private val bluetoothStateHandler: StreamHandler,
) : ODIDScanner(odidPayloadStreamHandler) {

    companion object {
        const val BT_OFFSET = 6
        const val MAX_BLE_ADV_SIZE = 31
    }

    private val TAG: String = BluetoothScanner::class.java.getSimpleName()
    private val bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()

    private var scanMode = ScanSettings.SCAN_MODE_LOW_LATENCY

    /// OpenDroneID Bluetooth beacons identify themselves by setting the GAP AD Type to
    /// "Service Data - 16-bit UUID" and the value to 0xFFFA for ASTM International, ASTM Remote ID.
    /// https://www.bluetooth.com/specifications/assigned-numbers/ -> "Generic Access Profile"
    /// https://www.bluetooth.com/specifications/assigned-numbers/ -> "16-bit UUIDs"
    /// Vol 3, Part B, Section 2.5.1 of the Bluetooth 5.1 Core Specification
    /// The AD Application Code is set to 0x0D = Open Drone ID.
    private val serviceUuid = UUID.fromString("0000fffa-0000-1000-8000-00805f9b34fb")
    private val serviceParcelUuid = ParcelUuid(serviceUuid)
    private val odidAdCode = byteArrayOf(0x0D.toByte())

    /// Callback for receiving data: read data from ScanRecord and call receiveData
    private val scanCallback: ScanCallback = object : ScanCallback() {
        override fun onScanResult(callbackType: Int, result: ScanResult) {
            val scanRecord: ScanRecord = result.scanRecord ?: return
            val bytes = scanRecord.bytes ?: return
            var source = Pigeon.MessageSource.BLUETOOTH_LEGACY;

            if (bytes.size < BT_OFFSET + MAX_MESSAGE_SIZE) return

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && bluetoothAdapter.isLeCodedPhySupported()) {
                if (result.getPrimaryPhy() == BluetoothDevice.PHY_LE_CODED)
                    source = Pigeon.MessageSource.BLUETOOTH_LONG_RANGE;
            }
            // if using BLE, max size of data is MAX_BLE_ADV_SIZE
            // if using BT5, data can be longer up to 256 bytes
            val isBLE = maxAdvDataLen() <= MAX_BLE_ADV_SIZE
            receiveData(
                if(isBLE) getDataFromIndex(bytes, BT_OFFSET, MAX_BLE_ADV_SIZE) else offsetData(bytes, BT_OFFSET),
                result.device.address,
                source,
                result.rssi.toLong(),
                result.device.name,
            )
        }

        override fun onBatchScanResults(results: List<ScanResult?>?) {
            Log.e(TAG, "Got batch scan results, unable to handle")
        }

        override fun onScanFailed(errorCode: Int) {
            Log.e(TAG, "Scan failed: $errorCode")
        }
    }

    @RequiresApi(Build.VERSION_CODES.O)
    override fun scan() {
        if (!bluetoothAdapter.isEnabled) return
        val bluetoothLeScanner: BluetoothLeScanner = bluetoothAdapter.bluetoothLeScanner
        val builder: ScanFilter.Builder = ScanFilter.Builder()
        builder.setServiceData(serviceParcelUuid, odidAdCode)
        val scanFilters: MutableList<ScanFilter> = ArrayList()
        scanFilters.add(builder.build())

        logAdapterInfo(bluetoothAdapter)

        var scanSettings = buildScanSettings()

        bluetoothLeScanner.startScan(scanFilters, scanSettings, scanCallback)
        isScanning = true
        bluetoothStateHandler.send(true)
    }

    override fun cancel() {
        isScanning = false
        if (!bluetoothAdapter.isEnabled) return
        bluetoothStateHandler.send(false)
        bluetoothAdapter.bluetoothLeScanner.stopScan(scanCallback)
    }

    @RequiresApi(Build.VERSION_CODES.O)
    override fun onAdapterStateReceived() {
        val rawState = bluetoothAdapter.state
        val commonState = getAdapterState()
        if (rawState == BluetoothAdapter.STATE_OFF || rawState == BluetoothAdapter.STATE_TURNING_OFF) {
            if (bluetoothAdapter.isEnabled) bluetoothAdapter.bluetoothLeScanner.stopScan(scanCallback)
            isScanning = false
        } else if ((rawState == BluetoothAdapter.STATE_ON)
                && !isScanning) {
            cancel()
            scan()
        }
    }

    fun setScanPriority(priority: Pigeon.ScanPriority) {
        if(priority == Pigeon.ScanPriority.HIGH)
        {
            scanMode = ScanSettings.SCAN_MODE_LOW_LATENCY
        }
        else
        {
            scanMode =  ScanSettings.SCAN_MODE_LOW_POWER
        }
        // if scan is running, restart with updated scanMode
        if(isScanning){
            bluetoothAdapter.bluetoothLeScanner.stopScan(scanCallback)
            scan()
        }

    }

    @RequiresApi(Build.VERSION_CODES.O)
    fun isBtExtendedSupported(): Boolean
    {
        return bluetoothAdapter.isLeExtendedAdvertisingSupported;
    }

    @RequiresApi(Build.VERSION_CODES.O)
    fun maxAdvDataLen() : Int
    {
        return bluetoothAdapter.leMaximumAdvertisingDataLength;
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

    private fun logAdapterInfo(bluetoothAdapter: BluetoothAdapter) {
        Log.i(TAG, "bluetooth LE extended supported: " + bluetoothAdapter.isLeExtendedAdvertisingSupported.toString())
        Log.i(TAG, "bluetooth LE coded phy supported: " + bluetoothAdapter.isLeCodedPhySupported.toString())
        Log.i(TAG, "bluetooth multiple advertisement supported: " + bluetoothAdapter.isMultipleAdvertisementSupported.toString())
        Log.i(TAG, "bluetooth max adv data len:" + bluetoothAdapter.leMaximumAdvertisingDataLength.toString())
    }

    private fun buildScanSettings() : ScanSettings {
        var scanSettings = ScanSettings.Builder()
            .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            bluetoothAdapter.isLeCodedPhySupported &&
            bluetoothAdapter.isLeExtendedAdvertisingSupported
        ) {
            scanSettings = ScanSettings.Builder()
                .setScanMode(scanMode)
                .setLegacy(false)
                .setPhy(ScanSettings.PHY_LE_ALL_SUPPORTED)
            .build()
        }
        return scanSettings
    }
}