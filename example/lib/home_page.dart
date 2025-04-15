import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_opendroneid/flutter_opendroneid.dart';
import 'package:flutter_opendroneid/models/dri_source_type.dart';

import 'request_permission_button.dart';
import 'scan_button.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _btMessagesCounter = 0;
  int _wifiMessagesCounter = 0;

  StreamSubscription? btSubscription;
  StreamSubscription? wifiSubscription;

  @override
  void initState() {
    btSubscription =
        FlutterOpenDroneId.bluetoothMessages.listen((_) => setState(() {
              ++_btMessagesCounter;
            }));
    wifiSubscription =
        FlutterOpenDroneId.wifiMessages.listen((_) => setState(() {
              ++_wifiMessagesCounter;
            }));
    super.initState();
  }

  @override
  void dispose() {
    btSubscription?.cancel();
    wifiSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const padding = 8.0;
    final isAndroid = Platform.isAndroid;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(padding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            DefaultTextStyle(
              style: Theme.of(context).textTheme.titleMedium!,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Received Bluetooth Messages:'),
                      Text(
                        '$_btMessagesCounter',
                      ),
                    ],
                  ),
                  if (isAndroid)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Received Wi-Fi Messages:'),
                        Text(
                          '$_wifiMessagesCounter',
                        ),
                      ],
                    ),
                ],
              ),
            ),
            Column(
              spacing: padding,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RequestPermissionButton(
                  permissions: isAndroid
                      ? [
                          Permission.bluetooth,
                          Permission.bluetoothConnect,
                          Permission.bluetoothScan
                        ]
                      : [Permission.bluetooth],
                  name: 'Bluetooth Permission',
                ),
                if (isAndroid)
                  RequestPermissionButton(
                    permissions: [Permission.nearbyWifiDevices],
                    name: 'Wi-Fi Permission',
                  ),
                if (isAndroid)
                  RequestPermissionButton(
                    permissions: [Permission.location],
                    name: 'Location Permission',
                  ),
                ScanButton(
                  sourceType: DriSourceType.Bluetooth,
                ),
                if (isAndroid)
                  ScanButton(
                    sourceType: DriSourceType.Wifi,
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
