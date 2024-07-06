import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DarumaImage{
  ready,
  normal,
  hit
}

/// ダルマの画像Provider
final darumaImageProvider = StateProvider<DarumaImage>((ref) => DarumaImage.ready);
