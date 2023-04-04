import 'dart:async';
import 'dart:collection';

import 'package:ble_app/client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:logging/logging.dart' as logging;
import 'package:permission_handler/permission_handler.dart';

class Bluetooths extends StatefulWidget {
  const Bluetooths({
    Key? key,
  }) : super(key: key);
  @override
  State<Bluetooths> createState() => _Bluetooths();
}

class _Bluetooths extends State<Bluetooths> {
  StreamSubscription? scanSubscription;
  FlutterReactiveBle ble = FlutterReactiveBle();
  final clients = HashMap<String, Client>();
  bool scanning = false;
  logging.Logger log = logging.Logger("Bluetooths");

  _Bluetooths();

  Future<bool> requestLocationPermission() async {
    PermissionStatus status = await Permission.location.status;
    if (status.isDenied || status.isRestricted) {
      if (await Permission.location.request().isGranted) {
        return true;
      } else {
        throw Exception("Permission Denied");
      }
    } else {
      return true;
    }
  }

  Future<void> scan() async {
    await requestLocationPermission();
    if (scanning) {
      scanSubscription!.cancel();
      scanning = false;
      setState(() {});
    } else {
      scanSubscription = ble.scanForDevices(
          withServices: [], scanMode: ScanMode.lowPower).listen((device) {
        Client client = Client(device.id, 255, device.rssi,
            name: device.name.isNotEmpty ? device.name : device.id);
        clients.update(
          client.id,
          (existingValue) => client,
          ifAbsent: () => client,
        );
        setState(() {});
      }, onError: (object, stackTrace) {});
      scanning = true;
      setState(() {});
    }
  }

  connect(Client client) {
    log.info("Connecting ${client.name ?? client.id}");
    client.connect().listen((state) async {
      if (state.connectionState == DeviceConnectionState.connected) {
        log.info("Connected ${client.name ?? client.id}");
        List<DiscoveredService> services =
            await ble.discoverServices(client.id);
        client.groupedCharacteristic(services);
        client.isConnected = true;
        setState(() {});
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return Bluetooth(ble: ble, device: device);
        }));
      }
      if (state.connectionState == DeviceConnectionState.disconnected) {
        client.isConnected = false;
        setState(() {});
      }
    }).onError((e) => log.severe("Connect Error", e));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Devices"),
        actions: [
          TextButton(
            onPressed: () async => await scan(),
            child: Text(
              scanning ? "Stop" : "Scan",
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: ListView.builder(
          itemCount: clients.length,
          itemBuilder: (BuildContext context, int index) {
            Client client = clients.values.toList()[index];
            return ListTile(
              leading: const Icon(Icons.bluetooth),
              subtitle: Text("RSSI: ${client.rssi}"),
              trailing: TextButton(
                child: Text(client.isConnected ? "Connected" : "Connect"),
                onPressed: () async => connect(client),
              ),
              title: Text(client.name ?? client.id),
            );
          }),
    );
  }
}
