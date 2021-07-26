import 'dart:ui';

import 'package:flutter_opendroneid/models/basicid_message.dart';
import 'package:flutter_opendroneid/models/location_message.dart';
import 'package:flutter_opendroneid/models/operatorid_message.dart';

import 'odid_message.dart';

class MessagePack {
  // FIXME: Rename to avoid clash with ODID MessagePack
  final String macAddress;
  final int? lastMessageRssi;
  final BasicIdMessage? basicIdMessage;
  final LocationMessage? locationMessage;
  final OperatorIdMessage? operatorIdMessage;

  MessagePack({
    required this.macAddress,
    this.lastMessageRssi,
    this.basicIdMessage,
    this.locationMessage,
    this.operatorIdMessage,
  });

  static const colorMax = 120;
  static const colorOffset = 90;

  MessagePack copyWith({
    String? macAddress,
    int? lastMessageRssi,
    BasicIdMessage? basicIdMessage,
    LocationMessage? locationMessage,
    OperatorIdMessage? operatorIdMessage,
  }) =>
      MessagePack(
        macAddress: macAddress ?? this.macAddress,
        lastMessageRssi: lastMessageRssi ?? this.lastMessageRssi,
        basicIdMessage: basicIdMessage ?? this.basicIdMessage,
        locationMessage: locationMessage ?? this.locationMessage,
        operatorIdMessage: operatorIdMessage ?? this.operatorIdMessage,
      );

  MessagePack updateWith(OdidMessage message) {
    if (message is BasicIdMessage) {
      return copyWith(basicIdMessage: message, lastMessageRssi: message.rssi);
    }
    if (message is LocationMessage) {
      return copyWith(locationMessage: message, lastMessageRssi: message.rssi);
    }
    if (message is OperatorIdMessage) {
      return copyWith(
          operatorIdMessage: message, lastMessageRssi: message.rssi);
    }
    throw Exception('Unknown type of ODID message to have pack updated with');
  }

  /// Calculates a color from mac address, that uniquely identifies the device
  Color getPackColor() {
    final len = macAddress.length;
    return Color.fromARGB(
      255,
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
