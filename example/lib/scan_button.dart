import 'package:flutter/material.dart';
import 'package:flutter_opendroneid/flutter_opendroneid.dart';
import 'package:flutter_opendroneid/models/dri_source_type.dart';

class ScanButton extends StatefulWidget {
  final DriSourceType sourceType;

  const ScanButton({
    super.key,
    required this.sourceType,
  });

  @override
  State<ScanButton> createState() => _ScanButtonState();
}

class _ScanButtonState extends State<ScanButton> {
  bool _isScanning = false;

  @override
  void initState() {
    _checkIsScanning();
    super.initState();
  }

  void _checkIsScanning() async {
    final isScanning = widget.sourceType == DriSourceType.Bluetooth
        ? await FlutterOpenDroneId.isScanningBluetooth
        : await FlutterOpenDroneId.isScanningWifi;

    if (!mounted) return;
    setState(() {
      _isScanning = isScanning;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        if (_isScanning)
          await FlutterOpenDroneId.stopScan(widget.sourceType);
        else
          await FlutterOpenDroneId.startScan(widget.sourceType);
        if (!mounted) return;
        _checkIsScanning();
      },
      child: Text('${_isScanning ? 'Stop' : 'Start'}  $_sourceName Scan'),
    );
  }

  String get _sourceName => switch (widget.sourceType) {
        DriSourceType.Bluetooth => 'Bluetooth',
        DriSourceType.Wifi => 'Wi-Fi',
      };
}
