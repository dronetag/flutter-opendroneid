import 'enums.dart';
import 'odid_message.dart';

class LocationMessage extends OdidMessage {
  /// The reported current status of the aircraft
  final AircraftStatus status;

  /// The type of reported height
  ///
  /// (The default type is takeoff height)
  final HeightType heightType;

  /// Direction of the aircraft heading (in degrees)
  final int? direction;

  /// Horizontal speed of the aircraft
  final double? speedHorizontal;

  /// Vertical speed of the aircraft
  final double? speedVertical;

  /// Location latitude of the aircraft
  final double? latitude;

  /// Location longitude of the aircraft
  final double? longitude;

  /// Altitude calculcated from barometric pressure (in meters)
  final double? altitudePressure;

  /// Altitude calculated from GNSS data (in meters)
  final double? altitudeGeodetic;

  /// Current height of the aircraft
  final double? height;

  /// Horizontal accuracy of reported position via GNSS
  final HorizontalAccuracy horizontalAccuracy;

  /// Vertical accuracy of reported altitude via GNSS
  final VerticalAccuracy verticalAccuracy;

  /// Vertical accuracy of reported altitude via barometric pressure
  final VerticalAccuracy baroAccuracy;

  /// Speed accuracy of reported position via GNSS
  final SpeedAccuracy speedAccuracy;

  /// Time of the location report
  final DateTime? time;

  /// Accuracy of timestamp values
  final double? timeAccuracy;

  /// Creates a new "LOCATION" OpenDroneID message
  LocationMessage({
    required DateTime received,
    required String macAddress,
    required MessageSource source,
    int? rssi,
    this.status = AircraftStatus.Undeclared,
    this.heightType = HeightType.Takeoff,
    this.direction,
    this.speedHorizontal,
    this.speedVertical,
    this.latitude,
    this.longitude,
    this.altitudePressure,
    this.altitudeGeodetic,
    this.height,
    this.horizontalAccuracy = HorizontalAccuracy.Unknown,
    this.verticalAccuracy = VerticalAccuracy.Unknown,
    this.baroAccuracy = VerticalAccuracy.Unknown,
    this.speedAccuracy = SpeedAccuracy.Unknown,
    this.time,
    this.timeAccuracy,
  }) : super(
          received: received,
          macAddress: macAddress,
          source: source,
          rssi: rssi,
        );

  @override
  MessageType get type => MessageType.Location;

  @override
  String toString() =>
      'LocationMessage { $macAddress ($status) @ $latitude, $longitude, '
      '$height meters, $time }';

  factory LocationMessage.fromMap(Map<Object?, Object?> map) {
    return LocationMessage(
      received: DateTime.now(),
      macAddress: map['macAddress'].toString(),
      source: MessageSource.values[map['source'] as int],
      rssi: map['rssi'] as int?,
      status: AircraftStatus.values[map['status'] as int],
      heightType: HeightType.values[map['heightType'] as int],
      direction: map['direction'] as int,
      speedHorizontal: map['speedHorizontal'] as double,
      speedVertical: map['speedVertical'] as double,
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      altitudePressure: map['altitudePressure'] as double,
      altitudeGeodetic: map['altitudeGeodetic'] as double,
      height: map['height'] as double,
      horizontalAccuracy:
          HorizontalAccuracy.values[map['accuracyHorizontal'] as int],
      verticalAccuracy: VerticalAccuracy.values[map['accuracyVertical'] as int],
      baroAccuracy: VerticalAccuracy.values[map['accuracyBaro'] as int],
      speedAccuracy: SpeedAccuracy.values[map['accuracySpeed'] as int],
      time: convertFromHourTimestamp(map['locationTimestamp'] as int),
      timeAccuracy: map['timeAccuracy'] as double,
    );
  }

  static DateTime convertFromHourTimestamp(int timestamp) {
    // If the timestamp is close to the full hour, but current time doesn't
    // correspond, it's probably delayed timestamp from the previous hour
    final referenceTime = timestamp > 18000 && DateTime.now().minute < 30
        ? DateTime.now().subtract(Duration(hours: 1))
        : DateTime.now();

    final referenceTimestamp =
        referenceTime.millisecondsSinceEpoch ~/ 3600000 * 3600000;

    return DateTime.fromMillisecondsSinceEpoch(
        referenceTimestamp + 100 * timestamp);
  }
}
