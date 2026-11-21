import 'package:flutter_opendroneid/src/pigeon/messages.g.dart';

/// Reported when an advertisement could not be parsed as an ODID message.
///
/// Delivered through [Zone.current.handleUncaughtError] so later payloads keep
/// flowing.
class ODIDMessageParsingException implements Exception {
  /// The exception thrown by the ODID parser.
  final Object relatedException;

  /// Identifier of the sender (MAC address, NAN peer, or peripheral UUID).
  final String macAddress;

  /// Bluetooth device name, when available.
  final String? btName;

  /// Transport that delivered the advertisement.
  final MessageSource source;

  /// Received signal strength in dBm, when available.
  final int? rssi;

  /// Native receive timestamp in milliseconds since the epoch.
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
