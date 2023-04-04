import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:rxdart/rxdart.dart';

class Bluetooth extends StatefulWidget {
  final FlutterReactiveBle ble;
  final DiscoveredDevice device;

  const Bluetooth({
    required this.ble,
    required this.device,
    Key? key,
  }) : super(key: key);
  @override
  // ignore: no_logic_in_create_state
  State<StatefulWidget> createState() => _Bluetooth(ble: ble, device: device);
}

class _Bluetooth extends State<Bluetooth> {
  List<String> messages = ["string"];
  FlutterReactiveBle ble;
  final DiscoveredDevice device;

  late Uuid writeCharacteristicIdWithRes;
  late Uuid writeCharacteristicIdWithoutRes;
  late Uuid readCharacteristicId;
  late Uuid notifiableCharacteristicId;
  late Uuid indicatableCharacteristicId;
  late Uuid serviceId;

  _Bluetooth({required this.ble, required this.device});
  Future<void> send(List<int> data) async {
    final characteristic = QualifiedCharacteristic(
        serviceId: serviceId,
        characteristicId: writeCharacteristicIdWithRes,
        deviceId: device.id);
    await ble.writeCharacteristicWithResponse(characteristic, value: data);
  }

  Future<void> sendMsg(String msg) async {
    List<int> binaryMessage = utf8.encode(msg);
    Uint8List data = Uint8List.fromList(binaryMessage);
    print("Send Message: $msg");
    send(data);
  }

  Future<void> sendFile() async {
    FilePickerResult? filePickerResult = await FilePicker.platform.pickFiles();
    if (filePickerResult != null) {
      print("Send File: ${filePickerResult.files[0].path}");
      Uint8List data =
          await File(filePickerResult.files[0].path!).readAsBytes();
      Stream.fromIterable(data).bufferCount(255).listen((event) async {
        await send(event);
      }).onDone(() {
        print("complete");
      });
    } else {
      print("Please Picker File");
    }
  }

  Future<void> connect(String deviceId) async {
    print('Start connecting to $deviceId');
    ble.connectToDevice(id: deviceId).listen(
      (state) async {
        if (state.connectionState == DeviceConnectionState.connected) {
          List<DiscoveredService> results =
              await ble.discoverServices(deviceId);
          for (var services in results) {
            for (var characteristic in services.characteristics) {
              if (characteristic.isReadable) {
                readCharacteristicId = characteristic.characteristicId;
              }
              if (characteristic.isWritableWithoutResponse) {
                writeCharacteristicIdWithoutRes =
                    characteristic.characteristicId;
              }
              if (characteristic.isWritableWithResponse) {
                writeCharacteristicIdWithRes = characteristic.characteristicId;
                serviceId = characteristic.serviceId;
              }
              if (characteristic.isNotifiable) {
                notifiableCharacteristicId = characteristic.characteristicId;
              }
              if (characteristic.isIndicatable) {
                indicatableCharacteristicId = characteristic.characteristicId;
              }
            }
          }
        }
        print(
            'ConnectionState for device $deviceId : ${state.connectionState}');
      },
      onError: (Object e) =>
          print('Connecting to device $deviceId resulted in error $e'),
    );
  }

  @override
  void initState() {
    super.initState();
    connect(device.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Device"),
        ),
        body: Container(
            margin: const EdgeInsets.all(20),
            child: Stack(
              children: [
                Align(
                  child: ListView.builder(
                      itemCount: messages.length,
                      itemBuilder: ((context, index) {
                        String message = messages[index];
                        return ListTile(
                          title: Text(message),
                        );
                      })),
                ),
                Align(
                    alignment: Alignment.bottomLeft,
                    child: TextButton(
                      child: const Text("send file"),
                      onPressed: () async {
                        await sendFile();
                      },
                    )),
                Align(
                    alignment: Alignment.bottomRight,
                    child: TextButton(
                      child: const Text("send hello"),
                      onPressed: () async {
                        await sendMsg("hello");
                      },
                    ))
              ],
            )));
  }
}
