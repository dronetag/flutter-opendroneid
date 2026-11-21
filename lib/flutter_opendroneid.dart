import 'dart:async';
import 'dart:io';

import 'package:dart_opendroneid/dart_opendroneid.dart';
import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;
import 'package:flutter/widgets.dart' show WidgetsFlutterBinding;
import 'package:flutter_opendroneid/exceptions/odid_message_parsing_exception.dart';
import 'package:flutter_opendroneid/models/dri_source_type.dart';
import 'package:flutter_opendroneid/models/permissions_missing_exception.dart';
import 'package:flutter_opendroneid/models/received_odid_message.dart';
import 'package:flutter_opendroneid/src/odid_payload_queue.dart';
import 'package:flutter_opendroneid/src/pigeon/messages.g.dart' as pigeon;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

export 'package:dart_opendroneid/src/types.dart';

export 'src/pigeon/messages.g.dart'
    show
        BluetoothPhy,
        BluetoothState,
        MessageSource,
        ODIDMetadata,
        ODIDPayload,
        ScanPriority,
        WifiState;

/// Reads Wi-Fi and Bluetooth Remote ID advertisements from the native
/// Android and iOS scanners.
///
/// Call [initialize] once from the root isolate before using any other member.
/// Control calls go through Pigeon native interop (JNI on Android, FFI on
/// iOS); payloads and scan state arrive through a direct native callback and
/// are exposed as broadcast streams.
///
/// Parsing happens in a microtask after the native callback returns, so the
/// platform thread is never blocked. Parse failures are reported through
/// [Zone.current.handleUncaughtError] in the isolate's root zone.
class FlutterOpenDroneId {
  static pigeon.OdidScannerHostApi? _apiOverride;

  static pigeon.OdidScannerHostApi get _api =>
      _apiOverride ??= pigeon.OdidScannerHostApi.createWithNativeInteropApi();

  /// Replaces the native host API in tests.
  @visibleForTesting
  static set debugApi(pigeon.OdidScannerHostApi api) => _apiOverride = api;

  static final _bluetoothScanActiveController =
      StreamController<bool>.broadcast();
  static final _wifiScanActiveController = StreamController<bool>.broadcast();

  static final _receivedMessagesController =
      StreamController<ReceivedODIDMessage>.broadcast();

  static final _rawMessagesController =
      StreamController<pigeon.ODIDPayload>.broadcast();

  static final OdidPayloadQueue<pigeon.ODIDPayload>
  _payloadQueue = OdidPayloadQueue<pigeon.ODIDPayload>(
    onPayload: _handlePayload,
    onError: (Object error, StackTrace stack) =>
        Zone.current.handleUncaughtError(error, stack),
    onOverflow: () => debugPrint(
      'flutter_opendroneid: payload queue overflow; dropping oldest payloads',
    ),
  );

  static bool _flutterApiRegistered = false;

  /// Number of payloads dropped because the bounded queue was full.
  static int get droppedPayloadCount => _payloadQueue.droppedPayloadCount;

  /// Drives the generated Flutter API callbacks from tests without native code.
  @visibleForTesting
  static pigeon.OdidScannerFlutterApi get debugFlutterApi => _FlutterApiImpl();

  /// Parsed Remote ID messages from every active scan.
  ///
  /// A malformed advertisement is reported as an uncaught
  /// [ODIDMessageParsingException] and does not stop later messages.
  static Stream<ReceivedODIDMessage> get receivedMessages =>
      _receivedMessagesController.stream;

  /// Raw payload bytes plus radio metadata, before ODID parsing.
  ///
  /// Use this when you want to parse advertisements yourself. Events are
  /// delivered in the same order as [receivedMessages].
  static Stream<pigeon.ODIDPayload> get rawMessages =>
      _rawMessagesController.stream;

  /// Emits whether a Bluetooth scan is currently active.
  static Stream<bool> get bluetoothState =>
      _bluetoothScanActiveController.stream;

  /// Emits whether a Wi-Fi scan is currently active.
  static Stream<bool> get wifiState => _wifiScanActiveController.stream;

  /// Whether the Bluetooth adapter is powered on.
  ///
  /// On iOS this may wait for CoreBluetooth to report its initial state.
  static Future<bool> get btTurnedOn async =>
      await _api.bluetoothState() ==
      pigeon.BluetoothState.values.indexOf(pigeon.BluetoothState.PoweredOn);

  /// Whether the Wi-Fi adapter is enabled.
  static Future<bool> get wifiTurnedOn async =>
      await _api.wifiState() ==
      pigeon.WifiState.values.indexOf(pigeon.WifiState.Enabled);

  /// Initialize the plugin before using.
  ///
  /// Must be called from the root isolate. Registration is repeated on every
  /// isolate start (including hot restart) because this method runs again.
  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    _registerFlutterApi();
    await _api.initialize();
  }

  /// Whether [initialize] has completed and the native scanners exist.
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

  /// Stops the scan for [sourceType] if it is running.
  ///
  /// The corresponding [bluetoothState] / [wifiState] stream emits `false`
  /// once the native scanner stops.
  static Future<void> stopScan(DriSourceType sourceType) async {
    if (sourceType == DriSourceType.Bluetooth &&
        (await _api.isScanningBluetooth())) {
      await _api.stopScanBluetooth();
    }
    if (sourceType == DriSourceType.Wifi && await _api.isScanningWifi()) {
      await _api.stopScanWifi();
    }
  }

  /// Changes the Bluetooth scan priority.
  ///
  /// A high priority drains the battery faster but receives more data. If a
  /// scan is running, the native scanner restarts it with the new priority.
  static Future<void> setBtScanPriority(pigeon.ScanPriority priority) async {
    await _api.setBtScanPriority(priority);
  }

  /// Overrides the 16-bit service UUID used to recognize ODID Bluetooth
  /// advertisements (four hexadecimal characters, e.g. `fffa`).
  static Future<void> setBtServiceUuid(String? serviceUuid) async {
    await _api.setBtServiceUuid(serviceUuid);
  }

  /// Whether the native Bluetooth scanner is currently running.
  static Future<bool> get isScanningBluetooth async {
    return _api.isScanningBluetooth();
  }

  /// Whether Bluetooth LE extended advertising is supported (Android).
  static Future<bool> get isBluetoothExtendedSupported async =>
      await _api.btExtendedSupported();

  /// Whether Wi-Fi Aware (NAN) is supported (Android).
  static Future<bool> get isWifiNanSupported async =>
      await _api.wifiNaNSupported();

  /// Maximum Bluetooth advertising payload length supported by the adapter.
  static Future<int> get btMaxAdvDataLen async => await _api.btMaxAdvDataLen();

  /// Whether the native Wi-Fi scanner is currently running.
  static Future<bool> get isScanningWifi async => await _api.isScanningWifi();

  /// Registers the Dart callback that native scanners call. Idempotent for the
  /// lifetime of an isolate; a hot restart installs a fresh registration.
  static void _registerFlutterApi() {
    if (_flutterApiRegistered) {
      return;
    }
    pigeon.OdidScannerFlutterApi.setUp(_FlutterApiImpl());
    _flutterApiRegistered = true;
  }

  /// Parses one payload and forwards it to both streams. Runs on the Dart event
  /// loop, never inside the native callback.
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

/// Direct native-to-Dart callback implementation.
///
/// Every method does constant work: payloads are queued for a microtask drain
/// and scan-state updates are forwarded to the corresponding broadcast stream.
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
