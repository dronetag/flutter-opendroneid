import 'package:dart_opendroneid/dart_opendroneid.dart';
import 'package:flutter_opendroneid/extensions/compare_extension.dart';
import 'package:flutter_opendroneid/models/constants.dart';
import 'package:flutter_opendroneid/pigeon.dart' as pigeon;

/// The [MessageContainer] groups together messages of different types
/// from one device. It contains one instance of each message. The container is
/// then sent using stream to client of the library.
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

  /// Returns new MessageContainer updated with message.
  /// Null is returned if update is refused, because it contains duplicate or
  /// corrupted data.
  MessageContainer? update({
    required ODIDMessage message,
    required int receivedTimestamp,
    required pigeon.MessageSource source,
    int? rssi,
  }) {
    if (message.runtimeType == MessagePack) {
      final messages = (message as MessagePack).messages;
      var result = this;
      for (var packMessage in messages) {
        final update = result.update(
          message: packMessage,
          receivedTimestamp: receivedTimestamp,
          source: source,
        );
        if (update != null) result = update;
      }
      return result;
    }
    // update pack only if new data differ from saved ones
    return switch (message.runtimeType) {
      LocationMessage => locationMessage != null &&
              locationMessage!.containsEqualData(message as LocationMessage)
          ? null
          : copyWith(
              locationMessage: message as LocationMessage,
              lastMessageRssi: rssi,
              lastUpdate:
                  DateTime.fromMillisecondsSinceEpoch(receivedTimestamp),
              source: source,
            ),
      BasicIDMessage => basicIdMessage != null &&
              basicIdMessage!.containsEqualData(message as BasicIDMessage)
          ? null
          : copyWith(
              basicIdMessage: message as BasicIDMessage,
              lastMessageRssi: rssi,
              lastUpdate:
                  DateTime.fromMillisecondsSinceEpoch(receivedTimestamp),
              source: source,
            ),
      SelfIDMessage => selfIdMessage != null &&
              selfIdMessage!.containsEqualData(message as SelfIDMessage)
          ? null
          : copyWith(
              selfIdMessage: message as SelfIDMessage,
              lastMessageRssi: rssi,
              lastUpdate:
                  DateTime.fromMillisecondsSinceEpoch(receivedTimestamp),
              source: source,
            ),
      OperatorIDMessage => operatorIdMessage != null &&
              operatorIdMessage!.containsEqualData(message as OperatorIDMessage)
          ? null
          : copyWith(
              operatorIdMessage: message as OperatorIDMessage,
              lastMessageRssi: rssi,
              lastUpdate:
                  DateTime.fromMillisecondsSinceEpoch(receivedTimestamp),
              source: source,
            ),
      AuthMessage => authenticationMessage != null &&
              authenticationMessage!.containsEqualData(message as AuthMessage)
          ? null
          : copyWith(
              authenticationMessage: message as AuthMessage,
              lastMessageRssi: rssi,
              lastUpdate:
                  DateTime.fromMillisecondsSinceEpoch(receivedTimestamp),
              source: source,
            ),
      SystemMessage => systemDataMessage != null &&
              systemDataMessage!.containsEqualData(message as SystemMessage)
          ? null
          : copyWith(
              systemDataMessage: message as SystemMessage,
              lastMessageRssi: rssi,
              lastUpdate:
                  DateTime.fromMillisecondsSinceEpoch(receivedTimestamp),
              source: source,
            ),
      _ => null
    };
  }

  pigeon.MessageSource get packSource => source;

  bool get operatorIDSet =>
      operatorIdMessage != null &&
      operatorIdMessage!.operatorID != OPERATOR_ID_NOT_SET;

  bool get operatorIDValid {
    final validCharacters = RegExp(r'^[a-zA-Z0-9]+$');
    return operatorIdMessage != null &&
        operatorIdMessage!.operatorID.length == 16 &&
        validCharacters.hasMatch(operatorIdMessage!.operatorID);
  }

  bool get systemDataValid =>
      systemDataMessage != null &&
      systemDataMessage?.operatorLocation != null &&
      systemDataMessage!.operatorLocation!.latitude != INV_LAT &&
      systemDataMessage?.operatorLocation!.longitude != INV_LON &&
      systemDataMessage!.operatorLocation!.latitude <= MAX_LAT &&
      systemDataMessage!.operatorLocation!.latitude >= MIN_LAT &&
      systemDataMessage!.operatorLocation!.longitude <= MAX_LON &&
      systemDataMessage!.operatorLocation!.longitude >= MIN_LON;

  bool get locationValid =>
      locationMessage != null &&
      locationMessage?.location != null &&
      locationMessage!.location!.latitude != INV_LAT &&
      locationMessage!.location!.longitude != INV_LON &&
      locationMessage!.location!.latitude <= MAX_LAT &&
      locationMessage!.location!.longitude <= MAX_LON &&
      locationMessage!.location!.latitude >= MIN_LAT &&
      locationMessage!.location!.longitude >= MIN_LON;
}
