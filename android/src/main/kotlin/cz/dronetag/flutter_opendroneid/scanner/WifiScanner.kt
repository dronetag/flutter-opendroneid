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
import android.os.CountDownTimer





class WifiScanner (
    private val messagesHandler: StreamHandler,
    private val bluetoothStateHandler: StreamHandler,
    private val wifiManager: WifiManager?,
    private val context: Context
) {
    private val messageHandler = OdidMessageHandler()
    private val CIDLen = 3
    private val driStartByteOffset = 4
    private val DRICID = intArrayOf(0xFA, 0x0B, 0xBC)
    private val vendorTypeLen = 1
    private val vendorTypeValue = 0x0D
    private val TAG: String = WifiScanner::class.java.getSimpleName()
    private var scanSuccess = 0
    private var scanFailed = 0
    private val wifiScanEnabled = true
    private val scanTimerInterval = 2

    private var countDownTimer: CountDownTimer? = null

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
                    val buf: ByteBuffer =
                        ByteBuffer.wrap(valueBytes as ByteArray).asReadOnlyBuffer()
                    processRemoteIdVendorIE(scanResult, buf)
                }
            }
        } else {
            for (element in scanResult.informationElements) {
                if (element != null && element.id == 221) {
                    val buf: ByteBuffer = element.bytes
                    Log.d("wifi scanner", "bytes: "+ element.bytes.toString())
                    processRemoteIdVendorIE(scanResult, buf)
                }
            }
        }
    }

    fun processRemoteIdVendorIE(scanResult: ScanResult, buf: ByteBuffer) {

        if (buf.remaining() < 30){
            return
        }
        val dri_CID = ByteArray(CIDLen)
        val arr = ByteArray(buf.remaining())
        buf[dri_CID, 0, CIDLen]
        val vendorType = ByteArray(vendorTypeLen)
        buf[vendorType]
        if ((dri_CID[0] and 0xFF.toByte()) == DRICID.get(0).toByte()
            && ((dri_CID[1] and 0xFF.toByte()) == DRICID.get(1).toByte())
            && ((dri_CID[2] and 0xFF.toByte()) == DRICID.get(2).toByte())
            && vendorType[0] == vendorTypeValue.toByte()
        ) {
            buf.position(driStartByteOffset)
            buf[arr, 0, buf.remaining()]
            val timeNano = SystemClock.elapsedRealtimeNanos()
            val transportType = "Beacon"
            val receivedMessage: OdidMessage = messageHandler.receiveDataWifiBeacon(arr) ?: return;
            Log.d("wifi scanner", "message received..")

            val json = receivedMessage.toJson()
            json["type"] = receivedMessage.type.ordinal
            json["source"] = OdidMessage.Source.WIFI_BEACON.ordinal
            json["rssi"] = scanResult.level
            Log.d("scanner", json.toString())

            messagesHandler.send(json)
        }
    }

    fun cancel() {
        if (!wifiScanEnabled) {
            return;
        }
        if (countDownTimer != null) {
            countDownTimer!!.cancel();
        }
        Log.d(TAG, "Stopping WiFi Beacon scanning");
    }

    fun scan() {
        if (!wifiScanEnabled) {
            return
        }
        context.registerReceiver(broadcastReceiver, IntentFilter(WifiManager.SCAN_RESULTS_AVAILABLE_ACTION))
        val ret = wifiManager!!.startScan()
        if (ret) {
            scanSuccess++
        } else {
            scanFailed++
        }
        Log.d(TAG, "start_scan:$ret")
    }
    // There are 2 ways to control WiFi scan:
    // Continuous scan: Calls startSCan() from scan completion callback
    // Periodic scan: countdown timer triggers startScan after expiry of the timer.
    // If phone is debug mode and scan throttling is off, scan is triggered from onReceive() callback.
    // But if scan throttling is turned on on the phone (default setting on the phone), then scan throttling kick in.
    // In case of throttling, startScan() fails. We need timer thread to periodically kick off scanning.
    fun startCountDownTimer() {
        countDownTimer = object : CountDownTimer(
            Long.MAX_VALUE,
            (scanTimerInterval * 1000).toLong()
        ) {
            // This is called after every ScanTimerInterval sec.
            override fun onTick(millisUntilFinished: Long) {
                scan()
            }

            override fun onFinish() {}
        }.start()
    }
}