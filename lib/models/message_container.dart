import 'package:dart_opendroneid/dart_opendroneid.dart';
import 'package:flutter_opendroneid/extensions/compare_extension.dart';
import 'package:flutter_opendroneid/models/constants.dart';
import 'package:flutter_opendroneid/pigeon.dart' as pigeon;
import 'package:flutter_opendroneid/utils/conversions.dart';

/// The [MessageContainer] groups together messages of different types
/// from one device. It contains one instance of each message. The container is
/// then sent using stream to client of the library.
class MessageContainer {
  final pigeon.ODIDMetadata metadata;
  final DateTime lastUpdate;

  final Map<IDType, BasicIDMessage>? basicIdMessages;
  final LocationMessage? locationMessage;
  final OperatorIDMessage? operatorIdMessage;
  final SelfIDMessage? selfIdMessage;
  final AuthMessage? authenticationMessage;
  final SystemMessage? systemDataMessage;

  MessageContainer({
    required this.metadata,
    required this.lastUpdate,
    this.basicIdMessages,
    this.locationMessage,
    this.operatorIdMessage,
    this.selfIdMessage,
    this.authenticationMessage,
    this.systemDataMessage,
  });

  @override
  String toString() {
    final singleMessages = <dynamic>[
      locationMessage,
      operatorIdMessage,
      selfIdMessage,
      authenticationMessage,
      systemDataMessage
    ];

    final descriptionString = singleMessages
        .where((msg) => msg != null)
        .map((msg) => msg.runtimeType)
        .join(' + ');

    return 'MessageContainer { '
        '$descriptionString, '
        '${basicIdMessages?.length} basic ID messages, '
        'last update: $lastUpdate, '
        'metadata: $metadata }';
  }

  MessageContainer copyWith({
    DateTime? lastUpdate,
    pigeon.ODIDMetadata? metadata,
    Map<IDType, BasicIDMessage>? basicIdMessage,
    LocationMessage? locationMessage,
    OperatorIDMessage? operatorIdMessage,
    SelfIDMessage? selfIdMessage,
    AuthMessage? authenticationMessage,
    SystemMessage? systemDataMessage,
  }) =>
      MessageContainer(
        metadata: metadata ?? this.metadata,
        lastUpdate: lastUpdate ?? DateTime.now(),
        basicIdMessages: basicIdMessage ?? this.basicIdMessages,
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
    required pigeon.ODIDMetadata metadata,
    required int receivedTimestamp,
  }) {
    if (message.runtimeType == MessagePack) {
      final messages = (message as MessagePack).messages;
      var result = this;
      for (var packMessage in messages) {
        final update = result.update(
          message: packMessage,
          metadata: metadata,
          receivedTimestamp: receivedTimestamp,
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
              metadata: metadata,
              lastUpdate:
                  DateTime.fromMillisecondsSinceEpoch(receivedTimestamp),
            ),
      BasicIDMessage => _updateBasicIDMessages(
          message: message as BasicIDMessage,
          receivedTimestamp: receivedTimestamp,
          metadata: metadata,
        ),
      SelfIDMessage => selfIdMessage != null &&
              selfIdMessage!.containsEqualData(message as SelfIDMessage)
          ? null
          : copyWith(
              selfIdMessage: message as SelfIDMessage,
              lastUpdate:
                  DateTime.fromMillisecondsSinceEpoch(receivedTimestamp),
              metadata: metadata,
            ),
      OperatorIDMessage => operatorIdMessage != null &&
              operatorIdMessage!.containsEqualData(message as OperatorIDMessage)
          ? null
          : copyWith(
              operatorIdMessage: message as OperatorIDMessage,
              lastUpdate:
                  DateTime.fromMillisecondsSinceEpoch(receivedTimestamp),
              metadata: metadata,
            ),
      AuthMessage => authenticationMessage != null &&
              authenticationMessage!.containsEqualData(message as AuthMessage)
          ? null
          : copyWith(
              authenticationMessage: message as AuthMessage,
              lastUpdate:
                  DateTime.fromMillisecondsSinceEpoch(receivedTimestamp),
              metadata: metadata,
            ),
      SystemMessage => systemDataMessage != null &&
              systemDataMessage!.containsEqualData(message as SystemMessage)
          ? null
          : copyWith(
              systemDataMessage: message as SystemMessage,
              metadata: metadata,
              lastUpdate:
                  DateTime.fromMillisecondsSinceEpoch(receivedTimestamp),
            ),
      _ => null
    };
  }

  String get macAddress => metadata.macAddress;

  pigeon.MessageSource get packSource => metadata.source;

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

  /// Check if container contains basic id message with given uas id
  bool containsUasId(String uasId) =>
      basicIdMessages?.values
          .any((element) => element.uasID.asString() == uasId) ??
      false;

  // preferably return message with SerialNumber uas id, which is the default
  BasicIDMessage? get preferredBasicIdMessage {
    if (basicIdMessages == null || basicIdMessages!.isEmpty) return null;

    return basicIdMessages![IDType.serialNumber] ??
        basicIdMessages!.values.first;
  }

  String? get serialNumberUasId =>
      basicIdMessages?[IDType.serialNumber]?.uasID.asString();

  MessageContainer? _updateBasicIDMessages({
    required BasicIDMessage message,
    required pigeon.ODIDMetadata metadata,
    required int receivedTimestamp,
  }) {
    if (basicIdMessages != null &&
        basicIdMessages![message.uasID.type] != null &&
        basicIdMessages![message.uasID.type]!.containsEqualData(message))
      return null;

    final newEntry = {message.uasID.type: message};
    return copyWith(
      basicIdMessage: basicIdMessages == null ? newEntry : basicIdMessages!
        ..addAll(newEntry),
      metadata: metadata,
      lastUpdate: DateTime.fromMillisecondsSinceEpoch(receivedTimestamp),
    );
  }
}
