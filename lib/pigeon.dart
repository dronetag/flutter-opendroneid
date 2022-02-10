// Autogenerated from Pigeon (v1.0.17), do not edit directly.
// See also: https://pub.dev/packages/pigeon
// ignore_for_file: public_member_api_docs, non_constant_identifier_names, avoid_as, unused_import, unnecessary_parenthesis, prefer_null_aware_operators, omit_local_variable_types, unused_shown_name
// @dart = 2.12
import 'dart:async';
import 'dart:typed_data' show Uint8List, Int32List, Int64List, Float64List;

import 'package:flutter/foundation.dart' show WriteBuffer, ReadBuffer;
import 'package:flutter/services.dart';

enum MessageType {
  BasicId,
  Location,
  Auth,
  SelfId,
  System,
  OperatorId,
}

enum MessageSource {
  BluetoothLegacy,
  BluetoothLongRange,
  WifiNaN,
  WifiBeacon,
}

enum IdType {
  None,
  Serial_Number,
  CAA_Registration_ID,
  UTM_Assigned_ID,
  Specific_Session_ID,
}

enum UaType {
  None,
  Aeroplane,
  Helicopter_or_Multirotor,
  Gyroplane,
  Hybrid_Lift,
  Ornithopter,
  Glider,
  Kite,
  Free_balloon,
  Captive_balloon,
  Airship,
  Free_fall_parachute,
  Rocket,
  Tethered_powered_aircraft,
  Ground_obstacle,
  Other,
}

enum AircraftStatus {
  Undeclared,
  Ground,
  Airborne,
  Emergency,
}

enum HeightType {
  Takeoff,
  Ground,
}

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

enum VerticalAccuracy {
  Unknown,
  meters_150,
  meters_45,
  meters_25,
  meters_10,
  meters_3,
  meters_1,
}

enum SpeedAccuracy {
  Unknown,
  meter_per_second_10,
  meter_per_second_3,
  meter_per_second_1,
  meter_per_second_0_3,
}

enum BluetoothState {
  Unknown,
  Resetting,
  Unsupported,
  Unauthorized,
  PoweredOff,
  PoweredOn,
}

class BasicIdMessage {
  BasicIdMessage({
    required this.receivedTimestamp,
    required this.macAddress,
    required this.source,
    this.rssi,
    required this.uasId,
    required this.idType,
    required this.uaType,
  });

  int receivedTimestamp;
  String macAddress;
  MessageSource source;
  int? rssi;
  String uasId;
  IdType idType;
  UaType uaType;

  Object encode() {
    final Map<Object?, Object?> pigeonMap = <Object?, Object?>{};
    pigeonMap['receivedTimestamp'] = receivedTimestamp;
    pigeonMap['macAddress'] = macAddress;
    pigeonMap['source'] = source == null ? null : source!.index;
    pigeonMap['rssi'] = rssi;
    pigeonMap['uasId'] = uasId;
    pigeonMap['idType'] = idType == null ? null : idType!.index;
    pigeonMap['uaType'] = uaType == null ? null : uaType!.index;
    return pigeonMap;
  }

  static BasicIdMessage decode(Object message) {
    final Map<Object?, Object?> pigeonMap = message as Map<Object?, Object?>;
    return BasicIdMessage(
      receivedTimestamp: pigeonMap['receivedTimestamp']! as int,
      macAddress: pigeonMap['macAddress']! as String,
      source: pigeonMap['source'] != null
          ? MessageSource.values[pigeonMap['source']! as int]
          : null,
      rssi: pigeonMap['rssi'] as int?,
      uasId: pigeonMap['uasId']! as String,
      idType: pigeonMap['idType'] != null
          ? IdType.values[pigeonMap['idType']! as int]
          : null,
      uaType: pigeonMap['uaType'] != null
          ? UaType.values[pigeonMap['uaType']! as int]
          : null,
    );
  }
}

class LocationMessage {
  LocationMessage({
    required this.receivedTimestamp,
    required this.macAddress,
    required this.source,
    this.rssi,
    required this.status,
    required this.heightType,
    this.direction,
    this.speedHorizontal,
    this.speedVertical,
    this.latitude,
    this.longitude,
    this.altitudePressure,
    this.altitudeGeodetic,
    this.height,
    required this.horizontalAccuracy,
    required this.verticalAccuracy,
    required this.baroAccuracy,
    required this.speedAccuracy,
    this.time,
    this.timeAccuracy,
  });

  int receivedTimestamp;
  String macAddress;
  MessageSource source;
  int? rssi;
  AircraftStatus status;
  HeightType heightType;
  int? direction;
  double? speedHorizontal;
  double? speedVertical;
  double? latitude;
  double? longitude;
  double? altitudePressure;
  double? altitudeGeodetic;
  double? height;
  HorizontalAccuracy horizontalAccuracy;
  VerticalAccuracy verticalAccuracy;
  VerticalAccuracy baroAccuracy;
  SpeedAccuracy speedAccuracy;
  int? time;
  double? timeAccuracy;

  Object encode() {
    final Map<Object?, Object?> pigeonMap = <Object?, Object?>{};
    pigeonMap['receivedTimestamp'] = receivedTimestamp;
    pigeonMap['macAddress'] = macAddress;
    pigeonMap['source'] = source == null ? null : source!.index;
    pigeonMap['rssi'] = rssi;
    pigeonMap['status'] = status == null ? null : status!.index;
    pigeonMap['heightType'] = heightType == null ? null : heightType!.index;
    pigeonMap['direction'] = direction;
    pigeonMap['speedHorizontal'] = speedHorizontal;
    pigeonMap['speedVertical'] = speedVertical;
    pigeonMap['latitude'] = latitude;
    pigeonMap['longitude'] = longitude;
    pigeonMap['altitudePressure'] = altitudePressure;
    pigeonMap['altitudeGeodetic'] = altitudeGeodetic;
    pigeonMap['height'] = height;
    pigeonMap['horizontalAccuracy'] = horizontalAccuracy == null ? null : horizontalAccuracy!.index;
    pigeonMap['verticalAccuracy'] = verticalAccuracy == null ? null : verticalAccuracy!.index;
    pigeonMap['baroAccuracy'] = baroAccuracy == null ? null : baroAccuracy!.index;
    pigeonMap['speedAccuracy'] = speedAccuracy == null ? null : speedAccuracy!.index;
    pigeonMap['time'] = time;
    pigeonMap['timeAccuracy'] = timeAccuracy;
    return pigeonMap;
  }

  static LocationMessage decode(Object message) {
    final Map<Object?, Object?> pigeonMap = message as Map<Object?, Object?>;
    return LocationMessage(
      receivedTimestamp: pigeonMap['receivedTimestamp']! as int,
      macAddress: pigeonMap['macAddress']! as String,
      source: pigeonMap['source'] != null
          ? MessageSource.values[pigeonMap['source']! as int]
          : null,
      rssi: pigeonMap['rssi'] as int?,
      status: pigeonMap['status'] != null
          ? AircraftStatus.values[pigeonMap['status']! as int]
          : null,
      heightType: pigeonMap['heightType'] != null
          ? HeightType.values[pigeonMap['heightType']! as int]
          : null,
      direction: pigeonMap['direction'] as int?,
      speedHorizontal: pigeonMap['speedHorizontal'] as double?,
      speedVertical: pigeonMap['speedVertical'] as double?,
      latitude: pigeonMap['latitude'] as double?,
      longitude: pigeonMap['longitude'] as double?,
      altitudePressure: pigeonMap['altitudePressure'] as double?,
      altitudeGeodetic: pigeonMap['altitudeGeodetic'] as double?,
      height: pigeonMap['height'] as double?,
      horizontalAccuracy: pigeonMap['horizontalAccuracy'] != null
          ? HorizontalAccuracy.values[pigeonMap['horizontalAccuracy']! as int]
          : null,
      verticalAccuracy: pigeonMap['verticalAccuracy'] != null
          ? VerticalAccuracy.values[pigeonMap['verticalAccuracy']! as int]
          : null,
      baroAccuracy: pigeonMap['baroAccuracy'] != null
          ? VerticalAccuracy.values[pigeonMap['baroAccuracy']! as int]
          : null,
      speedAccuracy: pigeonMap['speedAccuracy'] != null
          ? SpeedAccuracy.values[pigeonMap['speedAccuracy']! as int]
          : null,
      time: pigeonMap['time'] as int?,
      timeAccuracy: pigeonMap['timeAccuracy'] as double?,
    );
  }
}

class OperatorIdMessage {
  OperatorIdMessage({
    required this.macAddress,
    this.source,
    this.rssi,
    required this.operatorId,
  });

  String macAddress;
  MessageSource? source;
  int? rssi;
  String operatorId;

  Object encode() {
    final Map<Object?, Object?> pigeonMap = <Object?, Object?>{};
    pigeonMap['macAddress'] = macAddress;
    pigeonMap['source'] = source == null ? null : source!.index;
    pigeonMap['rssi'] = rssi;
    pigeonMap['operatorId'] = operatorId;
    return pigeonMap;
  }

  static OperatorIdMessage decode(Object message) {
    final Map<Object?, Object?> pigeonMap = message as Map<Object?, Object?>;
    return OperatorIdMessage(
      macAddress: pigeonMap['macAddress']! as String,
      source: pigeonMap['source'] != null
          ? MessageSource.values[pigeonMap['source']! as int]
          : null,
      rssi: pigeonMap['rssi'] as int?,
      operatorId: pigeonMap['operatorId']! as String,
    );
  }
}

class _ApiCodec extends StandardMessageCodec {
  const _ApiCodec();
}

class Api {
  /// Constructor for [Api].  The [binaryMessenger] named argument is
  /// available for dependency injection.  If it is left null, the default
  /// BinaryMessenger will be used which routes to the host platform.
  Api({BinaryMessenger? binaryMessenger}) : _binaryMessenger = binaryMessenger;

  final BinaryMessenger? _binaryMessenger;

  static const MessageCodec<Object?> codec = _ApiCodec();

  Future<void> startScan() async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.Api.startScan', codec, binaryMessenger: _binaryMessenger);
    final Map<Object?, Object?>? replyMap =
        await channel.send(null) as Map<Object?, Object?>?;
    if (replyMap == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
        details: null,
      );
    } else if (replyMap['error'] != null) {
      final Map<Object?, Object?> error = (replyMap['error'] as Map<Object?, Object?>?)!;
      throw PlatformException(
        code: (error['code'] as String?)!,
        message: error['message'] as String?,
        details: error['details'],
      );
    } else {
      return;
    }
  }

  Future<void> stopScan() async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.Api.stopScan', codec, binaryMessenger: _binaryMessenger);
    final Map<Object?, Object?>? replyMap =
        await channel.send(null) as Map<Object?, Object?>?;
    if (replyMap == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
        details: null,
      );
    } else if (replyMap['error'] != null) {
      final Map<Object?, Object?> error = (replyMap['error'] as Map<Object?, Object?>?)!;
      throw PlatformException(
        code: (error['code'] as String?)!,
        message: error['message'] as String?,
        details: error['details'],
      );
    } else {
      return;
    }
  }

  Future<bool> isScanning() async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.Api.isScanning', codec, binaryMessenger: _binaryMessenger);
    final Map<Object?, Object?>? replyMap =
        await channel.send(null) as Map<Object?, Object?>?;
    if (replyMap == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
        details: null,
      );
    } else if (replyMap['error'] != null) {
      final Map<Object?, Object?> error = (replyMap['error'] as Map<Object?, Object?>?)!;
      throw PlatformException(
        code: (error['code'] as String?)!,
        message: error['message'] as String?,
        details: error['details'],
      );
    } else {
      return (replyMap['result'] as bool?)!;
    }
  }

  Future<int> bluetoothState() async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.Api.bluetoothState', codec, binaryMessenger: _binaryMessenger);
    final Map<Object?, Object?>? replyMap =
        await channel.send(null) as Map<Object?, Object?>?;
    if (replyMap == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
        details: null,
      );
    } else if (replyMap['error'] != null) {
      final Map<Object?, Object?> error = (replyMap['error'] as Map<Object?, Object?>?)!;
      throw PlatformException(
        code: (error['code'] as String?)!,
        message: error['message'] as String?,
        details: error['details'],
      );
    } else {
      return (replyMap['result'] as int?)!;
    }
  }
}

class _MessageApiCodec extends StandardMessageCodec {
  const _MessageApiCodec();
  @override
  void writeValue(WriteBuffer buffer, Object? value) {
    if (value is BasicIdMessage) {
      buffer.putUint8(128);
      writeValue(buffer, value.encode());
    } else 
    if (value is LocationMessage) {
      buffer.putUint8(129);
      writeValue(buffer, value.encode());
    } else 
    if (value is OperatorIdMessage) {
      buffer.putUint8(130);
      writeValue(buffer, value.encode());
    } else 
{
      super.writeValue(buffer, value);
    }
  }
  @override
  Object? readValueOfType(int type, ReadBuffer buffer) {
    switch (type) {
      case 128:       
        return BasicIdMessage.decode(readValue(buffer)!);
      
      case 129:       
        return LocationMessage.decode(readValue(buffer)!);
      
      case 130:       
        return OperatorIdMessage.decode(readValue(buffer)!);
      
      default:      
        return super.readValueOfType(type, buffer);
      
    }
  }
}

class MessageApi {
  /// Constructor for [MessageApi].  The [binaryMessenger] named argument is
  /// available for dependency injection.  If it is left null, the default
  /// BinaryMessenger will be used which routes to the host platform.
  MessageApi({BinaryMessenger? binaryMessenger}) : _binaryMessenger = binaryMessenger;

  final BinaryMessenger? _binaryMessenger;

  static const MessageCodec<Object?> codec = _MessageApiCodec();

  Future<int> determineMessageType(Uint8List arg_payload, int arg_offset) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.MessageApi.determineMessageType', codec, binaryMessenger: _binaryMessenger);
    final Map<Object?, Object?>? replyMap =
        await channel.send(<Object>[arg_payload, arg_offset]) as Map<Object?, Object?>?;
    if (replyMap == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
        details: null,
      );
    } else if (replyMap['error'] != null) {
      final Map<Object?, Object?> error = (replyMap['error'] as Map<Object?, Object?>?)!;
      throw PlatformException(
        code: (error['code'] as String?)!,
        message: error['message'] as String?,
        details: error['details'],
      );
    } else {
      return (replyMap['result'] as int?)!;
    }
  }

  Future<BasicIdMessage> fromBufferBasic(Uint8List arg_payload, int arg_offset) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.MessageApi.fromBufferBasic', codec, binaryMessenger: _binaryMessenger);
    final Map<Object?, Object?>? replyMap =
        await channel.send(<Object>[arg_payload, arg_offset]) as Map<Object?, Object?>?;
    if (replyMap == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
        details: null,
      );
    } else if (replyMap['error'] != null) {
      final Map<Object?, Object?> error = (replyMap['error'] as Map<Object?, Object?>?)!;
      throw PlatformException(
        code: (error['code'] as String?)!,
        message: error['message'] as String?,
        details: error['details'],
      );
    } else {
      return (replyMap['result'] as BasicIdMessage?)!;
    }
  }

  Future<LocationMessage> fromBufferLocation(Uint8List arg_payload, int arg_offset) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.MessageApi.fromBufferLocation', codec, binaryMessenger: _binaryMessenger);
    final Map<Object?, Object?>? replyMap =
        await channel.send(<Object>[arg_payload, arg_offset]) as Map<Object?, Object?>?;
    if (replyMap == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
        details: null,
      );
    } else if (replyMap['error'] != null) {
      final Map<Object?, Object?> error = (replyMap['error'] as Map<Object?, Object?>?)!;
      throw PlatformException(
        code: (error['code'] as String?)!,
        message: error['message'] as String?,
        details: error['details'],
      );
    } else {
      return (replyMap['result'] as LocationMessage?)!;
    }
  }

  Future<OperatorIdMessage> fromBufferOperatorId(Uint8List arg_payload, int arg_offset) async {
    final BasicMessageChannel<Object?> channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.MessageApi.fromBufferOperatorId', codec, binaryMessenger: _binaryMessenger);
    final Map<Object?, Object?>? replyMap =
        await channel.send(<Object>[arg_payload, arg_offset]) as Map<Object?, Object?>?;
    if (replyMap == null) {
      throw PlatformException(
        code: 'channel-error',
        message: 'Unable to establish connection on channel.',
        details: null,
      );
    } else if (replyMap['error'] != null) {
      final Map<Object?, Object?> error = (replyMap['error'] as Map<Object?, Object?>?)!;
      throw PlatformException(
        code: (error['code'] as String?)!,
        message: error['message'] as String?,
        details: error['details'],
      );
    } else {
      return (replyMap['result'] as OperatorIdMessage?)!;
    }
  }
}
