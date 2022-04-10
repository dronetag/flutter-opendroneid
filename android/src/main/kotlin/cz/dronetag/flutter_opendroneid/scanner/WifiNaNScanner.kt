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
    private var wifiAwareSupported = true
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

        override fun onAttachFailed() {
            Log.d(TAG, "attach failed")
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
        if(type == Pigeon.MessageType.BasicId)
        {
            val message: Pigeon.BasicIdMessage? = messageHandler.fromBufferBasic(data  as ByteArray, 4,peerHash.hashCode().toString())
            message?.source = Pigeon.MessageSource.WifiNaN
            message?.rssi = 0
            basicMessagesHandler.send(message?.toMap() as Any)
        }
        else if(type == Pigeon.MessageType.Location)
        {
            val message =  messageHandler.fromBufferLocation(data, 4,peerHash.hashCode().toString())
            message?.source = Pigeon.MessageSource.WifiNaN;
            message?.rssi = 0
            locationMessagesHandler.send(message?.toMap() as Any)
        }
        else if(type == Pigeon.MessageType.OperatorId)
        {
            val message = messageHandler.fromBufferOperatorId(data, 4,peerHash.hashCode().toString())
            message?.source = Pigeon.MessageSource.WifiNaN
            message?.rssi = 0
            operatorIdMessagesHandler.send(message?.toMap() as Any)
        }
        else if(type == Pigeon.MessageType.SelfId)
        {
            val message: Pigeon.SelfIdMessage? = messageHandler.fromBufferSelfId(data, 4,peerHash.hashCode().toString())
            message?.source = Pigeon.MessageSource.WifiNaN;
            message?.rssi = 0
            selfIdMessagesHandler.send(message?.toMap() as Any)
        }
        else if(type == Pigeon.MessageType.Auth)
        {
            val message =  messageHandler.fromBufferAuthentication(data, 4,peerHash.hashCode().toString())
            message?.source = Pigeon.MessageSource.WifiNaN;
            message?.rssi = 0
            authenticationMessagesHandler.send(message?.toMap() as Any)
        }
        else if(type == Pigeon.MessageType.System)
        {
            val message = messageHandler.fromBufferSystemData(data, 4,peerHash.hashCode().toString())
            message?.source = Pigeon.MessageSource.WifiNaN;
            message?.rssi = 0
            systemDataMessagesHandler.send(message?.toMap() as Any)
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
        Log.d(TAG, "start_scan NaN:")
        startScan();
    }

    @RequiresApi(Build.VERSION_CODES.O)
    fun cancel() {
        if (!wifiAwareSupported) return
        Log.i(TAG, "WiFi NaN closing")
        if (wifiAwareManager!!.isAvailable && wifiAwareSession != null) wifiAwareSession!!.close()
    }
}