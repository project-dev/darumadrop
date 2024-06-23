
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:audioplayers/audioplayers.dart';
import 'package:darumadrop/logger.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'daruma_image.dart';
import 'daruma_state.dart';

void main() {

  WidgetsFlutterBinding.ensureInitialized();

  // 画面の向きを縦にする
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitDown,
    DeviceOrientation.portraitUp
  ]).then((value) => runApp(const MyApp()));

//  FlutterBluePlus.setLogLevel(LogLevel.verbose, color:false);
  FlutterBluePlus.setLogLevel(LogLevel.none, color:false);
  _enableBLE();

  runApp(const MyApp());
}

void _enableBLE() async{
  // check adapter availability
  //if (await FlutterBluePlus.isSupported == false) {
  if (await FlutterBluePlus.isAvailable == false) {
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


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daruma Drop',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver{

  BluetoothDevice? _device;
  bool _isConnect = false;
  DarumaState _state = DarumaState.stay;

  BluetoothCharacteristic? _notifyChara;
  BluetoothCharacteristic? _readChara;
  BluetoothCharacteristic? _writeChara;

  // ベタデータ
  final List<double> _accelX = [];
  final List<double> _accelY = [];
  final List<double> _accelZ = [];
  final List<double> _gyroX = [];
  final List<double> _gyroY = [];
  final List<double> _gyroZ = [];

  // RCフィルタ
  final List<double> _rcAX = [];
  final List<double> _rcAY = [];
  final List<double> _rcAZ = [];
  final List<double> _rcGX = [];
  final List<double> _rcGY = [];
  final List<double> _rcGZ = [];

  String _stateText = "";

  var _curAx = 0.0;
  var _curAy = 0.0;
  var _curAz = 0.0;
  var _curGx = 0.0;
  var _curGy = 0.0;
  var _curGz = 0.0;




  final AudioPlayer _bgmPlayer = AudioPlayer(playerId: "BGM");
  final AudioPlayer _sePlayer = AudioPlayer(playerId: "SE");

  final AssetSource _bgmAsset = AssetSource("audio/neodaruma.mp3");
  // 喝！
  final AssetSource _seAsset03 = AssetSource("audio/daruma_void03.mp3");
  // おみごと
  final AssetSource _seAsset04 = AssetSource("audio/daruma_void04.mp3");

  // 揺れたときの声
  final List<AssetSource> _darumaPlaySe = [
    // お、おちる！
    AssetSource("audio/daruma_void01.mp3"),
    // うわぁ
    AssetSource("audio/daruma_void02.mp3"),
//    // あけおめ
//    AssetSource("audio/daruma_akeome.mp3"),
  ];

  final _random = Random();

  late Timer _timer;

  DarumaState _darumaState = DarumaState.stay;

  DarumaImage _darumaImage = DarumaImage.ready;

  final Map<DarumaImage, Image> _imageMap = {
    DarumaImage.ready:Image.asset("assets/image/daruma_off.png"),
    DarumaImage.normal:Image.asset("assets/image/daruma_on.png"),
    DarumaImage.hit:Image.asset("assets/image/daruma_hit.png"),
  };



  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _bgmPlayer.setVolume(0.2);
    _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    _bgmPlayer.play(_bgmAsset);

    _sePlayer.onPlayerComplete.listen((event) {
      Logger.info("効果音再生終了");
      _state = DarumaState.stay;
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
      // ページの切り替わりでエラー発生
      setState(() {
      });
    },
    );

    // ログレベルの設定
    //FlutterBluePlus.setLogLevel(LogLevel.verbose, color:false);
    FlutterBluePlus.setLogLevel(LogLevel.error, color:false);

    // スキャン時のコールバック設定
    var subscription = FlutterBluePlus.scanResults.listen((results) {
      if(results.isEmpty){
        Logger.debug('result is empty');
      }
      for (ScanResult r in results) {
        var deviceName = r.device.localName;
        //var deviceName = r.device.platformName;

        //Logger.debug('$deviceName found! rssi: ${r.rssi}');
        if("" != deviceName ){
          Logger.debug('$deviceName found!');
        }
        if(_device == null && "daruma" == deviceName ){
          Logger.debug('daruma is scan');
          _device = r.device;
        }
      }
    },onError: (e) {
      Logger.error("error", exception: e);
    });
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
    final Size size = MediaQuery.of(context).size;

    // 計測データをFlSpotに変換する
    final List<LineChartBarData> accelData = [];

    final List<FlSpot> accelX = [];
    for (var i = 0; i < _accelX.length; i++) {
      accelX.add(FlSpot(i.toDouble(), _accelX[i]));
    }

    final List<FlSpot> accelY = [];
    for (var i = 0; i < _accelY.length; i++) {
      accelY.add(FlSpot(i.toDouble(), _accelY[i]));
    }

    final List<FlSpot> accelZ = [];
    for (var i = 0; i < _accelZ.length; i++) {
      accelZ.add(FlSpot(i.toDouble(), _accelZ[i]));
    }
/*
    // X軸の移動量がわかる
    accelData.add(LineChartBarData(
        spots: accelX,
        color:Colors.blue
    ));

    // Z軸の移動量を計測できる(本来はY軸だが、NEOダルマオトシの場合はZ軸)
    accelData.add(LineChartBarData(
        spots: accelY,
        color:Colors.red
    ));

    // Y軸値が変わる。(本来はZ軸だが、NEOダルマオトシの場合はY軸)
    // 実際はZ軸なので、高さで値が変わる
    accelData.add(LineChartBarData(
        spots: accelZ,
        color:Colors.yellow
    ));
*/
    final List<FlSpot> gyroX = [];
    for (var i = 0; i < _gyroX.length; i++) {
      gyroX.add(FlSpot(i.toDouble(), _gyroX[i]));
    }

    final List<FlSpot> gyroY = [];
    for (var i = 0; i < _gyroY.length; i++) {
      gyroY.add(FlSpot(i.toDouble(), _gyroY[i]));
    }

    final List<FlSpot> gyroZ = [];
    for (var i = 0; i < _rcGZ.length; i++) {
      gyroZ.add(FlSpot(i.toDouble(), _rcGZ[i]));
    }
//    for (var i = 0; i < _gyroZ.length; i++) {
//      gyroZ.add(FlSpot(i.toDouble(), _gyroZ[i]));
//    }

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
//        backgroundColor: Colors.white,
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
                      _imageMap[_darumaImage]!,
                      Text(_stateText),
                      Text("Z : ${_curAz.toStringAsFixed(4)}"),
                      Text("Y : ${_curGy.toStringAsFixed(4)}"),
                    ],
                  ),
                ),
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
/*
                            maxY: 2,
                            minY: -2,
 */
                            maxY: 100,
                            minY: -100,
                          )
                      )
                  )
                )
              ]
            )
      ),
        bottomNavigationBar: _makeBottomNavigationBar(),
      )
    );
  }

  Widget _makeBottomNavigationBar() {
    return BottomNavigationBar(
        backgroundColor: const Color.fromARGB(220, 255, 255, 255),

        elevation: 0,
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.bluetooth_searching, size: 42),
            label: "スキャン",
          ),
          BottomNavigationBarItem(
            icon: Icon((_isConnect == true ? Icons.bluetooth_connected : Icons.bluetooth_disabled), size: 42),
            label: "接続",
          ),
        ],
      onTap: (index){
          switch(index){
            case 0:
              _scanBLE();
              setState(() {

              });
              break;
            case 1:
              if(_isConnect){
                _disconnectBLE();
              }else{
                _connectBLE();
              }
              setState(() {

              });
              break;
          }
      },
    );
  }


  void _scanBLE() async {
    // Setup Listener for scan results
    // device not found? see "Common Problems" in the README
    _device = null;
/*
    var subscription = FlutterBluePlus.scanResults.listen((results) {

      if(results.isEmpty){
        Logger.debug('result is empty');
      }

      for (ScanResult r in results) {
        Logger.debug('${r.device.platformName } found! rssi: ${r.rssi}');
        if("" != r.device.platformName ){
          Logger.debug('${r.device.platformName } found!');
        }

        if(_device == null && "daruma" == r.device.platformName ){
          Logger.debug('daruma is scan');
          _device = r.device;
        }
      }
    }).onError((e){
      Logger.error("error", exception: e);
    });
*/
    // Start scanning
    Logger.debug("BLE Scan Start");
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));

    // Stop scanning
    await FlutterBluePlus.stopScan();

    if(null != _device){
      _connectBLE();
    }

    Logger.debug("BLE Scan End");
  }

  bool _isSePlaying = false;
  void _sePlay(AssetSource asset){
    if(_isSePlaying == true){
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

  void _connectBLE() async{
    Logger.debug('connect BLE');


    if(null == _device){
      Logger.debug('device is null');
      _isConnect = false;
      _darumaImage = DarumaImage.ready;
      return;
    }

    // listen for disconnection
    _device?.connectionState.listen((BluetoothConnectionState state) async {
      if (state == BluetoothConnectionState.disconnected) {
        Logger.debug('disconnect');
      }
    });
    await _device?.connect();
    _isConnect = true;
    _darumaImage = DarumaImage.normal;
    // 接続できた！
    //_sePlayer.play(_seAsset03);
    _sePlay(_seAsset03);
    _darumaState = DarumaState.stay;

    // Note: You must call this again if disconnected!
    List<BluetoothService>? services = await _device?.discoverServices();
    await _device?.requestMtu(255);

    _device?.servicesList?.forEach((service)  {
      service.characteristics.forEach((characteristic) async{
        if(characteristic.properties.notify){
          _notifyChara = characteristic;
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

              // ベタデータを保持する
              _accelX.insert(0, aX);
              _accelY.insert(0, aY);
              _accelZ.insert(0, aZ);

              _gyroX.insert(0, gX);
              _gyroY.insert(0, gY);
              _gyroZ.insert(0, gZ);

              // まるめ処理
              // 参考 https://ehbtj.com/electronics/sensor-digital-filter/

              // RCフィルタ
              if(_accelX.length == 1) {
                _curAx = _accelX[0];
                _curAy = _accelY[0];
                _curAz = _accelZ[0];

                _curGx = _gyroX[0];
                _curGy = _gyroY[0];
                _curGz = _gyroZ[0];

              }else if(_accelX.length > 1){
                _curAx = _accelX[0] * 0.8 + _accelX[1] * 0.2;
                _curAy = _accelY[0] * 0.8 + _accelY[1] * 0.2;
                _curAz = _accelZ[0] * 0.8 + _accelZ[1] * 0.2;

                _curGx = _gyroX[0] * 0.8 + _gyroX[1] * 0.2;
                _curGy = _gyroY[0] * 0.8 + _gyroY[1] * 0.2;
                _curGz = _gyroZ[0] * 0.8 + _gyroZ[1] * 0.2;
              }else{
                // データなし
              }

              _rcAX.insert(0, _curAx);
              _rcAY.insert(0, _curAy);
              _rcAZ.insert(0, _curAz);

              _rcGX.insert(0, _curGx);
              _rcGY.insert(0, _curGy);
              _rcGZ.insert(0, _curGz);

              while(_rcGZ.length > 50){
                _accelX.removeLast();
                _accelY.removeLast();
                _accelZ.removeLast();
                _gyroX.removeLast();
                _gyroY.removeLast();
                _gyroZ.removeLast();

                _rcAX.removeLast();
                _rcAY.removeLast();
                _rcAZ.removeLast();
                _rcGX.removeLast();
                _rcGY.removeLast();
                _rcGZ.removeLast();
              }

              // 移動平均

              //Logger.debug("判定中");

              var isDown = false;
              var isMove = false;
              //Logger.debug("_curAz $_curAz");
              //if(_rcAY[0] - _rcAY[1] <= -0.1){
              //if(_rcGX.length >= 2 && _rcGX[0] <= -40 && _rcGX[0] - _rcGX[1] <= -45){



              if(_rcGZ.length >= 4 && (_gyroZ[0] - _gyroZ[1] >= 100 || _gyroZ[1] - _gyroZ[2] >= 100 || _gyroZ[2] - _gyroZ[3] >= 100)){
                //落下
                isDown = true;
              }

              const chkValue = 0.3;
              if(_rcAX.length >= 4 && (
                     ((_rcAX[0] - _rcAX[1]).abs() >= chkValue || (_rcAY[0] - _rcAY[1]).abs() >= chkValue || (_rcAZ[0] - _rcAZ[1]).abs() >= chkValue)
                  && ((_rcAX[1] - _rcAX[2]).abs() >= chkValue || (_rcAY[1] - _rcAY[2]).abs() >= chkValue || (_rcAZ[1] - _rcAZ[2]).abs() >= chkValue)
                  && ((_rcAX[2] - _rcAX[3]).abs() >= chkValue || (_rcAY[2] - _rcAY[3]).abs() >= chkValue || (_rcAZ[2] - _rcAZ[3]).abs() >= chkValue)
                )
              ){
                //縦揺れ
                isMove = true;
              }

              // NG判定
              var ngCount = 0;
              if(_accelX.length >= 10){
                for (var i = 0; i < 10; i++) {
                  if(
                    (_rcGX[i] - _rcGX[i + 1]).abs() >= 100 &&
                    (_rcGY[i] - _rcGY[i + 1]).abs() >= 100 &&
                    (_rcGZ[i] - _rcGZ[i + 1]).abs() >= 100
                  ){
                    ngCount++;
                  }
                }
              }
              var isNg = ngCount > 2;
              if(ngCount > 0){
                Logger.debug("ngCount $ngCount");
              }

              if(isNg == true){
                _darumaState = DarumaState.down;
                _darumaImage = DarumaImage.hit;
                _stateText = "NG";
                Logger.debug("NG");


              }else if(isDown == true){
                _darumaState = DarumaState.down;
                _darumaImage = DarumaImage.hit;
                _stateText = "落下";
                Logger.debug("落下");

              }else if(isMove == true){
                _darumaState = DarumaState.move;
                _stateText = "おっとっと";
                Logger.debug("ゆれ");

              }else{
                _darumaState = DarumaState.stay;

              }


              switch (_darumaState) {
                case DarumaState.move:
                  //_darumaImage = DarumaImage.hit;
                  // 左右に揺れている
                  //if (_sePlayer.state == PlayerState.stopped || _sePlayer.state == PlayerState.completed) {
                  //  Logger.debug("SE play 2");
                  //  var seIndex = _random.nextInt(_darumaPlaySe.length);
                  //  try{
                  //    _sePlayer.play(_darumaPlaySe[seIndex]);
                  //  }catch(e){
                  //    Logger.error("SE再生でエラー", exception: e);
                  //  }
                  //}
                  break;

                case DarumaState.down:
                  _darumaImage = DarumaImage.hit;
                  Logger.debug(_sePlayer.state.toString());
                  //if (_sePlayer.state == PlayerState.stopped ||　_sePlayer.state == PlayerState.completed) {
                    Logger.debug("SE play 1");
                    try{
                      _sePlay(_darumaPlaySe[1]);
                    }catch(e){
                      Logger.error("SE再生でエラー", exception: e);
                    }
                  //}
                  break;
                default:
                  _darumaImage = DarumaImage.normal;
                  _stateText = "";
                  break;
              }

              setState(() {

              });

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
          _readChara = characteristic;
        }

        if(characteristic.properties.write){
          _writeChara = characteristic;
        }

      });
    });
    Logger.debug('connect BLE success');
  }

  void _disconnectBLE() async {
    Logger.debug('disconnect BLE');
    _isConnect = false;
    _darumaImage = DarumaImage.ready;
    if(null == _device){
      Logger.debug('device is null');
      return;
    }
    _device?.disconnect();
  }
}

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