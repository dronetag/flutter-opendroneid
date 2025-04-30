import 'package:flutter/material.dart';
import 'package:flutter_opendroneid/flutter_opendroneid.dart';
import 'package:flutter_opendroneid/models/message_container.dart';

class MessageContainerView extends StatelessWidget {
  final MessageContainer messageContainer;

  const MessageContainerView({
    super.key,
    required this.messageContainer,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      children: [
        ...?messageContainer.basicIdMessages?.values.map(_buildMessage),
        _buildMessage(messageContainer.locationMessage),
        _buildMessage(messageContainer.operatorIdMessage),
        _buildMessage(messageContainer.selfIdMessage),
        _buildMessage(messageContainer.authenticationMessage),
      ],
    );
  }

  Widget _buildMessage(ODIDMessage? message) {
    if (message != null) return Text('${message.toString()}\n');

    return SizedBox.shrink();
  }
}
