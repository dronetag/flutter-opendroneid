import 'dart:ui';

import 'package:flutter_opendroneid/models/constants.dart';
import 'package:flutter_opendroneid/pigeon.dart' as pigeon;
import 'package:dart_opendroneid/src/types.dart';

class MessageContainer {
  final String macAddress;
  final DateTime lastUpdate;
  final pigeon.MessageSource source;
  final int? lastMessageRssi;

  final BasicIDMessage? basicIdMessage;
  final LocationMessage? locationMessage;
  final OperatorIDMessage? operatorIdMessage;
  final SelfIDMessage? selfIdMessage;
  final AuthMessage? authenticationMessage;
  final SystemMessage? systemDataMessage;

  MessageContainer({
    required this.macAddress,
    required this.lastUpdate,
    required this.source,
    this.lastMessageRssi,
    this.basicIdMessage,
    this.locationMessage,
    this.operatorIdMessage,
    this.selfIdMessage,
    this.authenticationMessage,
    this.systemDataMessage,
  });

  static const colorMax = 120;
  static const colorOffset = 90;

  MessageContainer copyWith({
    String? macAddress,
    int? lastMessageRssi,
    DateTime? lastUpdate,
    pigeon.MessageSource? source,
    BasicIDMessage? basicIdMessage,
    LocationMessage? locationMessage,
    OperatorIDMessage? operatorIdMessage,
    SelfIDMessage? selfIdMessage,
    AuthMessage? authenticationMessage,
    SystemMessage? systemDataMessage,
  }) =>
      MessageContainer(
        macAddress: macAddress ?? this.macAddress,
        lastMessageRssi: lastMessageRssi ?? this.lastMessageRssi,
        lastUpdate: lastUpdate ?? DateTime.now(),
        source: source ?? this.source,
        basicIdMessage: basicIdMessage ?? this.basicIdMessage,
        locationMessage: locationMessage ?? this.locationMessage,
        operatorIdMessage: operatorIdMessage ?? this.operatorIdMessage,
        selfIdMessage: selfIdMessage ?? this.selfIdMessage,
        authenticationMessage:
            authenticationMessage ?? this.authenticationMessage,
        systemDataMessage: systemDataMessage ?? this.systemDataMessage,
      );

  MessageContainer update({
    required ODIDMessage message,
    required int receivedTimestamp,
    required pigeon.MessageSource source,
    int? rssi,
  }) {
    if (message.runtimeType == MessagePack) {
      final messages = (message as MessagePack).messages;
      var result = this;
      for (var packMessage in messages) {
        result = result.update(
          message: packMessage,
          receivedTimestamp: receivedTimestamp,
          source: source,
        );
      }
      return result;
    }
    return switch (message.runtimeType) {
      LocationMessage => copyWith(
          locationMessage: message as LocationMessage,
          lastMessageRssi: rssi,
          lastUpdate: DateTime.fromMillisecondsSinceEpoch(receivedTimestamp),
          source: source,
        ),
      BasicIDMessage => copyWith(
          basicIdMessage: message as BasicIDMessage,
          lastMessageRssi: rssi,
          lastUpdate: DateTime.fromMillisecondsSinceEpoch(receivedTimestamp),
          source: source,
        ),
      SelfIDMessage => copyWith(
          selfIdMessage: message as SelfIDMessage,
          lastMessageRssi: rssi,
          lastUpdate: DateTime.fromMillisecondsSinceEpoch(receivedTimestamp),
          source: source,
        ),
      OperatorIDMessage => copyWith(
          operatorIdMessage: message as OperatorIDMessage,
          lastMessageRssi: rssi,
          lastUpdate: DateTime.fromMillisecondsSinceEpoch(receivedTimestamp),
          source: source,
        ),
      AuthMessage => copyWith(
          authenticationMessage: message as AuthMessage,
          lastMessageRssi: rssi,
          lastUpdate: DateTime.fromMillisecondsSinceEpoch(receivedTimestamp),
          source: source,
        ),
      SystemMessage => copyWith(
          systemDataMessage: message as SystemMessage,
          lastMessageRssi: rssi,
          lastUpdate: DateTime.fromMillisecondsSinceEpoch(receivedTimestamp),
          source: source,
        ),
      _ => this
    };
  }

  MessageContainer updateWithOperatorId({
    required OperatorIDMessage message,
    required int receivedTimestamp,
    int? rssi,
  }) {
    return copyWith(
        operatorIdMessage: message,
        lastMessageRssi: rssi,
        lastUpdate: DateTime.fromMillisecondsSinceEpoch(receivedTimestamp));
  }

  MessageContainer updateWithAuthentication({
    required AuthMessage message,
    required int receivedTimestamp,
    int? rssi,
  }) {
    return copyWith(
        authenticationMessage: message,
        lastMessageRssi: rssi,
        lastUpdate: DateTime.fromMillisecondsSinceEpoch(receivedTimestamp));
  }

  MessageContainer updateWithSystemData({
    required SystemMessage message,
    required int receivedTimestamp,
    int? rssi,
  }) {
    return copyWith(
        systemDataMessage: message,
        lastMessageRssi: rssi,
        lastUpdate: DateTime.fromMillisecondsSinceEpoch(receivedTimestamp));
  }

  MessageContainer updateWithSelfId({
    required SelfIDMessage message,
    required int receivedTimestamp,
    int? rssi,
  }) {
    return copyWith(
        selfIdMessage: message,
        lastMessageRssi: rssi,
        lastUpdate: DateTime.fromMillisecondsSinceEpoch(receivedTimestamp));
  }

  pigeon.MessageSource getPackSource() => source;

  /// Calculates a color from mac address, that uniquely identifies the device
  Color getPackColor() {
    final len = macAddress.length;
    return Color.fromARGB(
      locationMessage?.status != OperationalStatus.airborne ? 80 : 255,
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
    return operatorIdMessage != null &&
        operatorIdMessage!.operatorID != OPERATOR_ID_NOT_SET;
  }

  bool operatorIDValid() {
    final validCharacters = RegExp(r'^[a-zA-Z0-9]+$');
    return operatorIdMessage != null &&
        operatorIdMessage!.operatorID.length == 16 &&
        validCharacters.hasMatch(operatorIdMessage!.operatorID);
  }

  bool systemDataValid() {
    return systemDataMessage != null &&
        systemDataMessage?.operatorLocation != null &&
        systemDataMessage!.operatorLocation!.latitude != INV_LAT &&
        systemDataMessage?.operatorLocation!.longitude != INV_LON &&
        systemDataMessage!.operatorLocation!.latitude <= MAX_LAT &&
        systemDataMessage!.operatorLocation!.latitude >= MIN_LAT &&
        systemDataMessage!.operatorLocation!.longitude <= MAX_LON &&
        systemDataMessage!.operatorLocation!.longitude >= MIN_LON;
  }

  bool locationValid() {
    return locationMessage != null &&
        locationMessage?.location != null &&
        locationMessage!.location!.latitude != INV_LAT &&
        locationMessage!.location!.longitude != INV_LON &&
        locationMessage!.location!.latitude <= MAX_LAT &&
        locationMessage!.location!.longitude <= MAX_LON &&
        locationMessage!.location!.latitude >= MIN_LAT &&
        locationMessage!.location!.longitude >= MIN_LON;
  }
}
