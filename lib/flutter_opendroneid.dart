import 'dart:async';
import 'dart:io';

import 'package:dart_opendroneid/dart_opendroneid.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_opendroneid/exceptions/odid_message_parsing_exception.dart';
import 'package:flutter_opendroneid/models/dri_source_type.dart';
import 'package:flutter_opendroneid/models/permissions_missing_exception.dart';
import 'package:flutter_opendroneid/models/received_odid_message.dart';
import 'package:flutter_opendroneid/src/odid_payload_queue.dart';
import 'package:flutter_opendroneid/src/pigeon/messages.g.dart' as pigeon;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

export 'package:dart_opendroneid/src/types.dart';

class FlutterOpenDroneId {
  static pigeon.OdidScannerHostApi? _apiOverride;

  static pigeon.OdidScannerHostApi get _api =>
      _apiOverride ??= pigeon.OdidScannerHostApi.createWithNativeInteropApi();

  @visibleForTesting
  static set debugApi(pigeon.OdidScannerHostApi api) => _apiOverride = api;

  static final _bluetoothScanActiveController =
      StreamController<bool>.broadcast();
  static final _wifiScanActiveController = StreamController<bool>.broadcast();

  static final _receivedMessagesController =
      StreamController<ReceivedODIDMessage>.broadcast();

  static final _rawMessagesController =
      StreamController<pigeon.ODIDPayload>.broadcast();

  static final OdidPayloadQueue<pigeon.ODIDPayload> _payloadQueue =
      OdidPayloadQueue<pigeon.ODIDPayload>(
        onPayload: _handlePayload,
        onError: (Object error, StackTrace stack) =>
            Zone.current.handleUncaughtError(error, stack),
      );

  static bool _flutterApiRegistered = false;

  static Stream<ReceivedODIDMessage> get receivedMessages =>
      _receivedMessagesController.stream;

  static Stream<pigeon.ODIDPayload> get rawMessages =>
      _rawMessagesController.stream;

  /// Emits whether a Bluetooth scan is currently active.
  static Stream<bool> get bluetoothState =>
      _bluetoothScanActiveController.stream;

  /// Emits whether a Wi-Fi scan is currently active.
  static Stream<bool> get wifiState => _wifiScanActiveController.stream;

  static Future<bool> get btTurnedOn async =>
      await _api.bluetoothState() ==
      pigeon.BluetoothState.values.indexOf(pigeon.BluetoothState.PoweredOn);

  static Future<bool> get wifiTurnedOn async =>
      await _api.wifiState() ==
      pigeon.WifiState.values.indexOf(pigeon.WifiState.Enabled);

  /// Initialize the plugin before using.
  static Future<void> initialize() async {
    _registerFlutterApi();
    await _api.initialize();
  }

  /// Check whether plugin was correctly initialized.
  static Future<bool> isInitialized() async {
    return await _api.isInitialized();
  }

  /// Starts scanning for nearby traffic
  /// For Bluetooth scanning, bluetooth perm. are required on both platforms,
  /// Android requires Bluetooth scan permission location permission on ver.< 12
  ///
  /// For Wi-Fi scanning, location permission is required on Android.
  ///
  /// By specifying [bluetoothServiceUuid] the service UUID of ODID BT
  /// packets will be changed to the desired value. Standard 8-byte value in
  /// hexadecimal format is expected, default is the standardized value - FFFA.
  ///
  /// Throws [PermissionsMissingException] if permissions were not granted.
  ///
  /// To further receive data, listen to [receivedMessages]
  /// stream.
  ///
  /// Plugin must be initialized by calling [initialize] before using.
  static Future<void> startScan(
    DriSourceType sourceType, {
    String? bluetoothServiceUuid = "fffa",
  }) async {
    if (sourceType == DriSourceType.Bluetooth) {
      await _assertBluetoothPermissions();
      await _api.startScanBluetooth(bluetoothServiceUuid);
    } else if (sourceType == DriSourceType.Wifi) {
      await _assertWifiPermissions();
      await _api.startScanWifi();
    }
  }

  /// Stops any currently running scan
  static Future<void> stopScan(DriSourceType sourceType) async {
    if (sourceType == DriSourceType.Bluetooth &&
        (await _api.isScanningBluetooth())) {
      await _api.stopScanBluetooth();
    }
    if (sourceType == DriSourceType.Wifi && await _api.isScanningWifi()) {
      await _api.stopScanWifi();
    }
  }

  static Future<void> setBtScanPriority(pigeon.ScanPriority priority) async {
    await _api.setBtScanPriority(priority);
  }

  static Future<void> setBtServiceUuid(String? serviceUuid) async {
    await _api.setBtServiceUuid(serviceUuid);
  }

  static Future<bool> get isScanningBluetooth async {
    return _api.isScanningBluetooth();
  }

  static Future<bool> get isBluetoothExtendedSupported async =>
      await _api.btExtendedSupported();

  static Future<bool> get isWifiNanSupported async =>
      await _api.wifiNaNSupported();

  static Future<int> get btMaxAdvDataLen async => await _api.btMaxAdvDataLen();

  static Future<bool> get isScanningWifi async => await _api.isScanningWifi();

  static void _registerFlutterApi() {
    if (_flutterApiRegistered) {
      return;
    }
    _flutterApiRegistered = true;
    pigeon.OdidScannerFlutterApi.setUp(_FlutterApiImpl());
  }

  static void _handlePayload(pigeon.ODIDPayload payload) {
    _rawMessagesController.add(payload);

    ODIDMessage? message;
    try {
      message = parseODIDMessage(payload.rawData).message;
    } catch (e) {
      throw ODIDMessageParsingException(
        relatedException: e,
        macAddress: payload.metadata.macAddress,
        rssi: payload.metadata.rssi,
        receivedTimestamp: payload.receivedTimestamp,
        source: payload.metadata.source,
        btName: payload.metadata.btName,
      );
    }

    _receivedMessagesController.add(
      ReceivedODIDMessage(
        odidMessage: message,
        metadata: payload.metadata,
        receivedTimestamp: DateTime.fromMillisecondsSinceEpoch(
          payload.receivedTimestamp,
        ),
      ),
    );
  }

  /// Checks all required Bluetooth permissions and throws
  /// [PermissionsMissingException] if any of them are not granted.
  static Future<void> _assertBluetoothPermissions() async {
    List<Permission> missingPermissions = [];

    // Bluetooth permission is required on all platforms
    if (!await Permission.bluetooth.status.isGranted)
      missingPermissions.add(Permission.bluetooth);

    if (Platform.isAndroid) {
      // Bluetooth Scan permission is required on all Android phones
      if (!await Permission.bluetoothScan.status.isGranted)
        missingPermissions.add(Permission.bluetoothScan);

      // Android also requires location permission to scan BT devices

      if (!await Permission.location.status.isGranted)
        missingPermissions.add(Permission.location);
    }

    if (missingPermissions.isNotEmpty)
      throw PermissionsMissingException(missingPermissions);
  }

  /// Checks all required Wi-Fi permissions and throws
  /// [PermissionsMissingException] if any of them are not granted.
  static Future<void> _assertWifiPermissions() async {
    // Android requires location permission to scan Wi-Fi devices
    if (Platform.isAndroid) {
      List<Permission> missingPermissions = [];

      final androidVersionNumber = await _getAndroidVersionNumber();
      if (androidVersionNumber == null) return;
      // Android < 12 also requires location permission
      // Android 13 has a new nearbyWifiDevicesPermission
      if (androidVersionNumber >= 13) {
        if (!await Permission.nearbyWifiDevices.status.isGranted)
          missingPermissions.add(Permission.nearbyWifiDevices);
      } else {
        if (!await Permission.location.status.isGranted)
          missingPermissions.add(Permission.location);
      }
      if (missingPermissions.isNotEmpty)
        throw PermissionsMissingException(missingPermissions);
    }
  }

  static Future<int?> _getAndroidVersionNumber() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidVersion = (await deviceInfo.androidInfo).version.release;
    return int.tryParse(androidVersion);
  }
}

class _FlutterApiImpl implements pigeon.OdidScannerFlutterApi {
  @override
  void onOdidPayload(pigeon.ODIDPayload payload) =>
      FlutterOpenDroneId._payloadQueue.add(payload);

  @override
  void onBluetoothScanActive(bool isActive) =>
      FlutterOpenDroneId._bluetoothScanActiveController.add(isActive);

  @override
  void onWifiScanActive(bool isActive) =>
      FlutterOpenDroneId._wifiScanActiveController.add(isActive);
}

/// Registered by Flutter as the plugin's `dartPluginClass`, including on hot restart.
class FlutterOpenDroneIdPlugin {
  static void registerWith() => FlutterOpenDroneId._registerFlutterApi();
}
