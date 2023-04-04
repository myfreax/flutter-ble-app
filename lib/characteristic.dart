import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class Characteristic {
  Uuid id;
  Uuid serviceId;
  Characteristic(this.id, this.serviceId);
}
