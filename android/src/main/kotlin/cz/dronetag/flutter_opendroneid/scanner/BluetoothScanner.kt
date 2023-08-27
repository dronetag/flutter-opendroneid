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
        private val odidPayloadStreamHandler: StreamHandler,
        private val bluetoothStateHandler: StreamHandler,
) {
    companion object {
        const val MAX_MESSAGE_SIZE = 25
    }

    var isScanning = false
        get() = field
        set(value) {
            field = value
            bluetoothStateHandler.send(value)
        }
    var scanMode = ScanSettings.SCAN_MODE_LOW_LATENCY
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

    private val payloadHandler: OdidPayloadHandler = OdidPayloadHandler()

    @RequiresApi(Build.VERSION_CODES.O)
    fun scan() {
        if (!bluetoothAdapter.isEnabled) return
        val bluetoothLeScanner: BluetoothLeScanner = bluetoothAdapter.bluetoothLeScanner
        val builder: ScanFilter.Builder = ScanFilter.Builder()
        builder.setServiceData(serviceParcelUuid, odidAdCode)
        val scanFilters: MutableList<ScanFilter> = ArrayList()
        scanFilters.add(builder.build())

        Log.i("bluetooth LE extended supported:", bluetoothAdapter.isLeExtendedAdvertisingSupported.toString())
        Log.i("bluetooth LE coded phy supported:", bluetoothAdapter.isLeCodedPhySupported.toString())
        Log.i("bluetooth multiple advertisement supported:", bluetoothAdapter.isMultipleAdvertisementSupported.toString())
        Log.i("bluetooth max adv data len:", bluetoothAdapter.leMaximumAdvertisingDataLength.toString())

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

        bluetoothLeScanner.startScan(scanFilters, scanSettings, scanCallback)
        isScanning = true
        bluetoothStateHandler.send(true)
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

    fun cancel() {
        isScanning = false
        if (!bluetoothAdapter.isEnabled) return
        bluetoothStateHandler.send(false)
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

    fun handleODIDPayload(result: ScanResult, offset: Long) {
        val scanRecord: ScanRecord = result.scanRecord ?: return
        val bytes = scanRecord.bytes ?: return
        var source = Pigeon.MessageSource.BLUETOOTH_LEGACY;

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && bluetoothAdapter.isLeCodedPhySupported()) {
            if (result.getPrimaryPhy() == BluetoothDevice.PHY_LE_CODED)
                source = Pigeon.MessageSource.BLUETOOTH_LONG_RANGE;
        }
        if (bytes.size < offset + MAX_MESSAGE_SIZE) return
    
        val payload = payloadHandler.getPayload(
            bytes.copyOfRange(offset.toInt(), MAX_MESSAGE_SIZE + offset.toInt()),
            source,
            result.device.address,
            result.rssi.toLong(),
            System.currentTimeMillis()
        )

        odidPayloadStreamHandler.send(payload?.toList() as Any)
    }

    val adapterStateReceiver: BroadcastReceiver = object : BroadcastReceiver() {
        @RequiresApi(Build.VERSION_CODES.O)
        override fun onReceive(context: Context?, intent: Intent?) {
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
    }

    private val scanCallback: ScanCallback = object : ScanCallback() {
        override fun onScanResult(callbackType: Int, result: ScanResult) {
            handleODIDPayload(result, 6)
        }

        override fun onBatchScanResults(results: List<ScanResult?>?) {
            Log.e("scanner", "Got batch scan results, unable to handle")
        }

        override fun onScanFailed(errorCode: Int) {
            Log.e("scanner", "Scan failed: $errorCode")
        }
    }
}