import 'package:dart_opendroneid/dart_opendroneid.dart';
import 'package:flutter_opendroneid/pigeon.dart';

typedef MacAddress = String;

class ReceivedODIDMessage {
  final ODIDMessage odidMessage;
  final DateTime receivedTimestamp;
  final MessageSource source;
  final MacAddress macAddress;
  final int? rssi;

  ReceivedODIDMessage({
    required this.odidMessage,
    required this.receivedTimestamp,
    required this.source,
    required this.macAddress,
    this.rssi,
  });

  @override
  String toString() => 'ReceivedODIDMessage{ '
      'odidMessage type: ${odidMessage.runtimeType}, '
      'macAddress: $macAddress, source: ${source.name}, rssi: $rssi, '
      'receivedTimestamp: $receivedTimestamp }';
}
