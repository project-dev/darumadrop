import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ゲームの進行
enum PlayStep{
  /// BLE準備中
  bleReady,
  /// 準備中
  ready,
  /// プレイ中
  playing,
  /// gameover
  gameOver,

}

/// ゲームの進行Provider
final playStepProvider = StateProvider<PlayStep>((ref) => PlayStep.bleReady);
