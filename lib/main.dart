
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:audioplayers/audioplayers.dart';
import 'package:darumadrop/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

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

  final AudioPlayer _bgmPlayer = AudioPlayer();
  final AudioPlayer _sePlayer = AudioPlayer();

  final AssetSource _bgmAsset = AssetSource("audio/neodaruma.mp3");
  // お、おちる！
  final AssetSource _seAsset01 = AssetSource("audio/daruma_void01.mp3");
  // うわぁ
  final AssetSource _seAsset02 = AssetSource("audio/daruma_void02.mp3");
  // 喝！
  final AssetSource _seAsset03 = AssetSource("audio/daruma_void03.mp3");
  // おみごと
  final AssetSource _seAsset04 = AssetSource("audio/daruma_void04.mp3");

  late Timer _timer;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance!.addObserver(this);

    _bgmPlayer.setVolume(0.2);
    _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    _bgmPlayer.play(_bgmAsset);

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
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

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
                      Image.asset(_isConnect == true ? "assets/image/daruma_on.png" : "assets/image/daruma_off.png"),
                      Text(_stateText),
                      Text("Z : ${_curAz.toStringAsFixed(4)}"),
                      Text("Y : ${_curGy.toStringAsFixed(4)}"),
                    ],
                  ),
                ),
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

    var subscription = FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        // Logger.debug('${r.device.localName} found! rssi: ${r.rssi}');
        if("" != r.device.localName){
          Logger.debug('${r.device.localName} found!');
        }

        if(_device == null && "daruma" == r.device.localName){
          Logger.debug('daruma is scan');
          _device = r.device;
        }
      }
    });

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

  void _connectBLE() async{
    Logger.debug('connect BLE');


    if(null == _device){
      Logger.debug('device is null');
      _isConnect = false;
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
    // 接続できた！
    _sePlayer.play(_seAsset03);


    // Note: You must call this again if disconnected!
    List<BluetoothService>? services = await _device?.discoverServices();
    await _device?.requestMtu(255);

    _device?.servicesList?.forEach((service) {
      service.characteristics.forEach((characteristic) async{
        if(characteristic.properties.notify){
          _notifyChara = characteristic;
          Logger.debug("set onValueReceived");
          characteristic.onValueReceived.listen((value) {

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

              while(_accelX.length > 5){
                _accelX.removeLast();
                _accelY.removeLast();
                _accelZ.removeLast();
                _gyroX.removeLast();
                _gyroY.removeLast();
                _gyroZ.removeLast();
              }

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

              Logger.debug(
                  "_curAx ${_curAx.toStringAsFixed(4)} / _curAy ${_curAy.toStringAsFixed(4)} / _curAz ${_curAz.toStringAsFixed(4)} / "
                  "_curGx ${_curGx.toStringAsFixed(4)} / _curGy ${_curGy.toStringAsFixed(4)} / _curGz ${_curGz.toStringAsFixed(4)}"
              );

              _rcAX.insert(0, _curAx);
              _rcAY.insert(0, _curAy);
              _rcAZ.insert(0, _curAz);

              _rcGX.insert(0, _curGx);
              _rcGY.insert(0, _curGy);
              _rcGZ.insert(0, _curGz);

              // 移動平均


              // 落下チェック
              if(_curAz < -0.2){
                // 落下中
                _stateText = "落下";
                _sePlayer.play(_seAsset02);
/*
              }else if(_curGy.abs() >= 25.0){
                // 左右に揺れている
               _stateText = "おっとっと";
                _sePlayer.play(_seAsset01);
*/
              }else{
                _stateText = "";
              }

              setState(() {

              });

//              Logger.debug("onValueReceived $data");

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

  static final _lisner = ValueNotifier<int>(0);

//  BackgroundPainter({Listenable? repaint}) : super(repaint: repaint);
  BackgroundPainter() : super(repaint: _lisner);

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


    _lisner.value++;
    if(backgroundImage!.width < _lisner.value){
      _lisner.value = 0;
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
        var imgX = x * backgroundImage!.width + _lisner.value;
        var imgY = y * backgroundImage!.height - _lisner.value;
        canvas.drawImage(backgroundImage!, Offset(imgX.toDouble(), imgY.toDouble()), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}