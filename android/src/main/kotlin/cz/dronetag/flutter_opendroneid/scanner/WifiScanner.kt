package cz.dronetag.flutter_opendroneid

import android.net.wifi.WifiManager
import android.net.wifi.ScanResult
import android.os.Build
import android.os.ParcelUuid
import android.content.*
import cz.dronetag.flutter_opendroneid.models.BasicIdMessage
import cz.dronetag.flutter_opendroneid.models.LocationMessage
import cz.dronetag.flutter_opendroneid.models.OdidMessage
import java.util.*
import io.flutter.Log
import kotlin.Unit




class WifiScanner (
    private val messagesHandler: StreamHandler,
    private val bluetoothStateHandler: StreamHandler,
    private val wifiManager: WifiManager?,
    private val context: Context
) {

    private val serviceUuid = UUID.fromString("0000fffa-0000-1000-8000-00805f9b34fb")
    private val serviceParcelUuid = ParcelUuid(serviceUuid)
    private val odidAdCode = byteArrayOf(0x0D.toByte())

    private val messageHandler = OdidMessageHandler()
    val resultList = ArrayList<ScanResult>()

    private val broadcastReceiver = object : BroadcastReceiver() {
        override fun onReceive(contxt: Context?, intent: Intent?) {
            val resultList = wifiManager?.getScanResults() as ArrayList<ScanResult>
            Log.d("wifi scanner", "wifi scan number of results: ${resultList.size}")
            for (net in resultList) {
                // example json from trasmitter raspberry program:
                //D/wifi scanner: SSID: DroneIDTest, BSSID: e4:5f:01:7a:f2:90, capabilities: [WPA2-PSK-CCMP][ESS][V], level: -49, frequency: 2437, timestamp: 529905847455, distance: ?(cm), distanceSd: ?(cm), passpoint: no, ChannelBandwidth: 0, centerFreq0: 0, centerFreq1: 0, 80211mcResponder: is not supported, Carrier AP: no, Carrier AP EAP Type: -1, Carrier name: null, Radio Chain Infos: null

                Log.d("wifi scanner", "$net")
                val json: MutableMap<String, Any>  = mutableMapOf<String, Any>()
                json["source"] = OdidMessage.Source.WIFI_BEACON.ordinal
                json["type"] = OdidMessage.Type.OPERATOR_ID.ordinal
                json["macAddress"] = net.BSSID
                json["rssi"] = net.level
                json["operatorID"] = net.SSID
                messagesHandler.send(json)
            }
        }
    }

    fun cancel() {
        Log.d("wifi scanner", "startScan cancel")
    }

    fun scan() {
        val start_res = wifiManager?.startScan()
        context.registerReceiver(broadcastReceiver, IntentFilter(WifiManager.SCAN_RESULTS_AVAILABLE_ACTION))
        Log.d("wifi scanner", "startScan began: $start_res")
    }
}