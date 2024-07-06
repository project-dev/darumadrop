// ダルマの状態
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DarumaState{
    /// ダルマ待機
    stay,
    /// ダルマ移動
    move,
    /// ダルマ落ちる
    down,
    /// ダルマ登る
    up,
    /// ダルマ転倒
    fallDown,
}

/// ダルマの状態Provider
final darumaStateProvider = StateProvider<DarumaState>((ref) => DarumaState.stay);
