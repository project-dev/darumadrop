
import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:audioplayers/audioplayers.dart';
import 'package:darumadrop/logger.dart';
import 'package:darumadrop/sensor_data.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'background_painter.dart';
import 'enum/daruma_image.dart';
import 'enum/daruma_state.dart';
import 'enum/play_state.dart';

///
class DarumaHomePage extends ConsumerStatefulWidget {
  const DarumaHomePage({super.key});

  @override
  ConsumerState<DarumaHomePage> createState() => _DarumaHomePageState();
}

class _DarumaHomePageState extends ConsumerState<DarumaHomePage> with WidgetsBindingObserver{

  BluetoothDevice? _device;

  //BluetoothCharacteristic? _notifyChara;
  //BluetoothCharacteristic? _readChara;
  //BluetoothCharacteristic? _writeChara;

  final AudioPlayer _bgmPlayer = AudioPlayer(playerId: "BGM");
  final AudioPlayer _sePlayer = AudioPlayer(playerId: "SE");

  /// BGM
  final AssetSource _bgmAsset = AssetSource("audio/neodaruma.mp3");
  /// お、おちる
  final AssetSource _seAsset01 = AssetSource("audio/daruma_void01.mp3");
  /// うわぁ
  final AssetSource _seAsset02 = AssetSource("audio/daruma_void02.mp3");
  /// 喝！
  final AssetSource _seAsset03 = AssetSource("audio/daruma_void03.mp3");
  /// おみごと
  final AssetSource _seAsset04 = AssetSource("audio/daruma_void04.mp3");
  /// 否！
  final AssetSource _seAsset05 = AssetSource("audio/daruma_void05.mp3");
  /// んあぁ！
  final AssetSource _seAsset06 = AssetSource("audio/daruma_void06.mp3");
  /// 待たれよ・・・
  final AssetSource _seAsset07 = AssetSource("audio/daruma_void07.mp3");
  /// 何処へ・・・
  final AssetSource _seAsset08 = AssetSource("audio/daruma_void08.mp3");
  /// あわわわわわ
  final AssetSource _seAsset09 = AssetSource("audio/daruma_void09.mp3");
  /// マジか
  final AssetSource _seAsset10 = AssetSource("audio/daruma_void10.mp3");

  // 揺れたときの声
  final List<AssetSource> _darumaPlaySe = [
    /// んなぁ！
    AssetSource("audio/daruma_void06.mp3"),
    /// うわぁ
    AssetSource("audio/daruma_void02.mp3"),
    /// あわわわわわ
    AssetSource("audio/daruma_void09.mp3"),
    /// まじか
    AssetSource("audio/daruma_void10.mp3"),
//    // あけおめ
//    AssetSource("audio/daruma_akeome.mp3"),
  ];

//  final _random = Random();

  late Timer _timer;

//  DarumaState _darumaState = DarumaState.stay;

//  DarumaImage _darumaImage = DarumaImage.ready;

  final Map<DarumaImage, Image> _imageMap = {
    DarumaImage.ready:Image.asset("assets/image/daruma_off.png"),
    DarumaImage.normal:Image.asset("assets/image/daruma_on.png"),
    DarumaImage.hit:Image.asset("assets/image/daruma_hit.png"),
  };



  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _bgmPlayer.setVolume(0.1);
    _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    _bgmPlayer.play(_bgmAsset);

    _sePlayer.onPlayerComplete.listen((event) {
      Logger.info("効果音再生終了");
      //ref.read(darumaStateProvider.notifier).state = DarumaState.stay;
    });

    if(BackgroundPainter.isInitialized() == false)  {
      BackgroundPainter.initialize();
    }

    _timer = Timer.periodic(
      // 第一引数：繰り返す間隔の時間を設定
      const Duration(milliseconds: 66), (Timer timer) {
      // 初期化待ち
      if(!BackgroundPainter.isInitialized()){
        return;
      }
      BackgroundPainter.calc();
//      // ページの切り替わりでエラー発生
//      setState(() {
//      });
    },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch(state){
      case AppLifecycleState.inactive:
      //非アクティブ
        _bgmPlayer.stop();
        break;
      case AppLifecycleState.paused:
      // 停止されたとき
        _bgmPlayer.stop();
        break;
      case AppLifecycleState.resumed:
      // 再開されたとき
        if(_bgmPlayer.state != PlayerState.playing){
          _bgmPlayer.play(_bgmAsset);
        }
        break;
      case AppLifecycleState.detached:
      // 破棄されたとき
        _bgmPlayer.stop();
        break;
      case ui.AppLifecycleState.hidden:
      // TODO: Handle this case.
    }
  }

  @override
  Widget build(BuildContext context) {

    var step = ref.watch(playStepProvider);
    var darumaImage = ref.watch(darumaImageProvider);
    //var darumaState = ref.watch(darumaStateProvider);
    var sensorData = ref.watch(sensorModelProvider);

    final Size size = MediaQuery.of(context).size;

    // 計測データをFlSpotに変換する
    final List<LineChartBarData> accelData = [];

    final List<FlSpot> accelX = [];
    for (var i = 0; i < sensorData.accelX.length; i++) {
      accelX.add(FlSpot(i.toDouble(), sensorData.accelX[i] * 300.0));
    }

    final List<FlSpot> accelY = [];
    for (var i = 0; i < sensorData.accelY.length; i++) {
      accelY.add(FlSpot(i.toDouble(), sensorData.accelY[i] * 100.0));
    }

    final List<FlSpot> accelZ = [];
    for (var i = 0; i < sensorData.accelZ.length; i++) {
      accelZ.add(FlSpot(i.toDouble(), sensorData.accelZ[i] * 300.0));
    }

    // X軸の移動量がわかる
    accelData.add(LineChartBarData(
        spots: accelX,
        color:Colors.blue
    ));

    // Y軸値が変わる。(本来はZ軸だが、NEOダルマオトシの場合はY軸)
    // 実際はZ軸なので、高さで値が変わる
    accelData.add(LineChartBarData(
        spots: accelZ,
        color:Colors.yellow
    ));

    // Z軸の移動量を計測できる(本来はY軸だが、NEOダルマオトシの場合はZ軸)
    accelData.add(LineChartBarData(
        spots: accelY,
        color:Colors.red
    ));


    final List<FlSpot> gyroX = [];
    for (var i = 0; i < sensorData.gyroX.length; i++) {
      gyroX.add(FlSpot(i.toDouble(), sensorData.gyroX[i]));
    }

    final List<FlSpot> gyroY = [];
    for (var i = 0; i < sensorData.gyroY.length; i++) {
      gyroY.add(FlSpot(i.toDouble(), sensorData.gyroY[i]));
    }

    final List<FlSpot> gyroZ = [];
    for (var i = 0; i < sensorData.rcGZ.length; i++) {
      gyroZ.add(FlSpot(i.toDouble(), sensorData.rcGZ[i]));
    }
//    for (var i = 0; i < _gyroZ.length; i++) {
//      gyroZ.add(FlSpot(i.toDouble(), _gyroZ[i]));
//    }

/*
    // あまり動かない
    accelData.add(LineChartBarData(
      spots: gyroX,
      color:Colors.blue,
      dashArray: [2],
    ));

    // 結構動くので横方向の移動はこの値で確認できそう
    accelData.add(LineChartBarData(
      spots: gyroY,
      color:Colors.red,
      dashArray: [2],
    ));

    // おそらく基準は180～200くらい
    // 縦方向の移動方向はこの値で判断できそう
    accelData.add(LineChartBarData(
      spots: gyroZ,
      color:Colors.yellow,
      //dashArray: [2],
    ));
*/
    final List<FlSpot> rcAX = [];
    final List<FlSpot> rcAY = [];
    final List<FlSpot> rcAZ = [];
    final List<FlSpot> rcGX = [];
    final List<FlSpot> rcGY = [];
    final List<FlSpot> rcGZ = [];

    return WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
          extendBody: true,
          body:SafeArea(
              child: Stack(
                  children:[
                    Container(
                      alignment: Alignment.bottomCenter,
                      child: CustomPaint(
                        size: Size(size.width, size.height),
                        painter: BackgroundPainter(),
                      ),
                    ),

                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          _imageMap[darumaImage]!,
                        ],
                      ),
                    ),
/*
                    Center(
                        child:
                        Container(
                            alignment: Alignment.bottomCenter,
                            child:
                            accelData.isEmpty ? const Text("Wait") :
                            LineChart(
                                LineChartData(
                                  lineBarsData: accelData,
                                  titlesData: const FlTitlesData(
                                    topTitles: AxisTitles(
                                      axisNameWidget: Text(
                                        "加速度センサー",
                                      ),
                                      axisNameSize: 35.0,
                                    ),
                                    rightTitles:
                                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  ),

                            //maxY: 2,
                            //minY: -2,

                                  maxY: 100,
                                  minY: -100,
                                )
                            )
                        )
                    ),
*/
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _makeButton()
                        ],
                      ),
                    )
                  ]
              )
          ),
        )
    );
  }

  Widget _makeButton(){
    if(_device == null){
      return TextButton.icon(
        onPressed: () {
          _scanBLE();
        },
        icon: const Icon(Icons.bluetooth_searching, size: 42, color: Colors.white),
        label: const Text(
            'ダルマに接続！',
            style: TextStyle(
                color: Colors.white,
                fontSize: 48
            )
        ),
        style: TextButton.styleFrom(
          backgroundColor: Colors.blue,
        ),
      );
    }else if(ref.read(playStepProvider) == PlayStep.gameOver){
      return TextButton.icon(
        onPressed: () {
          ref.read(playStepProvider.notifier).state = PlayStep.playing;
        },
        icon: const Icon(Icons.refresh, size: 42, color: Colors.white),
        label: const Text(
            '再挑戦する',
            style: TextStyle(
                color: Colors.white,
                fontSize: 48
            )
        ),
        style: TextButton.styleFrom(
          backgroundColor: Colors.blue,
        ),
      );
    }else{
      return const Text("");
    }

  }


  void _scanBLE() async {
    // Setup Listener for scan results
    // device not found? see "Common Problems" in the README
    _device = null;
    _sePlay(_seAsset07);

    // ログレベルの設定
    //FlutterBluePlus.setLogLevel(LogLevel.verbose, color:false);
    FlutterBluePlus.setLogLevel(LogLevel.error, color:false);

    // スキャン時のコールバック設定
    var subscription = FlutterBluePlus.onScanResults.listen((results) {
      if(results.isEmpty){
        Logger.debug('result is empty');
        _device = null;
        ref.read(darumaImageProvider.notifier).state = DarumaImage.ready;
        ref.read(playStepProvider.notifier).state = PlayStep.bleReady;
        return;
      }
      for (ScanResult r in results) {
        var deviceName = r.device.platformName;
        Logger.debug('$deviceName ...');
        if("" != deviceName ){
          Logger.debug('$deviceName found!');
        }
        if(_device == null && "daruma" == deviceName ){
          Logger.debug('daruma is scan');
          _device = r.device;
          ref.read(darumaImageProvider.notifier).state = DarumaImage.normal;
          ref.read(playStepProvider.notifier).state = PlayStep.ready;
          _connectBLE();
        }
      }
    },onError: (e) {
      Logger.error("error", exception: e);
    });

    FlutterBluePlus.cancelWhenScanComplete(subscription);
    FlutterBluePlus.events.onConnectionStateChanged.listen((event){
      switch(event.connectionState){
        case BluetoothConnectionState.connected:
          break;
        case BluetoothConnectionState.disconnected:
          _device = null;
          ref.read(darumaImageProvider.notifier).state = DarumaImage.ready;
          ref.read(playStepProvider.notifier).state = PlayStep.bleReady;
          _sePlay(_seAsset08);
          break;
        default:
          break;
      }
    });

    // Start scanning
    Logger.debug("BLE Scan Start");
    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 4),
      withNames: ["daruma"],
    );

    await FlutterBluePlus.isScanning.where((val) => val == false).first;
    if(_device == null){
      // 見つからない！
      _sePlay(_seAsset05);
    }
    Logger.debug("BLE Scan End");
  }

  bool _isSePlaying = false;
  /// SEの再生
  void _sePlay(AssetSource asset){
    if(_isSePlaying == true || _sePlayer.state == PlayerState.playing){
      return;
    }
    _isSePlaying = true;
    _sePlayer.play(asset)
        .then((value){
      _isSePlaying = false;
    })
        .catchError((e){
      _isSePlaying = false;
      Logger.error("SE再生でエラー", exception: e);
    });
  }

  var axTotal = 0.0;
  var ayTotal = 0.0;
  var azTotal = 0.0;

  var xTotal = 0.0;
  var yTotal = 0.0;
  var zTotal = 0.0;
  void _connectBLE() async{
    Logger.debug('connect BLE');

    if(null == _device){
      Logger.debug('device is null');
      ref.read(darumaImageProvider.notifier).state = DarumaImage.ready;
      return;
    }

    // listen for disconnection
    _device?.connectionState.listen((BluetoothConnectionState state) async {
      if (state == BluetoothConnectionState.disconnected) {
        Logger.debug('disconnect');
        _sePlay(_seAsset03);
      }
    });
    try{
      await _device?.connect();
      ref.read(playStepProvider.notifier).state = PlayStep.playing;
    }catch(e){
      Logger.error("BLEの接続でエラー", exception: e);
      ref.read(darumaImageProvider.notifier).state = DarumaImage.ready;
      ref.read(playStepProvider.notifier).state = PlayStep.bleReady;
      return;
    }

    ref.read(darumaImageProvider.notifier).state = DarumaImage.normal;
    // 接続できた！
    _sePlay(_seAsset03);
    ref.read(darumaStateProvider.notifier).state = DarumaState.stay;

    // Note: You must call this again if disconnected!
    List<BluetoothService>? services = await _device?.discoverServices();
    await _device?.requestMtu(255);

    _device?.servicesList?.forEach((service)  {
      service.characteristics.forEach((characteristic) async{
        if(characteristic.properties.notify){
          //_notifyChara = characteristic;
          Logger.debug("set onValueReceived");
          characteristic.onValueReceived.listen((value) async{

            // (accelX, accelY, accelZ),(gyroX, gyroY, gyroZ)
            var data = String.fromCharCodes(value);
            data = data.replaceAll("(", "").replaceAll(")", "");
            var tokens = data.split(",");

            var aX = double.tryParse(tokens[0]) ?? 0;
            var aY = double.tryParse(tokens[1]) ?? 0;
            var aZ = double.tryParse(tokens[2]) ?? 0;
            var gX = double.tryParse(tokens[3]) ?? 0;
            var gY = double.tryParse(tokens[4]) ?? 0;
            var gZ = double.tryParse(tokens[5]) ?? 0;

            aX = (aX * 1000.0).floorToDouble() / 1000.0;
            aY = (aY * 1000.0).floorToDouble() / 1000.0;
            aZ = (aZ * 1000.0).floorToDouble() / 1000.0;

            gX = (gX * 1000.0).floorToDouble() / 1000.0;
            gY = (gY * 1000.0).floorToDouble() / 1000.0;
            gZ = (gZ * 1000.0).floorToDouble() / 1000.0;

            var sensorDataNotifier  = ref.read(sensorModelProvider.notifier);
            var sensorData  = ref.read(sensorModelProvider);
            sensorDataNotifier.addAccelData(aX, aY, aZ);
            sensorDataNotifier.addGyroData(gX, gY, gZ);

            if(ref.read(playStepProvider) == PlayStep.playing){
              var gyroZ = sensorData.gyroZ;
              var rcAY = sensorData.rcAY;
              // 移動平均
              /*
              if(rcAY.length >= 4 && (rcAY[0]  > 1 && rcAY[1] > 1 && rcAY[2] > 1 && rcAY[3] > 1)){
                //転倒
                ref.read(playStepProvider.notifier).state = PlayStep.gameOver;
                ref.read(darumaStateProvider.notifier).state = DarumaState.fallDown;
                ref.read(darumaImageProvider.notifier).state = DarumaImage.hit;
                try{
                  var idx = Random().nextInt(_darumaPlaySe.length);
                  _sePlay(_darumaPlaySe[idx]);
                }catch(e){
                  Logger.error("SE再生でエラー", exception: e);
                }
                Logger.debug("NG");
              }else

               */
              if(gyroZ.length >= 4 && gyroZ[0] <= -60){
                //落下
                ref.read(darumaStateProvider.notifier).state = DarumaState.down;
                ref.read(darumaImageProvider.notifier).state = DarumaImage.hit;
                try{
                  var idx = Random().nextInt(_darumaPlaySe.length);
                  _sePlay(_darumaPlaySe[idx]);
                }catch(e){
                  Logger.error("SE再生でエラー", exception: e);
                }
                Logger.debug("落下");

              }else{
                if(_sePlayer.state != PlayerState.playing){
                  ref.read(darumaStateProvider.notifier).state = DarumaState.stay;
                  ref.read(darumaImageProvider.notifier).state = DarumaImage.normal;
                }
                //Logger.debug("通常");
              }
            }
          },
          );

          // ここでsetNotifyValue(true)を呼び出すことでonValueReceivedのリスナーが呼び出されるようになる
          if(await characteristic.setNotifyValue(true)){
            Logger.debug("setNotifyValue success");
          }else{
            Logger.debug("setNotifyValue failed");
          }
        }
        if(characteristic.properties.read){
          //_readChara = characteristic;
        }

        if(characteristic.properties.write){
          //_writeChara = characteristic;
        }

      });
    });
    Logger.debug('connect BLE success');
  }

  void _disconnectBLE() async {
    Logger.debug('disconnect BLE');
    ref.read(darumaImageProvider.notifier).state = DarumaImage.ready;
    if(null == _device){
      Logger.debug('device is null');
      return;
    }
    _device?.disconnect();
  }
}

