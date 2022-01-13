package cz.dronetag.flutter_opendroneid

import android.net.wifi.WifiManager
import android.net.wifi.ScanResult
import android.os.Build
import android.os.ParcelUuid
import android.content.*
import android.net.wifi.ScanResult.InformationElement
import cz.dronetag.flutter_opendroneid.models.BasicIdMessage
import cz.dronetag.flutter_opendroneid.models.LocationMessage
import cz.dronetag.flutter_opendroneid.models.OdidMessage
import java.util.*
import java.nio.ByteBuffer;
import io.flutter.Log
import kotlin.Unit
import android.widget.Toast
import android.os.SystemClock
import java.lang.StringBuilder
import kotlin.experimental.and


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

    private val CIDLen = 3
    private val DriStartByteOffset = 4
    private val ScanTimerInterval = 2
    private val DRI_CID = intArrayOf(0xFA, 0x0B, 0xBC)
    private val VendorTypeLen = 1
    private val VendorTypeValue = 0x0D
    private val TAG: String = WifiScanner::class.java.getSimpleName()


    private val broadcastReceiver = object : BroadcastReceiver() {
        override fun onReceive(contxt: Context?, intent: Intent?) {
            if (wifiManager == null) {
                Toast.makeText(context, "WiFi beacon scanner attach failed.", Toast.LENGTH_LONG)
                    .show()
                return
            }
            val freshScanResult = intent!!.getBooleanExtra(WifiManager.EXTRA_RESULTS_UPDATED, false)
            val action = intent.action
            if (freshScanResult && WifiManager.SCAN_RESULTS_AVAILABLE_ACTION == action) {
                val wifiList = wifiManager.scanResults
                for (scanResult in wifiList) {
                    try {
                        handleResult(scanResult)
                    } catch (e: NoSuchFieldException) {
                        e.printStackTrace()
                    } catch (e: IllegalAccessException) {
                        e.printStackTrace()
                    }
                }
                scan()
            }

           /* val resultList = wifiManager?.getScanResults() as ArrayList<ScanResult>
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
            }*/
        }
    }

    @Throws(NoSuchFieldException::class, IllegalAccessException::class)
    fun handleResult(scanResult: ScanResult) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) {
            // On earlier Android APIs, the information element field is hidden.
            // Use reflection to access it.
            val value =
                ScanResult::class.java.getField("informationElements")[scanResult]
            val elements = value as Array<InformationElement>
                ?: return
            for (element in elements) {
                if (element == null) continue
                val valueId = element.javaClass.getField("id")[element] ?: continue
                val id = valueId as Int
                if (id == 221) {
                    val valueBytes = element.javaClass.getField("bytes")[element] ?: continue
                    Log.d("wifi scanner", valueBytes.toString())
                    val buf: ByteBuffer =
                        ByteBuffer.wrap(valueBytes as ByteArray).asReadOnlyBuffer()
                    processRemoteIdVendorIE(scanResult, buf)
                }
                else
                    Log.d("wifi scanner", "id is not 221")
            }
        } else {
            for (element in scanResult.informationElements) {
                if (element != null && element.id == 221) {
                    val buf: ByteBuffer = element.bytes
                    processRemoteIdVendorIE(scanResult, buf)
                }
            }
        }
    }

    fun processRemoteIdVendorIE(scanResult: ScanResult, buf: ByteBuffer) {
        Log.d("wifi scanner:processRemoteIdVendorIE", scanResult.SSID)
        if (buf.remaining() < 30){
            Log.d("wifi scanner", "buffer too short")
            return
        }
        val dri_CID = ByteArray(CIDLen)
        val arr = ByteArray(buf.remaining())
        buf[dri_CID, 0, CIDLen]
        val vendorType = ByteArray(VendorTypeLen)
        buf[vendorType]
        if ((dri_CID[0] and 0xFF.toByte()) == DRI_CID.get(0).toByte()
            && ((dri_CID[1] and 0xFF.toByte()) == DRI_CID.get(1).toByte())
            && ((dri_CID[2] and 0xFF.toByte()) == DRI_CID.get(2).toByte())
            && vendorType[0] == VendorTypeValue.toByte()
        ) {
            buf.position(DriStartByteOffset)
            buf[arr, 0, buf.remaining()]
            val timeNano = SystemClock.elapsedRealtimeNanos()
            val transportType = "Beacon"
            val receivedMessage: OdidMessage? = messageHandler.receiveDataWifiBeacon(arr);
            if(receivedMessage==null) {
                Log.d("wifi scanner", "null message")
                return
            }
            else
                Log.d("wifi scanner", "message received..")

            Log.d("wifi scanner", "parsing scan result...")

            val json = receivedMessage.toJson()
            json["type"] = receivedMessage.type.ordinal
            json["source"] = OdidMessage.Source.WIFI_BEACON.ordinal
            json["rssi"] = scanResult.level
            Log.d("scanner", json.toString())

            messagesHandler.send(json)
        }
        else{
            Log.d("wifi scanner", "condition false")

        }
    }

    fun cancel() {
        Log.d("wifi scanner", "startScan cancel")
    }

    fun scan() {
        val startRes = wifiManager?.startScan()
        context.registerReceiver(broadcastReceiver, IntentFilter(WifiManager.SCAN_RESULTS_AVAILABLE_ACTION))
        Log.d("wifi scanner", "startScan began: $startRes")
    }
}