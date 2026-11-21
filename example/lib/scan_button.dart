import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_opendroneid/flutter_opendroneid.dart';
import 'package:flutter_opendroneid/models/dri_source_type.dart';
import 'package:flutter_opendroneid/models/permissions_missing_exception.dart';

class ScanButton extends StatefulWidget {
  final DriSourceType sourceType;

  const ScanButton({super.key, required this.sourceType});

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

  Future<void> _checkIsScanning() async {
    final isScanning = widget.sourceType == DriSourceType.Bluetooth
        ? await FlutterOpenDroneId.isScanningBluetooth
        : await FlutterOpenDroneId.isScanningWifi;

    if (!mounted) return;
    setState(() {
      _isScanning = isScanning;
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Semantics(identifier: 'scan-error', child: Text(message)),
      ),
    );
  }

  Future<void> _toggleScan() async {
    try {
      if (_isScanning) {
        await FlutterOpenDroneId.stopScan(widget.sourceType);
      } else {
        await FlutterOpenDroneId.startScan(widget.sourceType);
      }
    } on PlatformException catch (error) {
      _showError(error.message ?? error.code);
    } on PermissionsMissingException catch (error) {
      _showError('Missing permissions: ${error.missingPermissions.join(', ')}');
    }
    if (!mounted) return;
    await _checkIsScanning();
  }

  @override
  Widget build(BuildContext context) {
    final source = widget.sourceType == DriSourceType.Bluetooth
        ? 'bluetooth'
        : 'wifi';
    final identifier = 'scan-$source-${_isScanning ? 'stop' : 'start'}';

    return Semantics(
      key: ValueKey(identifier),
      identifier: identifier,
      button: true,
      child: ElevatedButton(
        onPressed: _toggleScan,
        child: Text('${_isScanning ? 'Stop' : 'Start'} $_sourceName Scan'),
      ),
    );
  }

  String get _sourceName => switch (widget.sourceType) {
    DriSourceType.Bluetooth => 'Bluetooth',
    DriSourceType.Wifi => 'Wi-Fi',
  };
}
