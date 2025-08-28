import 'package:flutter/material.dart';
import 'package:flutter_opendroneid/flutter_opendroneid.dart';
import 'package:flutter_opendroneid/models/received_odid_message.dart';

class ReceivedODIDMessageView extends StatelessWidget {
  final ReceivedODIDMessage message;

  const ReceivedODIDMessageView({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      children: [
        _buildMessage(message.odidMessage),
      ],
    );
  }

  Widget _buildMessage(ODIDMessage? message) {
    if (message != null) return Text('${message.toString()}\n');

    return SizedBox.shrink();
  }
}
