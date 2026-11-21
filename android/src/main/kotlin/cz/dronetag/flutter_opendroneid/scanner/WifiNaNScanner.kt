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


/**
 * Subscribes to Wi-Fi Aware (NAN) service advertisements for ODID payloads.
 *
 * Devices without the Wi-Fi Aware feature report [isWifiAwareSupported] as
 * `false` and never start a session.
 */
class WifiNaNScanner (
    private val sink: OdidSink,
    private val wifiAwareManager: WifiAwareManager?,
    private val context: Context
)  : ODIDScanner(sink) {

    companion object {
        const val WIFI_NAN_OFFSET = 1
    }

    private val TAG: String = WifiNaNScanner::class.java.getSimpleName()
    private val wifiScanEnabled = true
    private var wifiAwareSupported = true
    private var receiverRegistered = false

    private var wifiAwareSession: WifiAwareSession? = null

    // callback for Wi-Fi Aware session advertisement
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
                    if (serviceSpecificInfo != null) {
                        val metadata = ODIDMetadata(
                            macAddress = peerHandle.hashCode().toString(),
                            source = MessageSource.WIFI_NAN,
                        )
                        receiveData(
                            offsetData(serviceSpecificInfo, WIFI_NAN_OFFSET),
                            metadata
                        )
                    }
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
        if (!wifiAwareSupported) return
        val manager = wifiAwareManager ?: return
        if (isScanning) return

        isScanning = true
        registerStateReceiver()
        startScan()
    }

    @RequiresApi(Build.VERSION_CODES.O)
    override fun cancel() {
        if (!wifiAwareSupported) return

        isScanning = false
        if (receiverRegistered) {
            context.unregisterReceiver(adapterStateReceiver)
            receiverRegistered = false
        }
        stopScan()
    }

    @RequiresApi(Build.VERSION_CODES.O)
    override fun onAdapterStateReceived() {
        val manager = wifiAwareManager ?: return
        if (manager.isAvailable) {
            Log.i(TAG, "WiFi Aware became available.")
            startScan()
        }
    }

    fun isWifiAwareSupported(): Boolean {
        return wifiAwareSupported && wifiAwareManager != null
    }

    private fun registerStateReceiver() {
        if (receiverRegistered) return
        val filter = IntentFilter(WifiAwareManager.ACTION_WIFI_AWARE_STATE_CHANGED)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.registerReceiver(adapterStateReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            context.registerReceiver(adapterStateReceiver, filter)
        }
        receiverRegistered = true
    }

    @TargetApi(Build.VERSION_CODES.O)
    private fun startScan() {
        if (!wifiAwareSupported) return
        val manager = wifiAwareManager ?: return
        if (manager.isAvailable)
        {
            manager.attach(
                attachCallback,
                identityChangedListener,
                null
            )
            sink.onWifiScanActive(true)
        }
    }

    @TargetApi(Build.VERSION_CODES.O)
    private fun stopScan() {
        if (!wifiAwareSupported) return
        val manager = wifiAwareManager ?: return
        if (manager.isAvailable && wifiAwareSession != null)
        {
            wifiAwareSession!!.close()
            wifiAwareSession = null
            sink.onWifiScanActive(false)
        }
    }
}
