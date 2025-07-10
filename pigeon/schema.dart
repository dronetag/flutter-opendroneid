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

enum BluetoothPhy {
  None,
  Phy1M,
  Phy2M,
  PhyLECoded,
  Unknown,
}

class ODIDMetadata {
  final String macAddress;

  final MessageSource source;

  final int? rssi;

  final String? btName;

  final int? frequency;

  final int? centerFreq0;

  final int? centerFreq1;

  final int? channelWidthMhz;

  final BluetoothPhy? primaryPhy;

  final BluetoothPhy? secondaryPhy;

  ODIDMetadata({
    required this.macAddress,
    required this.source,
    this.rssi,
    this.btName,
    this.frequency,
    this.channelWidthMhz,
    this.centerFreq0,
    this.centerFreq1,
    this.primaryPhy,
    this.secondaryPhy,
  });
}

/// Payload send from native to dart contains raw data and metadata
class ODIDPayload {
  final Uint8List rawData;

  final int receivedTimestamp;

  final ODIDMetadata metadata;

  ODIDPayload(
    this.rawData,
    this.receivedTimestamp,
    this.metadata,
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
  ODIDPayload buildPayload(
      Uint8List rawData, int receivedTimestamp, ODIDMetadata metadata);
}
