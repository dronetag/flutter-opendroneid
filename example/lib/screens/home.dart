import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_opendroneid/flutter_opendroneid.dart';
import 'package:flutter_opendroneid/models/message_pack.dart';
import 'package:flutter_opendroneid_example/widgets/aircraft_item.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_opendroneid/pigeon.dart' as pigeon;

class HomeScreen extends StatefulWidget {
  final Map<String, List<MessagePack>> receivedPacks;
  final VoidCallback startScan;
  final VoidCallback stopScan;
  final VoidCallback clearData;

  HomeScreen({
    required this.receivedPacks,
    required this.startScan,
    required this.stopScan,
    required this.clearData,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  StreamSubscription? _bluetoothStateSubscription;
  StreamSubscription? _scanStateSubscription;
  pigeon.BluetoothState bluetoothState = pigeon.BluetoothState.Unknown;
  bool isScanning = false;
  bool autoRestartEnabled = false;
  bool beaconSupported = false;
  bool awareSupported = false;
  bool btLeSupported = false;
  bool btExtendedSupported = false;

  @override
  void initState() {
    // Detect the OS
    print(Platform.operatingSystem);
    // The OS version
    print(Platform.operatingSystemVersion);

    // always supported on android
    if (Platform.operatingSystem == "android") {
      beaconSupported = true;
      btLeSupported = true;
    }

    _bluetoothStateSubscription =
        FlutterOpenDroneId.bluetoothState.listen((state) {
      if (!mounted) return;
      setState(() {
        bluetoothState = state;
      });
    });
    _scanStateSubscription = FlutterOpenDroneId.isScanningStream
        .listen((s) => setState(() => isScanning = s));

    FlutterOpenDroneId.isWifiNanSupported.then((value) {
      setState(() {
        awareSupported = value;
      });
    });

    FlutterOpenDroneId.isBluetoothExtendedSupported.then((value) {
      setState(() {
        btExtendedSupported = value;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _bluetoothStateSubscription?.cancel();
    _scanStateSubscription?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final packs = widget.receivedPacks;
    return Scaffold(
      appBar: AppBar(
        title: Wrap(spacing: 8.0, children: [
          Icon(isScanning ? Icons.circle : Icons.circle_outlined),
          Text('Flutter OpenDroneID'),
        ]),
        backgroundColor: isScanning
            ? Theme.of(context).primaryColor
            : Theme.of(context).primaryColorDark,
        actions: [
          if (bluetoothState != pigeon.BluetoothState.PoweredOn)
            Tooltip(
              child: Icon(Icons.bluetooth_disabled, color: Colors.orangeAccent),
              message: bluetoothState.toString(),
            ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                child: Text('Clear data'),
                value: 'clear',
              ),
              const PopupMenuItem(
                child: Text('About'),
                value: 'about',
              ),
              CheckedPopupMenuItem(
                value: 'autorestart',
                checked: autoRestartEnabled,
                child: Text('Auto-restart'),
              ),
              PopupMenuItem(
                child: Row(
                  children: [
                    Text(
                      "Bluetooth 4:",
                    ),
                    Spacer(),
                    Text(
                      btLeSupported.toString(),
                    )
                  ],
                ),
              ),
              PopupMenuItem(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Bluetooth 5:",
                    ),
                    Spacer(),
                    Text(
                      btExtendedSupported.toString(),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                child: Row(
                  children: [
                    Text(
                      "Wifi Beacon:",
                    ),
                    Spacer(),
                    Text(
                      beaconSupported.toString(),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                child: Row(
                  children: [
                    Text(
                      "Wifi NaN:   ",
                    ),
                    Spacer(),
                    Text(
                      awareSupported.toString(),
                    ),
                  ],
                ),
              ),
            ],
            onSelected: (item) {
              if (item == 'clear') {
                widget.clearData();
              }
              if (item == 'about') {
                showAboutDialog(
                  context: context,
                  applicationName: 'Flutter OpenDroneID',
                  applicationIcon: Icon(Icons.flight),
                  applicationLegalese: '2021 © Dronetag s.r.o.',
                );
              }
              if (item == 'autorestart') {
                setState(() {
                  autoRestartEnabled = !autoRestartEnabled;
                });
                FlutterOpenDroneId.enableAutoRestart(
                    enable: autoRestartEnabled);
              }
            },
            icon: Icon(Icons.more_vert),
          ),
        ],
        centerTitle: false,
      ),
      floatingActionButton: ElevatedButton.icon(
        icon: Icon(isScanning ? Icons.pause : Icons.play_arrow),
        label: Text(isScanning ? 'Stop scan' : 'Start scan'),
        onPressed: isScanning ? widget.stopScan : widget.startScan,
      ),
      body: Builder(builder: (context) {
        final themeMapBrightness =
            Theme.of(context).brightness == Brightness.light ? 'light' : 'dark';
        final mapTileServer =
            'https://cartodb-basemaps-{s}.global.ssl.fastly.net/${themeMapBrightness}_all/{z}/{x}/{y}.png';
        return Column(
          children: [
            Flexible(
                child: FlutterMap(
              options: MapOptions(
                center: LatLng(50.07, 14.43),
                zoom: 4.5,
                interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              layers: [
                TileLayerOptions(
                    backgroundColor: Colors.transparent,
                    urlTemplate: mapTileServer,
                    subdomains: ['a', 'b', 'c']),
                MarkerLayerOptions(
                  markers: packs.values
                      .map<MessagePack>((packs) => packs.last)
                      .where((pack) => pack.locationMessage != null)
                      .map<Marker>((message) {
                    return Marker(
                      width: 12.0,
                      height: 12.0,
                      point: LatLng(message.locationMessage!.latitude!,
                          message.locationMessage!.longitude!),
                      builder: (ctx) => Container(
                        child: Icon(Icons.circle,
                            size: 12.0, color: message.getPackColor()),
                      ),
                    );
                  }).toList(),
                ),
              ],
            )),
            Flexible(
              child: Column(
                children: [
                  Chip(label: Text('${packs.length} drones around')),
                  Expanded(
                    child: ListView(
                      children: ListTile.divideTiles(
                          context: context,
                          tiles: packs.values.map((pack) {
                            return AircraftItem(messagePack: pack.last);
                          })).toList(),
                    ),
                  )
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}
