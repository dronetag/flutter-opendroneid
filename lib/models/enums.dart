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
