import 'package:pigeon/pigeon.dart';

abstract class OdidMessage {
  final DateTime received;
  final String macAddress;
  final MessageSource source;
  final int? rssi;
}
