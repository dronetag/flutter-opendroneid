import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    appDirectory: 'example',
    configDirectory: 'example',
    dartOptions: DartOptions(),
    kotlinOptions: KotlinOptions(useJni: true),
    swiftOptions: SwiftOptions(
      useFfi: true,
      ffiModuleName: 'flutter_opendroneid',
      includeErrorClass: true,
    ),
  ),
)

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
  ODIDMetadata({
    required this.macAddress,
    required this.source,
    this.rssi,
    this.btName,
    this.frequency,
    this.centerFreq0,
    this.centerFreq1,
    this.channelWidthMhz,
    this.primaryPhy,
    this.secondaryPhy,
  });

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
}

/// Payload sent from native to Dart contains raw data and metadata
class ODIDPayload {
  ODIDPayload(this.rawData, this.receivedTimestamp, this.metadata);

  final Uint8List rawData;

  final int receivedTimestamp;

  final ODIDMetadata metadata;
}

@HostApi()
abstract class OdidScannerHostApi {
  void initialize();
  bool isInitialized();
  void startScanBluetooth(String? serviceUuid);
  void startScanWifi();
  void stopScanBluetooth();
  void stopScanWifi();
  void setBtScanPriority(ScanPriority priority);
  void setBtServiceUuid(String? serviceUuid);
  bool isScanningBluetooth();
  bool isScanningWifi();

  /// Waits for the iOS CoreBluetooth state when it is still unknown.
  @async
  int bluetoothState();

  int wifiState();
  bool btExtendedSupported();
  int btMaxAdvDataLen();
  bool wifiNaNSupported();
}

@FlutterApi()
abstract class OdidScannerFlutterApi {
  void onOdidPayload(ODIDPayload payload);
  void onBluetoothScanActive(bool isActive);
  void onWifiScanActive(bool isActive);
}
