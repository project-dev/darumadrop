import 'dart:io';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'logger.dart';

/// BlueToothを切断
void enableBLE() async{
  // check adapter availability
  //if (await FlutterBluePlus.isSupported == false) {
  if (await FlutterBluePlus.isSupported == false) {
    Logger.warn("Bluetooth not supported by this device");
    return;
  }


  // turn on bluetooth ourself if we can
  // for iOS, the user controls bluetooth enable/disable
  if (Platform.isAndroid) {
    await FlutterBluePlus.turnOn();
  }

  // wait bluetooth to be on & print states
  // note: for iOS the initial state is typically BluetoothAdapterState.unknown
  // note: if you have permissions issues you will get stuck at BluetoothAdapterState.unauthorized
  await FlutterBluePlus.adapterState
      .map((s){Logger.debug(s.toString());return s;})
      .where((s) => s == BluetoothAdapterState.on)
      .first;
}
