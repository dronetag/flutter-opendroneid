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
    private val basicMessagesHandler: StreamHandler,
    private val locationMessagesHandler: StreamHandler,
    private val operatorIdMessagesHandler: StreamHandler,
    private val selfIdMessagesHandler: StreamHandler,
    private val authenticationMessagesHandler: StreamHandler,
    private val systemDataMessagesHandler: StreamHandler,
    private val wifiStateHandler: StreamHandler,
    private val wifiAwareManager: WifiAwareManager?,
    private val context: Context
) {
    private val messageHandler = OdidMessageHandler()
    private var wifiAwareSession: WifiAwareSession? = null
    private val wifiScanEnabled = true
    private var wifiAwareSupported = true
    var isScanning = false
    private val TAG: String = WifiNaNScanner::class.java.getSimpleName()

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
                override fun onServiceDiscovered(
                    peerHandle: PeerHandle?,
                    serviceSpecificInfo: ByteArray?,
                    matchFilter: MutableList<ByteArray>?
                ) {
                    val transportType = "NAN"

                    val timeNano: Long = SystemClock.elapsedRealtimeNanos()
                    receiveDataNaN(
                        serviceSpecificInfo,
                        peerHandle.hashCode(),
                        timeNano,
                        transportType
                    )
                }
            }, null)
        }

    }

    fun receiveDataNaN(
        data: ByteArray?, peerHash: Int, timeNano: Long,
        transportType: String?
    ) {
        val typeOrdinal = messageHandler.determineMessageType(data as ByteArray, 4);
        val byteBuffer = ByteBuffer.wrap(data, 4, 25)
        byteBuffer.order(ByteOrder.LITTLE_ENDIAN)
        if(typeOrdinal == null)
            return;
        val type = Pigeon.MessageType.values()[typeOrdinal.toInt()]
        if(type == Pigeon.MessageType.BASIC_ID)
        {
            val message: Pigeon.BasicIdMessage? = messageHandler.fromBufferBasic(data  as ByteArray, 4,peerHash.hashCode().toString())
            message?.source = Pigeon.MessageSource.WIFI_NAN
            message?.rssi = 0
            basicMessagesHandler.send(message?.toList() as Any)
        }
        else if(type == Pigeon.MessageType.LOCATION)
        {
            val message =  messageHandler.fromBufferLocation(data, 4,peerHash.hashCode().toString())
            message?.source = Pigeon.MessageSource.WIFI_NAN;
            message?.rssi = 0
            locationMessagesHandler.send(message?.toList() as Any)
        }
        else if(type == Pigeon.MessageType.OPERATOR_ID)
        {
            val message = messageHandler.fromBufferOperatorId(data, 4,peerHash.hashCode().toString())
            message?.source = Pigeon.MessageSource.WIFI_NAN
            message?.rssi = 0
            operatorIdMessagesHandler.send(message?.toList() as Any)
        }
        else if(type == Pigeon.MessageType.SELF_ID)
        {
            val message: Pigeon.SelfIdMessage? = messageHandler.fromBufferSelfId(data, 4,peerHash.hashCode().toString())
            message?.source = Pigeon.MessageSource.WIFI_NAN;
            message?.rssi = 0
            selfIdMessagesHandler.send(message?.toList() as Any)
        }
        else if(type == Pigeon.MessageType.AUTH)
        {
            val message =  messageHandler.fromBufferAuthentication(data, 4,peerHash.hashCode().toString())
            message?.source = Pigeon.MessageSource.WIFI_NAN;
            message?.rssi = 0
            authenticationMessagesHandler.send(message?.toList() as Any)
        }
        else if(type == Pigeon.MessageType.SYSTEM)
        {
            val message = messageHandler.fromBufferSystemData(data, 4,peerHash.hashCode().toString())
            message?.source = Pigeon.MessageSource.WIFI_NAN;
            message?.rssi = 0
            systemDataMessagesHandler.send(message?.toList() as Any)
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

    @TargetApi(Build.VERSION_CODES.O)
    fun startScan() {
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

    fun isWifiAwareSupported(): Boolean
    {
        return wifiAwareSupported;
    }

    @TargetApi(Build.VERSION_CODES.O)
    fun stopScan() {
        if (!wifiAwareSupported) return
        if (wifiAwareManager != null && wifiAwareManager!!.isAvailable && wifiAwareSession != null)
        {
            wifiAwareSession!!.close()
            wifiStateHandler.send(false)
        }
    }

    fun scan() {
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
        context.registerReceiver(myReceiver, IntentFilter(WifiAwareManager.ACTION_WIFI_AWARE_STATE_CHANGED))
        startScan();
    }

    @RequiresApi(Build.VERSION_CODES.O)
    fun cancel() {
        if (!wifiAwareSupported) return
        isScanning = false;
        stopScan()
    }
}