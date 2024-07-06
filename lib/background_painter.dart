import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;

import 'logger.dart';

/// バックグラウンドのアニメーションの描画
class BackgroundPainter extends CustomPainter {

  static ui.Image? backgroundImage;

  static List<double> x = [];
  static List<double> y = [];
  static int areaWidth = 0;
  static int areaHeight = 0;
  static int counter = 0;

  static final _listener = ValueNotifier<int>(0);

//  BackgroundPainter({Listenable? repaint}) : super(repaint: repaint);
  BackgroundPainter() : super(repaint: _listener);

  static void initialize() async{
    final physicalSize = ui.PlatformDispatcher.instance.views.first.physicalSize;
    Logger.info("BackgroundPainter initialize start");
    areaWidth = physicalSize.width.toInt();
    areaHeight = physicalSize.height.toInt();
    Logger.info("width $areaWidth / height $areaHeight");
    backgroundImage = await _loadImage("assets/image/background.png");
    if(backgroundImage == null){
      Logger.error("assets/image/background.png not found");
      return;
    }
    Logger.info("BackgroundPainter initialize end");
  }

  static bool isInitialized(){
    if(backgroundImage == null){
      return false;
    }
    return true;
  }

  static Future<ui.Image?> _loadImage(String assetName) async {
    Logger.info("_loadImage $assetName 1");
    var data = await rootBundle.load(assetName);
    Logger.info("_loadImage $assetName 2");
    return await decodeImageFromList(data.buffer.asUint8List());
  }

  static void calc(){
    if(backgroundImage == null){
      return;
    }


    _listener.value++;
    if(backgroundImage!.width < _listener.value){
      _listener.value = 0;
    }
  }


  @override
  void paint(Canvas canvas, Size size) {
    if(backgroundImage == null){
      return;
    }

    // 背景を動かす
    final Paint paint = Paint()..color = Colors.blue;
    var xCnt = areaWidth / backgroundImage!.width;
    var yCnt = areaHeight / backgroundImage!.height;
    for(int y = -1; y < yCnt + 2; y++){
      for(int x = -1; x < xCnt + 2; x++){
        var imgX = x * backgroundImage!.width + _listener.value;
        var imgY = y * backgroundImage!.height - _listener.value;
        canvas.drawImage(backgroundImage!, Offset(imgX.toDouble(), imgY.toDouble()), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}