package cz.dronetag.flutter_opendroneid

import android.net.wifi.WifiManager
import android.net.wifi.ScanResult
import android.os.Build
import android.content.*
import android.net.wifi.ScanResult.InformationElement
import java.nio.ByteBuffer;
import io.flutter.Log
import kotlin.experimental.and
import android.os.CountDownTimer
import java.nio.ByteOrder
import java.util.*

class WifiScanner (
    private val odidPayloadStreamHandler: StreamHandler,
    private val wifiStateHandler: StreamHandler,
    private val wifiManager: WifiManager?,
    private val context: Context
) {
    companion object {
        const val MAX_MESSAGE_SIZE = 25
    }

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
    private val payloadHandler: OdidPayloadHandler = OdidPayloadHandler()
    var isScanning = false

    private var countDownTimer: CountDownTimer? = null

    private val broadcastReceiver = object : BroadcastReceiver() {
        override fun onReceive(contxt: Context?, intent: Intent?) {
            if (wifiManager == null) {
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
                val valueId = element.javaClass.getField("id")[element] ?: continue
                val id = valueId as Int
                if (id == 221) {
                    val valueBytes = element.javaClass.getField("bytes")[element] ?: continue
                    val buf: ByteBuffer =
                        ByteBuffer.wrap(valueBytes as ByteArray).asReadOnlyBuffer()
                    receiveData(scanResult, buf)
                }
            }
        } else {
            for (element in scanResult.informationElements) {
                if (element != null && element.id == 221) {
                    val buf: ByteBuffer = element.bytes
                    receiveData(scanResult, buf)
                }
            }
        }
    }

    fun receiveData(scanResult: ScanResult, buf: ByteBuffer) {
        if (buf.remaining() < 30){
            return
        }
        val offset = 1
        val dri_CID = ByteArray(CIDLen)
        var arr = ByteArray(buf.remaining())
        buf.get(dri_CID, 0, CIDLen)

        val vendorType = ByteArray(vendorTypeLen)
        buf.get(vendorType, 0, vendorTypeLen)
        
        if ((dri_CID[0] and 0xFF.toByte()) == DRICID.get(0).toByte()
            && ((dri_CID[1] and 0xFF.toByte()) == DRICID.get(1).toByte())
            && ((dri_CID[2] and 0xFF.toByte()) == DRICID.get(2).toByte())
            && vendorType[0] == vendorTypeValue.toByte()
        ) 
        {
            val payload = payloadHandler.getPayload(
                arr.copyOfRange(offset, MAX_MESSAGE_SIZE + offset),
                Pigeon.MessageSource.WIFI_BEACON,
                scanResult.BSSID,
                scanResult.level.toLong(),
                System.currentTimeMillis()
            )

            odidPayloadStreamHandler.send(payload?.toList() as Any)
        }
    }

    

    fun cancel() {
        if (!wifiScanEnabled) {
            return;
        }
        isScanning = false;
        wifiStateHandler.send(false)
        if (countDownTimer != null) {
            countDownTimer!!.cancel();
        }
    }

    fun scan() {
        if (!wifiScanEnabled) {
            return
        }
        isScanning = true
        wifiStateHandler.send(true)
        context.registerReceiver(broadcastReceiver, IntentFilter(WifiManager.SCAN_RESULTS_AVAILABLE_ACTION))
        val ret = wifiManager!!.startScan()
        if (ret) {
            scanSuccess++
        } else {
            scanFailed++
        }
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

    val adapterStateReceiver: BroadcastReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (wifiManager == null) {
                return
            }
            // wifi can be available even if it is turned of
            if(wifiManager.isScanAlwaysAvailable())
                return
            val rawState = wifiManager.getWifiState()
            if (rawState == WifiManager.WIFI_STATE_DISABLED || rawState == WifiManager.WIFI_STATE_DISABLING) {
                cancel()
            }
        }
    }

    fun getAdapterState(): Int {
        if (wifiManager == null) {
            return 1
        }
         // wifi can be available even if it is turned of
        if(wifiManager.isScanAlwaysAvailable())
            return 3
        return when (wifiManager.getWifiState()) {
            WifiManager.WIFI_STATE_ENABLED -> 3
            else -> 1
        }
    }
}