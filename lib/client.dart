import 'dart:typed_data';

import 'package:ble_app/characteristic.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:convert';

class Client {
  Characteristic? writeCharacteristicWithoutRes;
  Characteristic? writeCharacteristicWithRes;
  Characteristic? notifiableCharacteristic;
  Characteristic? indicatableCharacteristic;
  Characteristic? readCharacteristic;
  int rssi;
  int maxPayload;
  String id;
  String? name;
  bool isConnected = false;
  FlutterReactiveBle ble = FlutterReactiveBle();

  Client(this.id, this.maxPayload, this.rssi, {this.name});

  groupedCharacteristic(List<DiscoveredService> discoveredServices) {
    for (DiscoveredService services in discoveredServices) {
      for (DiscoveredCharacteristic characteristic
          in services.characteristics) {
        if (characteristic.isReadable) {
          readCharacteristic = Characteristic(
              characteristic.characteristicId, characteristic.serviceId);
        }
        if (characteristic.isWritableWithoutResponse) {
          writeCharacteristicWithoutRes = Characteristic(
              characteristic.characteristicId, characteristic.serviceId);
        }
        if (characteristic.isWritableWithResponse) {
          writeCharacteristicWithRes = Characteristic(
              characteristic.characteristicId, characteristic.serviceId);
        }
        if (characteristic.isNotifiable) {
          notifiableCharacteristic = Characteristic(
              characteristic.characteristicId, characteristic.serviceId);
        }
        if (characteristic.isIndicatable) {
          indicatableCharacteristic = Characteristic(
              characteristic.characteristicId, characteristic.serviceId);
        }
      }
    }
  }

  Stream<ConnectionStateUpdate> connect() {
    return ble.connectToDevice(id: id);
  }

  Future<void> send(List<int> data, Characteristic characteristic) async {
    QualifiedCharacteristic qualifiedCharacteristic = QualifiedCharacteristic(
        serviceId: (characteristic).serviceId,
        characteristicId: characteristic.id,
        deviceId: id);
    await ble.writeCharacteristicWithResponse(qualifiedCharacteristic,
        value: data);
  }

  Future<void> sendMsg(String msg, Characteristic characteristic) async {
    List<int> binaryMessage = utf8.encode(msg);
    Uint8List data = Uint8List.fromList(binaryMessage);
    await send(data, characteristic);
  }

  Stream<List<int>> sendFile(Uint8List data) {
    return Stream.fromIterable(data).bufferCount(maxPayload);
  }
}
