package cz.dronetag.flutter_opendroneid

import android.annotation.TargetApi
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.wifi.aware.AttachCallback
import android.net.wifi.aware.DiscoverySessionCallback
import android.net.wifi.aware.IdentityChangedListener
import android.net.wifi.aware.PeerHandle
import android.net.wifi.aware.SubscribeConfig
import android.net.wifi.aware.SubscribeDiscoverySession
import android.net.wifi.aware.WifiAwareManager
import android.net.wifi.aware.WifiAwareSession
import android.os.Build
import android.os.SystemClock
import io.flutter.Log
import androidx.annotation.NonNull
import androidx.annotation.RequiresApi
import android.content.pm.PackageManager;
import java.lang.StringBuilder
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.Arrays;
import java.util.List;


class WifiNaNScanner (
    odidPayloadStreamHandler: StreamHandler,
    private val wifiStateHandler: StreamHandler,
    private val wifiAwareManager: WifiAwareManager?,
    private val context: Context
)  : ODIDScanner(odidPayloadStreamHandler) {
    private val TAG: String = WifiNaNScanner::class.java.getSimpleName()
    
    private var wifiAwareSession: WifiAwareSession? = null
    private val wifiScanEnabled = true
    private var wifiAwareSupported = true

    init{
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O ||
            !context.getPackageManager().hasSystemFeature(PackageManager.FEATURE_WIFI_AWARE)) {
            Log.i(TAG, "WiFi Aware is not supported.");
            wifiAwareSupported = false
        }
        else
        {
            wifiAwareSupported = true
        }
    }

    override fun scan() {
        if (!wifiScanEnabled) {
            return
        }
        isScanning = true
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O ||
            !context.getPackageManager().hasSystemFeature(PackageManager.FEATURE_WIFI_AWARE)) {
            Log.i(TAG, "WiFi Aware is not supported.");
            wifiAwareSupported = false
            return;
        }
        wifiAwareSupported = true
        context.registerReceiver(adapterStateReceiver, IntentFilter(WifiAwareManager.ACTION_WIFI_AWARE_STATE_CHANGED))
        startScan();
    }

    @RequiresApi(Build.VERSION_CODES.O)
    override fun cancel() {
        if (!wifiAwareSupported) return
        isScanning = false;
        stopScan()
    }

    @RequiresApi(Build.VERSION_CODES.O)
    override fun onAdapterStateReceived() {
        if (wifiAwareManager!!.isAvailable) {
            Log.i(TAG, "WiFi Aware became available.")
            startScan()
        }
    }

    private val attachCallback: AttachCallback = @RequiresApi(Build.VERSION_CODES.O)
    object : AttachCallback() {
        override fun onAttached(session: WifiAwareSession) {
            if (!wifiAwareSupported) return
            wifiAwareSession = session
            val config = SubscribeConfig.Builder()
                .setServiceName("org.opendroneid.remoteid")
                .build()
            wifiAwareSession!!.subscribe(config, object : DiscoverySessionCallback() {
                override fun onServiceDiscovered(
                    peerHandle: PeerHandle?,
                    serviceSpecificInfo: ByteArray?,
                    matchFilter: MutableList<ByteArray>?
                ) {
                    if (serviceSpecificInfo != null)
                        receiveData(
                            offsetData(serviceSpecificInfo, WIFI_NAN_OFFSET),
                            peerHandle.hashCode().toString(),
                            Pigeon.MessageSource.WIFI_NAN,
                        )
                }
            }, null)
        }

    }

    @TargetApi(Build.VERSION_CODES.O)
    private val identityChangedListener: IdentityChangedListener =
        object : IdentityChangedListener() {
            override fun onIdentityChanged(mac: ByteArray) {
                val macAddress = arrayOfNulls<Byte>(mac.size)
                var i = 0
                for (b in mac) macAddress[i++] = b
            }
        }

    fun isWifiAwareSupported(): Boolean
    {
        return wifiAwareSupported;
    }

    @TargetApi(Build.VERSION_CODES.O)
    private fun startScan() {
        if (!wifiAwareSupported) return
        if (wifiAwareManager!!.isAvailable)
        {
            wifiAwareManager.attach(
                attachCallback,
                identityChangedListener,
                null
            )
            wifiStateHandler.send(true)
        }
    }

    @TargetApi(Build.VERSION_CODES.O)
    private fun stopScan() {
        if (!wifiAwareSupported) return
        if (wifiAwareManager != null && wifiAwareManager!!.isAvailable && wifiAwareSession != null)
        {
            wifiAwareSession!!.close()
            wifiStateHandler.send(false)
        }
    }
}