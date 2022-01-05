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
    _updateScanningState();
    super.initState();
  }

  Future<void> initPlatformState() async {
    if (Platform.isAndroid) {
      Permission.location.request();
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
    _updateScanningState();
  }

  void stop() {
    listener?.cancel();
    FlutterOpenDroneId.stopScan();
    _updateScanningState();
  }

  void clear() {
    setState(() {
      packHistory = {};
    });
  }

  void _updateScanningState() async {
    final value = await FlutterOpenDroneId.isScanning;
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
