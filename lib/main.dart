import 'package:ble_app/bluetooths.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:logging/logging.dart' as log;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  log.Logger.root.level = log.Level.ALL; // defaults to Level.INFO
  log.Logger.root.onRecord.listen((record) {
    print(
        '${record.level.name}: ${record.loggerName}: ${record.time}: ${record.message}');
  });
  FlutterReactiveBle();
  runApp(const MaterialApp(
    home: Bluetooths(),
  ));
}
