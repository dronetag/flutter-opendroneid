import 'package:flutter_opendroneid/models/basicid_message.dart';
import 'package:flutter_opendroneid/models/location_message.dart';
import 'package:flutter_opendroneid/models/operatorid_message.dart';

import 'enums.dart';

abstract class OdidMessage {
  final DateTime received;
  final String macAddress;
  final MessageSource source;
  final int? rssi;

  MessageType get type;

  const OdidMessage({
    required this.received,
    required this.macAddress,
    required this.source,
    this.rssi,
  });

  static OdidMessage? fromMap(Map<Object?, Object?> data) {
    final typeRaw = int.parse(data['type'].toString());
    final type = MessageType.values[typeRaw];

    switch (type) {
      case MessageType.BasicId:
        return BasicIdMessage.fromMap(data);
      case MessageType.Location:
        return LocationMessage.fromMap(data);
      case MessageType.OperatorId:
        return OperatorIdMessage.fromMap(data);
      default:
        return null;
    }
  }
}
