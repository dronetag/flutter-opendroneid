import 'dart:ui';

import 'package:flutter_opendroneid/models/constants.dart';
import 'package:flutter_opendroneid/pigeon.dart' as pigeon;

class MessagePack {
  // FIXME: Rename to avoid clash with ODID MessagePack
  final String macAddress;
  final int? lastMessageRssi;
  final DateTime lastUpdate;
  final pigeon.BasicIdMessage? basicIdMessage;
  final pigeon.LocationMessage? locationMessage;
  final pigeon.OperatorIdMessage? operatorIdMessage;
  final pigeon.SelfIdMessage? selfIdMessage;
  final pigeon.AuthenticationMessage? authenticationMessage;
  final pigeon.SystemDataMessage? systemDataMessage;

  MessagePack({
    required this.macAddress,
    this.lastMessageRssi,
    required this.lastUpdate,
    this.basicIdMessage,
    this.locationMessage,
    this.operatorIdMessage,
    this.selfIdMessage,
    this.authenticationMessage,
    this.systemDataMessage,
  });

  static const colorMax = 120;
  static const colorOffset = 90;

  MessagePack copyWith({
    String? macAddress,
    int? lastMessageRssi,
    DateTime? lastUpdate,
    pigeon.BasicIdMessage? basicIdMessage,
    pigeon.LocationMessage? locationMessage,
    pigeon.OperatorIdMessage? operatorIdMessage,
    pigeon.SelfIdMessage? selfIdMessage,
    pigeon.AuthenticationMessage? authenticationMessage,
    pigeon.SystemDataMessage? systemDataMessage,
  }) =>
      MessagePack(
        macAddress: macAddress ?? this.macAddress,
        lastMessageRssi: lastMessageRssi ?? this.lastMessageRssi,
        lastUpdate: lastUpdate ?? DateTime.now(),
        basicIdMessage: basicIdMessage ?? this.basicIdMessage,
        locationMessage: locationMessage ?? this.locationMessage,
        operatorIdMessage: operatorIdMessage ?? this.operatorIdMessage,
        selfIdMessage: selfIdMessage ?? this.selfIdMessage,
        authenticationMessage:
            authenticationMessage ?? this.authenticationMessage,
        systemDataMessage: systemDataMessage ?? this.systemDataMessage,
      );

  MessagePack updateWithBasic(pigeon.BasicIdMessage message) {
    return copyWith(
        basicIdMessage: message,
        lastMessageRssi: message.rssi,
        lastUpdate:
            DateTime.fromMillisecondsSinceEpoch(message.receivedTimestamp));
  }

  MessagePack updateWithLocation(pigeon.LocationMessage message) {
    return copyWith(
        locationMessage: message,
        lastMessageRssi: message.rssi,
        lastUpdate:
            DateTime.fromMillisecondsSinceEpoch(message.receivedTimestamp));
  }

  MessagePack updateWithOperatorId(pigeon.OperatorIdMessage message) {
    return copyWith(
        operatorIdMessage: message,
        lastMessageRssi: message.rssi,
        lastUpdate:
            DateTime.fromMillisecondsSinceEpoch(message.receivedTimestamp));
  }

  MessagePack updateWithAuthentication(pigeon.AuthenticationMessage message) {
    return copyWith(
        authenticationMessage: message,
        lastMessageRssi: message.rssi,
        lastUpdate:
            DateTime.fromMillisecondsSinceEpoch(message.receivedTimestamp));
  }

  MessagePack updateWithSystemData(pigeon.SystemDataMessage message) {
    return copyWith(
        systemDataMessage: message,
        lastMessageRssi: message.rssi,
        lastUpdate:
            DateTime.fromMillisecondsSinceEpoch(message.receivedTimestamp));
  }

  MessagePack updateWithSelfId(pigeon.SelfIdMessage message) {
    return copyWith(
        selfIdMessage: message,
        lastMessageRssi: message.rssi,
        lastUpdate:
            DateTime.fromMillisecondsSinceEpoch(message.receivedTimestamp));
  }

  pigeon.MessageSource getPackSource() {
    if (locationMessage != null && locationMessage!.source != null)
      return locationMessage!.source!;
    if (selfIdMessage != null && selfIdMessage!.source != null)
      return selfIdMessage!.source!;
    if (basicIdMessage != null && basicIdMessage!.source != null)
      return basicIdMessage!.source!;
    if (operatorIdMessage != null && operatorIdMessage!.source != null)
      return operatorIdMessage!.source!;
    if (systemDataMessage != null && systemDataMessage!.source != null)
      return systemDataMessage!.source!;
    if (authenticationMessage != null && authenticationMessage!.source != null)
      return authenticationMessage!.source!;
    return pigeon.MessageSource.Unknown;
  }

  /// Calculates a color from mac address, that uniquely identifies the device
  Color getPackColor() {
    final len = macAddress.length;
    return Color.fromARGB(
      locationMessage?.status != pigeon.AircraftStatus.Airborne ? 80 : 255,
      colorOffset +
          32 +
          macAddress
                  .substring(0, len ~/ 2)
                  .codeUnits
                  .reduce((sum, e) => sum + e) %
              (colorMax - 32),
      colorOffset +
          macAddress.codeUnits.reduce((sum, e) => (sum * e) % colorMax),
      colorOffset +
          macAddress
              .substring(len ~/ 2)
              .codeUnits
              .fold(255, (sum, e) => sum - e % colorMax),
    );
  }

  bool operatorIDSet() {
    return operatorIdMessage != null && operatorIdMessage!.operatorId != "NULL";
  }

  bool systemDataValid() {
    return systemDataMessage != null &&
        systemDataMessage?.operatorLatitude != null &&
        systemDataMessage?.operatorLongitude != null &&
        systemDataMessage?.operatorLongitude != INV_LON &&
        systemDataMessage!.operatorLatitude != INV_LAT &&
        systemDataMessage!.operatorLatitude <= MAX_LAT &&
        systemDataMessage!.operatorLatitude >= MIN_LAT &&
        systemDataMessage!.operatorLongitude <= MAX_LON &&
        systemDataMessage!.operatorLongitude >= MIN_LON;
  }

  bool locationValid() {
    return locationMessage != null &&
        locationMessage?.latitude != null &&
        locationMessage?.longitude != null &&
        locationMessage!.latitude != INV_LAT &&
        locationMessage!.longitude != INV_LON &&
        locationMessage!.latitude! <= MAX_LAT &&
        locationMessage!.longitude! <= MAX_LON &&
        locationMessage!.latitude! >= MIN_LAT &&
        locationMessage!.longitude! >= MIN_LON;
  }
}
