import 'package:pigeon/pigeon.dart';

/// Higher priority drains battery but receives more data
enum ScanPriority {
  High,
  Low,
}

/// ODID Message Source
enum MessageSource {
  BluetoothLegacy,
  BluetoothLongRange,
  WifiNan,
  WifiBeacon,
  Unknown,
}

/// State of the Bluetooth adapter
enum BluetoothState {
  Unknown,
  Resetting,
  Unsupported,
  Unauthorized,
  PoweredOff,
  PoweredOn,
}

/// State of the Wifi adapter
enum WifiState {
  Disabling,
  Disabled,
  Enabling,
  Enabled,
}

/// Payload send from native to dart contains raw data and metadata
class ODIDPayload {
  final Uint8List rawData;

  final int receivedTimestamp;

  final String macAddress;

  final int? rssi;

  final MessageSource source;

  final String? btName;

  ODIDPayload(
    this.rawData,
    this.receivedTimestamp,
    this.macAddress,
    this.rssi,
    this.source,
    this.btName,
  );
}

@HostApi()
abstract class Api {
  @async
  void initialize();
  @async
  bool isInitialized();
  @async
  void startScanBluetooth(String? serviceUuid);
  @async
  void startScanWifi();
  @async
  void stopScanBluetooth();
  @async
  void stopScanWifi();
  @async
  void setBtScanPriority(ScanPriority priority);
  @async
  bool isScanningBluetooth();
  @async
  bool isScanningWifi();
  @async
  int bluetoothState();
  @async
  int wifiState();
  @async
  bool btExtendedSupported();
  @async
  int btMaxAdvDataLen();
  @async
  bool wifiNaNSupported();
}

// ODIDPayload is not generated until used in API
@HostApi()
abstract class PayloadApi {
  ODIDPayload buildPayload(Uint8List rawData, MessageSource source,
      String macAddress, String? btName, int rssi, int receivedTimestamp);
}
