import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_opendroneid/flutter_opendroneid.dart';
import 'package:flutter_opendroneid/models/message_pack.dart';
import 'package:permission_handler/permission_handler.dart';

import 'screens/home.dart';

class FlutterOpenDroneIdApp extends StatefulWidget {
  @override
  _FlutterOpenDroneIdAppState createState() => _FlutterOpenDroneIdAppState();
}

class _FlutterOpenDroneIdAppState extends State<FlutterOpenDroneIdApp> {
  StreamSubscription? listener;
  Map<String, List<MessagePack>> packHistory = {};

  @override
  void initState() {
    initPlatformState();
    _updateScanningStateBluetooth();
    _updateScanningStateWifi();
    super.initState();
  }

  Future<void> initPlatformState() async {
    if (Platform.isAndroid || Platform.isIOS) {
      await Permission.location.request();
      var status = await Permission.location.status;
      if (status.isDenied) {
        print('loc denied');
      } else
        print('loc enabled');
      await Permission.bluetooth.request();
      status = await Permission.bluetooth.status;
      if (status.isDenied) {
        print('bt denied');
      } else
        print('bt enabled');
    }
  }

  @override
  void dispose() {
    stop();
    listener?.cancel();
    super.dispose();
  }

  void start() {
    listener = FlutterOpenDroneId.allMessages.listen((pack) {
      setState(() {
        if (!packHistory.containsKey(pack.macAddress)) {
          packHistory[pack.macAddress] = [pack];
        } else {
          packHistory[pack.macAddress]?.add(pack);
        }
      });
    });
    FlutterOpenDroneId.startScan();
    _updateScanningStateBluetooth();
    _updateScanningStateWifi();
  }

  void stop() {
    listener?.cancel();
    FlutterOpenDroneId.stopScan();
    _updateScanningStateBluetooth();
    _updateScanningStateWifi();
  }

  void clear() {
    setState(() {
      packHistory = {};
    });
  }

  void _updateScanningStateBluetooth() async {
    final value = await FlutterOpenDroneId.isScanningBluetooth;
  }

  void _updateScanningStateWifi() async {
    final value = await FlutterOpenDroneId.isScanningWifi;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.from(
          colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.indigo,
        backgroundColor: Colors.white,
      )),
      darkTheme: ThemeData.from(
          colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.indigo,
        backgroundColor: Colors.black,
        brightness: Brightness.dark,
      )),
      home: HomeScreen(
        receivedPacks: packHistory,
        startScan: start,
        stopScan: stop,
        clearData: clear,
      ),
    );
  }
}
