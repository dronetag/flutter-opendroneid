import 'enums.dart';
import 'odid_message.dart';

class OperatorIdMessage extends OdidMessage {
  /// Operator ID
  final String operatorId;

  /// Creates a new "OPERATOR_ID" OpenDroneID message
  const OperatorIdMessage({
    required DateTime received,
    required String macAddress,
    required MessageSource source,
    int? rssi,
    required this.operatorId,
  }) : super(
          received: received,
          macAddress: macAddress,
          source: source,
          rssi: rssi,
        );

  @override
  MessageType get type => MessageType.BasicId;

  @override
  String toString() => 'OperatorIdMessage { $operatorId }';

  factory OperatorIdMessage.fromMap(Map<Object?, Object?> map) =>
      OperatorIdMessage(
        received: DateTime.now(),
        macAddress: map['macAddress'].toString(),
        source: MessageSource.values[map['source'] as int],
        rssi: map['rssi'] as int?,
        operatorId: map['operatorId'].toString(),
      );
}
