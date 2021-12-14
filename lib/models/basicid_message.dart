import 'enums.dart';
import 'odid_message.dart';

class BasicIdMessage extends OdidMessage {
  /// The primary identifier of UAS
  ///
  /// (Dronetag devices use their serial number as their UAS ID)
  final String uasId;

  /// Identification type
  final IdType idType;

  /// Type of the aircraft
  final UaType uaType;

  /// Creates a new "BASIC" OpenDroneID message
  const BasicIdMessage({
    required DateTime received,
    required String macAddress,
    required MessageSource source,
    int? rssi,
    required this.uasId,
    required this.idType,
    required this.uaType,
  }) : super(
          received: received,
          macAddress: macAddress,
          source: source,
          rssi: rssi,
        );

  @override
  MessageType get type => MessageType.BasicId;

  @override
  String toString() =>
      'BasicIdMessage { macAddress: $macAddress, uasId: $uasId, idType: '
      '$idType, uaType: $uaType }';

  factory BasicIdMessage.fromMap(Map<Object?, Object?> map) => BasicIdMessage(
        received: DateTime.now(),
        macAddress: map['macAddress'].toString(),
        source: MessageSource.values[map['source'] as int],
        rssi: map['rssi'] as int?,
        uasId: map['uasId']
            .toString()
            .replaceAll(RegExp(r'[^A-Za-z0-9]'), ''), // FIXME
        idType: IdType.values[map['idType'] as int],
        uaType: UaType.values[map['uaType'] as int],
      );
}
