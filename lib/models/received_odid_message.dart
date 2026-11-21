import 'package:dart_opendroneid/dart_opendroneid.dart';
import 'package:flutter_opendroneid/src/pigeon/messages.g.dart';

typedef MacAddress = String;

/// A parsed ODID message together with the radio metadata and receive time.
class ReceivedODIDMessage {
  /// Parsed Remote ID message.
  final ODIDMessage odidMessage;

  /// Radio-level metadata (source, MAC/identifier, RSSI, channel, PHY).
  final ODIDMetadata metadata;

  /// Time the native scanner received the advertisement.
  final DateTime receivedTimestamp;

  ReceivedODIDMessage({
    required this.odidMessage,
    required this.metadata,
    required this.receivedTimestamp,
  });

  /// Returns a copy with the given fields replaced.
  ReceivedODIDMessage copyWith({
    ODIDMessage? odidMessage,
    ODIDMetadata? metadata,
    DateTime? receivedTimestamp,
  }) => ReceivedODIDMessage(
    odidMessage: odidMessage ?? this.odidMessage,
    metadata: metadata ?? this.metadata,
    receivedTimestamp: receivedTimestamp ?? this.receivedTimestamp,
  );

  @override
  String toString() =>
      'ReceivedODIDMessage{ '
      'odidMessage type: ${odidMessage.runtimeType}, '
      'macAddress: ${metadata.macAddress}, source: ${metadata.source.name}, '
      'rssi: ${metadata.rssi}, receivedTimestamp: $receivedTimestamp }';
}
