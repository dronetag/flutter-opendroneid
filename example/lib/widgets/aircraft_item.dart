import 'package:flutter/material.dart';
import 'package:flutter_opendroneid/models/message_pack.dart';

class AircraftItem extends StatelessWidget {
  final MessagePack messagePack;

  AircraftItem({required this.messagePack});

  @override
  Widget build(BuildContext context) {
    final loc = messagePack.locationMessage;
    final theme = Theme.of(context);
    final countryCode =
        messagePack.operatorIdMessage?.operatorId.substring(0, 2);
    return ListTile(
      leading: Icon(Icons.flight, color: messagePack.getPackColor()),
      title: Text.rich(
        TextSpan(children: [
          if (messagePack.basicIdMessage?.uasId.startsWith('1596') == true)
            WidgetSpan(
                child: Image.asset(
              'assets/dronetag.png',
              height: 16,
              width: 24,
              alignment: Alignment.topLeft,
              color: theme.brightness == Brightness.light
                  ? Colors.black
                  : Colors.white,
            )),
          TextSpan(text: messagePack.basicIdMessage?.uasId ?? 'Unknown UAS ID'),
        ]),
      ),
      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Operator ID row
        Text.rich(
          TextSpan(children: [
            if (countryCode != null)
              WidgetSpan(
                  child: Image.network(
                'https://www.countryflags.io/$countryCode/flat/24.png',
                height: 16,
                width: 24,
                alignment: Alignment.centerLeft,
              )),
            TextSpan(
                text: messagePack.operatorIdMessage?.operatorId ??
                    'Unknown Operator ID'),
          ]),
        ),
        Text(
            '${loc?.latitude?.toStringAsFixed(6)}, '
            '${loc?.longitude?.toStringAsFixed(6)}, '
            '${loc?.height}m, ~?m, ${messagePack.lastMessageRssi}dBm',
            textScaleFactor: 0.9),
      ]),
    );
  }
}
