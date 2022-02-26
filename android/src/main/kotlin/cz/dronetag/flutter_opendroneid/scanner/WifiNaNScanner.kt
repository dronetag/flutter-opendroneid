package cz.dronetag.flutter_opendroneid

import android.content.Context
import android.net.wifi.aware.AttachCallback;
import android.net.wifi.aware.DiscoverySessionCallback;
import android.net.wifi.aware.IdentityChangedListener;
import android.net.wifi.aware.PeerHandle;
import android.net.wifi.aware.SubscribeConfig;
import android.net.wifi.aware.SubscribeDiscoverySession;
import android.net.wifi.aware.WifiAwareManager;
import android.net.wifi.aware.WifiAwareSession;

class WifiNaNScanner (
    private val basicMessagesHandler: StreamHandler,
    private val locationMessagesHandler: StreamHandler,
    private val operatorIdMessagesHandler: StreamHandler,
    private val bluetoothStateHandler: StreamHandler,
    private val wifiAwareManager: WifiAwareManager?,
    private val context: Context
) {
    private val messageHandler = OdidMessageHandler()
    private val wifiScanEnabled = true
    var isScanning = false
}