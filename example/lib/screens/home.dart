import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_opendroneid/flutter_opendroneid.dart';
import 'package:flutter_opendroneid/models/enums.dart';
import 'package:flutter_opendroneid/models/message_pack.dart';
import 'package:flutter_opendroneid_example/widgets/aircraft_item.dart';
import 'package:latlong2/latlong.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, List<MessagePack>> receivedPacks;
  final bool isScanning;
  final VoidCallback startScan;
  final VoidCallback stopScan;
  final VoidCallback clearData;

  HomeScreen({
    required this.receivedPacks,
    required this.isScanning,
    required this.startScan,
    required this.stopScan,
    required this.clearData,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  StreamSubscription? _bluetoothStateSubscription;
  BluetoothState bluetoothState = BluetoothState.Unknown;

  @override
  void initState() {
    _bluetoothStateSubscription =
        FlutterOpenDroneId.bluetoothState.listen((state) {
      if (!mounted) return;
      setState(() {
        bluetoothState = state;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _bluetoothStateSubscription?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    final packs = widget.receivedPacks;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter OpenDroneID'),
        actions: [
          if (bluetoothState != BluetoothState.PoweredOn)
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
            },
            icon: Icon(Icons.more_vert),
          ),
        ],
        centerTitle: false,
      ),
      floatingActionButton: ElevatedButton.icon(
        icon: Icon(widget.isScanning ? Icons.pause : Icons.play_arrow),
        label: Text(widget.isScanning ? 'Stop scan' : 'Start scan'),
        onPressed: widget.isScanning ? widget.stopScan : widget.startScan,
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
