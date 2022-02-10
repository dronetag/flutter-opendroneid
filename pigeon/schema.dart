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

class BasicIdMessage {
  // common part
  late final int receivedTimestamp;
  late final String macAddress;
  late final MessageSource source;
  late final int? rssi;

  /// The primary identifier of UAS
  /// (Dronetag devices use their serial number as their UAS ID)
  late final String uasId;

  /// Identification type
  late final IdType idType;

  /// Type of the aircraft
  late UaType uaType;
}

class LocationMessage {
  // common part
  late final int receivedTimestamp;
  late final String macAddress;
  late final MessageSource source;
  late final int? rssi;

  /// The reported current status of the aircraft
  late final AircraftStatus status;

  /// The type of reported height
  ///
  /// (The default type is takeoff height)
  late final HeightType heightType;

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
  late final HorizontalAccuracy horizontalAccuracy;

  /// Vertical accuracy of reported altitude via GNSS
  late final VerticalAccuracy verticalAccuracy;

  /// Vertical accuracy of reported altitude via barometric pressure
  late final VerticalAccuracy baroAccuracy;

  /// Speed accuracy of reported position via GNSS
  late final SpeedAccuracy speedAccuracy;

  /// Time of the location report
  late final int? time;

  /// Accuracy of timestamp values
  late final double? timeAccuracy;
}

class OperatorIdMessage {
  /// Operator ID
  /// late final int receivedTimestamp;
  late final String macAddress;
  late final MessageSource? source;
  late final int? rssi;

  late final String operatorId;
}

@HostApi()
abstract class Api {
  void startScan();
  void stopScan();
  bool isScanning();
  int bluetoothState();
}

@HostApi()
abstract class MessageApi {
  int determineMessageType(Uint8List payload, int offset);
  BasicIdMessage fromBufferBasic(Uint8List payload, int offset);
  LocationMessage fromBufferLocation(Uint8List payload, int offset);
  OperatorIdMessage fromBufferOperatorId(Uint8List payload, int offset);
}
