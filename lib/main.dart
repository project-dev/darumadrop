
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ble_util.dart';
import 'my_app.dart';

/// メイン
void main() {

  WidgetsFlutterBinding.ensureInitialized();

  // 画面の向きを縦にする
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitDown,
    DeviceOrientation.portraitUp
  ]).then((value) => runApp(
      const ProviderScope(
          child : MyApp()
      )
    )
  );

//  FlutterBluePlus.setLogLevel(LogLevel.verbose, color:false);
  FlutterBluePlus.setLogLevel(LogLevel.none, color:false);
  enableBLE();
}
