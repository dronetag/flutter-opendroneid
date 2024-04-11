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

/// Wi-Fi Beacons Scanner
/// There are 2 ways to control WiFi scan:
/// Continuous scan: Calls startScan() from scan completion callback
/// Periodic scan: countdown timer triggers startScan after expiry of the timer.
/// If phone is debug mode and scan throttling is off, scan is triggered from onReceive() callback.
/// But if scan throttling is turned on on the phone (default setting on the phone), then scan throttling kick in.
/// In case of throttling, startScan() fails. We need timer thread to periodically kick off scanning.
class WifiScanner (
    odidPayloadStreamHandler: StreamHandler,
    private val wifiStateHandler: StreamHandler,
    private val wifiManager: WifiManager?,
    private val context: Context
) : ODIDScanner(odidPayloadStreamHandler) {

    companion object {
        const val WIFI_BEACON_OFFSET = 5
    }

    private val TAG: String = WifiScanner::class.java.getSimpleName()
    private val CIDLen = 3
    private val DRICID = intArrayOf(0xFA, 0x0B, 0xBC)
    private val vendorTypeLen = 1
    private val vendorTypeValue = 0x0D
    private var scanSuccess = 0
    private var scanFailed = 0
    private val scanTimerInterval = 2

    private var countDownTimer: CountDownTimer? = null

    // callback for receiving Wi-Fi scan results
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
                if(isScanning)
                    scan()
            }
        }
    }

    override fun scan() {
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

    override fun cancel() {
        isScanning = false;
        context.unregisterReceiver(broadcastReceiver)
        wifiStateHandler.send(false)
        if (countDownTimer != null) {
            countDownTimer!!.cancel();
        }
    }

    override fun onAdapterStateReceived() {
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

    @Throws(NoSuchFieldException::class, IllegalAccessException::class)
    private fun handleResult(scanResult: ScanResult) {
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
                    val bytes = element.javaClass.getField("bytes")[element] ?: continue
                    receiveBeaconData(scanResult, bytes as ByteArray)
                }
            }
        } else {
            for (element in scanResult.informationElements) {
                if (element != null && element.id == 221) {
                    val bytes = ByteArray(element.bytes.remaining())
                    element.bytes.get(bytes)
                    receiveBeaconData(scanResult, bytes)
                }
            }
        }
    }

    private fun receiveBeaconData(scanResult: ScanResult, bytes: ByteArray) { 
        if(checkDRICID(bytes)){
            receiveData(
                offsetData(bytes, WIFI_BEACON_OFFSET),
                scanResult.BSSID, 
                Pigeon.MessageSource.WIFI_BEACON,
                scanResult.level.toLong(),
            )
        }
    }

    private fun checkDRICID(bytes: ByteArray) : Boolean{
        val buf = ByteBuffer.wrap(bytes as ByteArray).asReadOnlyBuffer()
        if (buf.remaining() < MAX_MESSAGE_SIZE + WIFI_BEACON_OFFSET){
            return false
        }
        val dri_CID = ByteArray(CIDLen)
        buf.get(dri_CID, 0, CIDLen)

        val vendorType = ByteArray(vendorTypeLen)
        buf.get(vendorType, 0, vendorTypeLen)
        
        return (dri_CID[0] and 0xFF.toByte()) == DRICID.get(0).toByte()
                && ((dri_CID[1] and 0xFF.toByte()) == DRICID.get(1).toByte())
                && ((dri_CID[2] and 0xFF.toByte()) == DRICID.get(2).toByte())
                && vendorType[0] == vendorTypeValue.toByte()
    }

    private fun startCountDownTimer() {
        countDownTimer = object : CountDownTimer(
            Long.MAX_VALUE,
            (scanTimerInterval * 1000).toLong()
        ) {
            // This is called after every ScanTimerInterval sec.
            override fun onTick(millisUntilFinished: Long) {
                if(isScanning)
                    scan()
            }

            override fun onFinish() {}
        }.start()
    }
}