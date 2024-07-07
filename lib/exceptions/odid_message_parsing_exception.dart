import 'package:flutter_opendroneid/pigeon.dart';

class ODIDMessageParsingException implements Exception {
  final Object relatedException;
  final String macAddress;
  final String? btName;
  final MessageSource source;
  final int? rssi;
  final int receivedTimestamp;

  ODIDMessageParsingException({
    required this.relatedException,
    required this.macAddress,
    required this.btName,
    required this.source,
    required this.receivedTimestamp,
    this.rssi,
  });

  @override
  String toString() =>
      'ODIDMessageParsingException{ exception: $relatedException, '
      'mac: $macAddress, btName: $btName, source: $source, '
      'rssi: $rssi, receivedTimestamp: $receivedTimestamp }';
}
