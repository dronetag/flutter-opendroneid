import 'package:pigeon/pigeon.dart';

/// ODID Message Type
enum MessageType {
  BasicId,
  Location,
  Auth,
  SelfId,
  System,
  OperatorId,
}

/// ODID Message Source
enum MessageSource {
  BluetoothLegacy,
  BluetoothLongRange,
  WifiNaN,
  WifiBeacon,
}

/// Identification type
enum IdType {
  None,
  Serial_Number,
  CAA_Registration_ID,
  UTM_Assigned_ID,
  Specific_Session_ID,
}

/// Unmanned aircraft type
enum UaType {
  None,
  Aeroplane,
  Helicopter_or_Multirotor,
  Gyroplane,
  Hybrid_Lift, // VTOL. Fixed wing aircraft that can take off vertically
  Ornithopter,
  Glider,
  Kite,
  Free_balloon,
  Captive_balloon,
  Airship,
  Free_fall_parachute, // Unpowered
  Rocket,
  Tethered_powered_aircraft,
  Ground_obstacle,
  Other,
}

/// Aircraft flight status
enum AircraftStatus {
  Undeclared,
  Ground,
  Airborne,
  Emergency,
}

/// Height value type
enum HeightType {
  Takeoff,
  Ground,
}

/// Horizontal accuracy
enum HorizontalAccuracy {
  Unknown,
  kilometers_18_52,
  kilometers_7_408,
  kilometers_3_704,
  kilometers_1_852,
  meters_926,
  meters_555_6,
  meters_185_2,
  meters_92_6,
  meters_30,
  meters_10,
  meters_3,
  meters_1,
}

/// Vertical accuracy
enum VerticalAccuracy {
  Unknown,
  meters_150,
  meters_45,
  meters_25,
  meters_10,
  meters_3,
  meters_1,
}

/// Speed accuracy
enum SpeedAccuracy {
  Unknown,
  meter_per_second_10,
  meter_per_second_3,
  meter_per_second_1,
  meter_per_second_0_3,
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

enum AuthType {
  None,
  UAS_ID_Signature,
  Operator_ID_Signature,
  Message_Set_Signature,
  Network_Remote_ID,
  Specific_Authentication,
  Private_Use_0xA,
  Private_Use_0xB,
  Private_Use_0xC,
  Private_Use_0xD,
  Private_Use_0xE,
  Private_Use_0xF
}

enum AircraftCategory {
  Undeclared,
  EU_Open,
  EU_Specific,
  EU_Certified,
}

enum AircraftClass {
  Undeclared,
  EU_Class_0,
  EU_Class_1,
  EU_Class_2,
  EU_Class_3,
  EU_Class_4,
  EU_Class_5,
  EU_Class_6,
}

enum OperatorLocationType { TakeOff, LiveGNSS, FixedLocation, Invalid }

enum ClassificationType {
  Undeclared,
  EU, // European Union
}

class BasicIdMessage {
  // common part
  late final int receivedTimestamp;
  late final String macAddress;
  late final MessageSource? source;
  late final int? rssi;

  /// The primary identifier of UAS
  /// (Dronetag devices use their serial number as their UAS ID)
  late final String uasId;

  /// Identification type
  late final IdType? idType;

  /// Type of the aircraft
  late UaType? uaType;
}

class LocationMessage {
  // common part
  late final int receivedTimestamp;
  late final String macAddress;
  late final MessageSource? source;
  late final int? rssi;

  /// The reported current status of the aircraft
  late final AircraftStatus? status;

  /// The type of reported height
  ///
  /// (The default type is takeoff height)
  late final HeightType? heightType;

  /// Direction of the aircraft heading (in degrees)
  late final int? direction;

  /// Horizontal speed of the aircraft
  late final double? speedHorizontal;

  /// Vertical speed of the aircraft
  late final double? speedVertical;

  /// Location latitude of the aircraft
  late final double? latitude;

  /// Location longitude of the aircraft
  late final double? longitude;

  /// Altitude calculcated from barometric pressure (in meters)
  late final double? altitudePressure;

  /// Altitude calculated from GNSS data (in meters)
  late final double? altitudeGeodetic;

  /// Current height of the aircraft
  late final double? height;

  /// Horizontal accuracy of reported position via GNSS
  late final HorizontalAccuracy? horizontalAccuracy;

  /// Vertical accuracy of reported altitude via GNSS
  late final VerticalAccuracy? verticalAccuracy;

  /// Vertical accuracy of reported altitude via barometric pressure
  late final VerticalAccuracy? baroAccuracy;

  /// Speed accuracy of reported position via GNSS
  late final SpeedAccuracy? speedAccuracy;

  /// Time of the location report
  late final int? time;

  /// Accuracy of timestamp values
  late final double? timeAccuracy;
}

class OperatorIdMessage {
  /// Operator ID
  late final int receivedTimestamp;
  late final String macAddress;
  late final MessageSource? source;
  late final int? rssi;

  late final String operatorId;
}

class AuthenticationMessage {
  // common part
  late final int receivedTimestamp;
  late final String macAddress;
  late final MessageSource? source;
  late final int? rssi;

  late final AuthType? authType;
  late final int authDataPage;
  late final int authLastPageIndex;
  late final int authLength;
  late final int authTimestamp;
  late final String authData;
}

class SelfIdMessage {
  // common part
  late final int receivedTimestamp;
  late final String macAddress;
  late final MessageSource? source;
  late final int? rssi;

  late final int descriptionType;
  late final String operationDescription;
}

class SystemDataMessage {
  // common part
  late final int receivedTimestamp;
  late final String macAddress;
  late final MessageSource? source;
  late final int? rssi;

  late final OperatorLocationType? operatorLocationType;
  late final ClassificationType? classificationType;
  late final double operatorLatitude;
  late final double operatorLongitude;
  late final int areaCount;
  late final int areaRadius;
  late final double areaCeiling;
  late final double areaFloor;
  late final AircraftCategory? category;
  late final AircraftClass? classValue;
  late final double operatorAltitudeGeo;
}

class ConnectionMessage {
  // common part
  late final int receivedTimestamp;
  late final String macAddress;
  late final MessageSource? source;
  late final int? rssi;

  late final String transportType;
  late final int lastSeen;
  late final int firstSeen;
  late final int msgDelta;
}

@HostApi()
abstract class Api {
  @async
  void startScanBluetooth();
  @async
  void startScanWifi();
  @async
  void stopScanBluetooth();
  @async
  void stopScanWifi();
  @async
  void setAutorestartBluetooth(bool enable);
  @async
  bool isScanningBluetooth();
  @async
  bool isScanningWifi();
  @async
  int bluetoothState();
  @async
  bool btExtendedSupported();
  @async
  int btMaxAdvDataLen();
  @async
  bool wifiNaNSupported();
}

@HostApi()
abstract class MessageApi {
  int determineMessageType(Uint8List payload, int offset);
  BasicIdMessage fromBufferBasic(
      Uint8List payload, int offset, String macAddress);
  LocationMessage fromBufferLocation(
      Uint8List payload, int offset, String macAddress);
  OperatorIdMessage fromBufferOperatorId(
      Uint8List payload, int offset, String macAddress);
  SelfIdMessage fromBufferSelfId(
      Uint8List payload, int offset, String macAddress);
  AuthenticationMessage fromBufferAuthentication(
      Uint8List payload, int offset, String macAddress);
  SystemDataMessage fromBufferSystemData(
      Uint8List payload, int offset, String macAddress);
  ConnectionMessage fromBufferConnection(
      Uint8List payload, int offset, String macAddress);
}
