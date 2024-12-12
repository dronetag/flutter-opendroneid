import 'package:dart_opendroneid/dart_opendroneid.dart';
import 'package:flutter_opendroneid/pigeon.dart';

typedef MacAddress = String;

class ReceivedODIDMessage {
  final ODIDMessage odidMessage;
  final ODIDMetadata metadata;
  final DateTime receivedTimestamp;

  ReceivedODIDMessage(
      {required this.odidMessage,
      required this.metadata,
      required this.receivedTimestamp});

  ReceivedODIDMessage copyWith({
    ODIDMessage? odidMessage,
    ODIDMetadata? metadata,
    DateTime? receivedTimestamp,
  }) =>
      ReceivedODIDMessage(
          odidMessage: odidMessage ?? this.odidMessage,
          metadata: metadata ?? this.metadata,
          receivedTimestamp: receivedTimestamp ?? this.receivedTimestamp);

  @override
  String toString() => 'ReceivedODIDMessage{ '
      'odidMessage type: ${odidMessage.runtimeType}, '
      'macAddress: ${metadata.macAddress}, source: ${metadata.source.name}, '
      'rssi: ${metadata.rssi}, receivedTimestamp: $receivedTimestamp }';
}
