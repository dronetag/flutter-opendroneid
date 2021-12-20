package cz.dronetag.flutter_opendroneid

import android.net.wifi.WifiManager
import android.os.Build
import android.os.ParcelUuid
import android.content.*
import cz.dronetag.flutter_opendroneid.models.BasicIdMessage
import cz.dronetag.flutter_opendroneid.models.LocationMessage
import cz.dronetag.flutter_opendroneid.models.OdidMessage
import java.util.*
import io.flutter.Log

class WifiScanner(
    private val messagesHandler: StreamHandler,
    private val bluetoothStateHandler: StreamHandler,
    private val wifiManager: WifiManager?
) {

    private val serviceUuid = UUID.fromString("0000fffa-0000-1000-8000-00805f9b34fb")
    private val serviceParcelUuid = ParcelUuid(serviceUuid)
    private val odidAdCode = byteArrayOf(0x0D.toByte())

    private val messageHandler = OdidMessageHandler()
    private val resultList = ArrayList<ScanResult>()

    private val broadcastReceiver = object : BroadcastReceiver() {
        override fun onReceive(contxt: Context?, intent: Intent?) {
            resultList = wifiManager.scanResults as ArrayList<ScanResult>
            Log.d("TESTING", "onReceive Called")
        }
    }

    fun cancel() {
        wifiManager?.startScan()
        Log.d("wifi scanner", "startScan begin")
    }

    fun scan() {
        wifiManager?.startScan()

        registerReceiver(broadcastReceiver, IntentFilter(WifiManager.SCAN_RESULTS_AVAILABLE_ACTION))
        Log.d("wifi scanner", "startScan begin")
    }
}