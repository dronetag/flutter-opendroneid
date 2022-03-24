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
import java.util.Arrays;
import java.util.List;


class WifiNaNScanner (
    private val basicMessagesHandler: StreamHandler,
    private val locationMessagesHandler: StreamHandler,
    private val operatorIdMessagesHandler: StreamHandler,
    private val bluetoothStateHandler: StreamHandler,
    private val selfIdMessagesHandler: StreamHandler,
    private val authenticationMessagesHandler: StreamHandler,
    private val systemDataMessagesHandler: StreamHandler,
    private val wifiAwareManager: WifiAwareManager?,
    private val context: Context
) {
    private val messageHandler = OdidMessageHandler()
    private var wifiAwareSession: WifiAwareSession? = null
    private val wifiScanEnabled = true
    private var wifiAwareSupported = false
    var isScanning = false
    private val TAG: String = WifiNaNScanner::class.java.getSimpleName()

    private val myReceiver: BroadcastReceiver = object : BroadcastReceiver() {
        @RequiresApi(Build.VERSION_CODES.O)
        override fun onReceive(context: Context?, intent: Intent?) {
            if (wifiAwareManager!!.isAvailable) {
                Log.i(TAG, "WiFi Aware became available.")
                startScan()
            }
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
                override fun onSubscribeStarted(session: SubscribeDiscoverySession) {
                    Log.i(TAG, "onSubscribeStarted")
                }

                override fun onServiceDiscovered(
                    peerHandle: PeerHandle?,
                    serviceSpecificInfo: ByteArray?,
                    matchFilter: MutableList<ByteArray>?
                ) {
                    Log.i(
                        TAG,
                        "onServiceDiscovered: " + serviceSpecificInfo!!.size + ": " + Arrays.toString(
                            serviceSpecificInfo
                        )
                    )
                    val transportType = "NAN"
                    val timeNano: Long = SystemClock.elapsedRealtimeNanos()

                }
            }, null)
        }

        override fun onAttachFailed() {
            Log.d(TAG, "attach failed")
        }
    }

    @TargetApi(Build.VERSION_CODES.O)
    private val identityChangedListener: IdentityChangedListener =
        object : IdentityChangedListener() {
            override fun onIdentityChanged(mac: ByteArray) {
                val macAddress = arrayOfNulls<Byte>(mac.size)
                var i = 0
                for (b in mac) macAddress[i++] = b
                Log.i(
                    TAG,
                    "identityChangedListener: onIdentityChanged. MAC: " + Arrays.toString(macAddress)
                )
            }
        }

    @TargetApi(Build.VERSION_CODES.O)
    fun startScan() {
        if (!wifiAwareSupported) return
        Log.i(TAG, "WiFi NaN attaching")
        if (wifiAwareManager!!.isAvailable) wifiAwareManager.attach(
            attachCallback,
            identityChangedListener,
            null
        )
    }

    fun isWifiAwareSupported(): Boolean
    {
        return wifiAwareSupported;
    }

    @TargetApi(Build.VERSION_CODES.O)
    fun stopScan() {
        if (!wifiAwareSupported) return
        Log.i(TAG, "WiFi NaN closing")
        if (wifiAwareManager!!.isAvailable && wifiAwareSession != null) wifiAwareSession!!.close()
    }

    fun scan() {
        if (!wifiScanEnabled) {
            return
        }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O ||
            !context.getPackageManager().hasSystemFeature(PackageManager.FEATURE_WIFI_AWARE)) {
            Log.i(TAG, "WiFi Aware is not supported.");
            return;
        }
        wifiAwareSupported = true;
        isScanning = true
        context.registerReceiver(myReceiver, IntentFilter(WifiAwareManager.ACTION_WIFI_AWARE_STATE_CHANGED))
        Log.d(TAG, "start_scan:")
    }

    @RequiresApi(Build.VERSION_CODES.O)
    fun cancel() {
        if (!wifiAwareSupported) return
        Log.i(TAG, "WiFi NaN closing")
        if (wifiAwareManager!!.isAvailable && wifiAwareSession != null) wifiAwareSession!!.close()
    }
}