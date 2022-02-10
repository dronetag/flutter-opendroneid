import 'dart:ui';

import 'package:flutter_opendroneid/models/basicid_message.dart';
import 'package:flutter_opendroneid/models/enums.dart';
import 'package:flutter_opendroneid/models/location_message.dart';
import 'package:flutter_opendroneid/models/operatorid_message.dart';

import 'odid_message.dart';

import 'package:flutter_opendroneid/pigeon.dart' as pigeon;

class MessagePack {
  // FIXME: Rename to avoid clash with ODID MessagePack
  final String macAddress;
  final int? lastMessageRssi;
  final DateTime? lastUpdate;
  final pigeon.BasicIdMessage? basicIdMessage;
  final pigeon.LocationMessage? locationMessage;
  final pigeon.OperatorIdMessage? operatorIdMessage;

  MessagePack({
    required this.macAddress,
    this.lastMessageRssi,
    this.lastUpdate,
    this.basicIdMessage,
    this.locationMessage,
    this.operatorIdMessage,
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
  }) =>
      MessagePack(
        macAddress: macAddress ?? this.macAddress,
        lastMessageRssi: lastMessageRssi ?? this.lastMessageRssi,
        lastUpdate: lastUpdate ?? DateTime.now(),
        basicIdMessage: basicIdMessage ?? this.basicIdMessage,
        locationMessage: locationMessage ?? this.locationMessage,
        operatorIdMessage: operatorIdMessage ?? this.operatorIdMessage,
      );

  MessagePack updateWithBasic(pigeon.BasicIdMessage message) {
    return copyWith(basicIdMessage: message, lastMessageRssi: message.rssi);
  }

  MessagePack updateWithLocation(pigeon.LocationMessage message) {
    return copyWith(locationMessage: message, lastMessageRssi: message.rssi);
  }

  MessagePack updateWithOperatorId(pigeon.OperatorIdMessage message) {
    return copyWith(operatorIdMessage: message, lastMessageRssi: message.rssi);
  }

  /// Calculates a color from mac address, that uniquely identifies the device
  Color getPackColor() {
    final len = macAddress.length;
    return Color.fromARGB(
      locationMessage?.status != AircraftStatus.Airborne ? 80 : 255,
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
}
