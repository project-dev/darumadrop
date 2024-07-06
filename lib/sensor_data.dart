import 'package:flutter_riverpod/flutter_riverpod.dart';

class SensorData{
  // ベタデータ
  List<double> accelX = [];
  List<double> accelY = [];
  List<double> accelZ = [];
  List<double> gyroX = [];
  List<double> gyroY = [];
  List<double> gyroZ = [];

  // RCフィルタ
  List<double> rcAX = [];
  List<double> rcAY = [];
  List<double> rcAZ = [];
  List<double> rcGX = [];
  List<double> rcGY = [];
  List<double> rcGZ = [];

  var axTotal = 0.0;
  var ayTotal = 0.0;
  var azTotal = 0.0;

  var gxTotal = 0.0;
  var gyTotal = 0.0;
  var gzTotal = 0.0;

  SensorData({
    List<double>? accelX,
    List<double>? accelY,
    List<double>? accelZ,
    List<double>? gyroX,
    List<double>? gyroY,
    List<double>? gyroZ,
    List<double>? rcAX,
    List<double>? rcAY,
    List<double>? rcAZ,
    List<double>? rcGX,
    List<double>? rcGY,
    List<double>? rcGZ,
    double? axTotal,
    double? ayTotal,
    double? azTotal,
    double? gxTotal,
    double? gyTotal,
    double? gzTotal,
  }) {
    this.accelX = accelX ?? this.accelX;
    this.accelY = accelY ?? this.accelY;
    this.accelZ = accelZ ?? this.accelZ;
    this.gyroX = gyroX ?? this.gyroX;
    this.gyroY = gyroY ?? this.gyroY;
    this.gyroZ = gyroZ ?? this.gyroZ;
    this.rcAX = rcAX ?? this.rcAX;
    this.rcAY = rcAY ?? this.rcAY;
    this.rcAZ = rcAZ ?? this.rcAZ;
    this.rcGX = rcGX ?? this.rcGX;
    this.rcGY = rcGY ?? this.rcGY;
    this.rcGZ = rcGZ ?? this.rcGZ;
    this.axTotal = axTotal ?? this.axTotal;
    this.ayTotal = ayTotal ?? this.ayTotal;
    this.azTotal = azTotal ?? this.azTotal;
    this.gxTotal = gxTotal ?? this.gxTotal;
    this.gyTotal = gyTotal ?? this.gyTotal;
    this.gzTotal = gzTotal ?? this.gzTotal;
  }

  SensorData copyWith({
    List<double>? accelX,
    List<double>? accelY,
    List<double>? accelZ,
    List<double>? gyroX,
    List<double>? gyroY,
    List<double>? gyroZ,
    List<double>? rcAX,
    List<double>? rcAY,
    List<double>? rcAZ,
    List<double>? rcGX,
    List<double>? rcGY,
    List<double>? rcGZ,
    double? axTotal,
    double? ayTotal,
    double? azTotal,
    double? gxTotal,
    double? gyTotal,
    double? gzTotal,
  }) {
    return SensorData(
      accelX: accelX ?? this.accelX,
      accelY: accelY ?? this.accelY,
      accelZ: accelZ ?? this.accelZ,
      gyroX: gyroX ?? this.gyroX,
      gyroY: gyroY ?? this.gyroY,
      gyroZ: gyroZ ?? this.gyroZ,
      rcAX: rcAX ?? this.rcAX,
      rcAY: rcAY ?? this.rcAY,
      rcAZ: rcAZ ?? this.rcAZ,
      rcGX: rcGX ?? this.rcGX,
      rcGY: rcGY ?? this.rcGY,
      rcGZ: rcGZ ?? this.rcGZ,
      axTotal: axTotal ?? this.axTotal,
      ayTotal: ayTotal ?? this.ayTotal,
      azTotal: azTotal ?? this.azTotal,
      gxTotal: gxTotal ?? this.gxTotal,
      gyTotal: gyTotal ?? this.gyTotal,
      gzTotal: gzTotal ?? this.gzTotal,
    );
  }

}

final sensorModelProvider = StateNotifierProvider<SensorDataNotifier, SensorData>((ref){
  return SensorDataNotifier();
});


class SensorDataNotifier extends StateNotifier<SensorData>{
  SensorDataNotifier() : super(SensorData());

  void addAccelData(double x, double y, double z) {
    double curAx = 0;
    double curAy = 0;
    double curAz = 0;

    if(state.accelX.length < 4) {
      state = state.copyWith(
        axTotal: state.axTotal + x,
        ayTotal: state.ayTotal + y,
        azTotal: state.azTotal + z,
      );
    }else if(state.accelX.length >= 4){
      x -= (state.axTotal / 3);
      y -= (state.ayTotal / 3);
      z -= (state.azTotal / 3);
    }

    if(state.accelX.length == 1) {
      curAx = state.accelX[0];
      curAy = state.accelY[0];
      curAz = state.accelZ[0];

    }else if(state.accelX.length > 1){
      curAx = state.accelX[0] * 0.8 + state.accelX[1] * 0.2;
      curAy = state.accelY[0] * 0.8 + state.accelY[1] * 0.2;
      curAz = state.accelZ[0] * 0.8 + state.accelZ[1] * 0.2;
    }else{
      // データなし
    }

    state.accelX.insert(0, x);
    state.accelY.insert(0, y);
    state.accelZ.insert(0, z);

    state.rcAX.insert(0, curAx);
    state.rcAY.insert(0, curAy);
    state.rcAZ.insert(0, curAz);

    var limit = state.accelX.length >= 50 ? 50 : state.accelX.length;
    state.accelX = state.accelX.getRange(0, limit).toList();
    state.accelY = state.accelY.getRange(0, limit).toList();
    state.accelZ = state.accelZ.getRange(0, limit).toList();

    state.rcAX = state.rcAX.getRange(0, limit).toList();
    state.rcAY = state.rcAY.getRange(0, limit).toList();
    state.rcAZ = state.rcAZ.getRange(0, limit).toList();

    state.accelX = [...state.accelX];
    state.accelY = [...state.accelY];
    state.accelZ = [...state.accelZ];

    state.rcAX = [...state.rcAX];
    state.rcAY = [...state.rcAY];
    state.rcAZ = [...state.rcAZ];

    state = state.copyWith(
      accelX: [...state.accelX],
      accelY: [...state.accelY],
      accelZ: [...state.accelZ],
      rcAX: [...state.rcAX],
      rcAY: [...state.rcAY],
      rcAZ: [...state.rcAZ],
    );

  }

  void addGyroData(double x, double y, double z){
    double curX = 0;
    double curY = 0;
    double curZ = 0;

    if(state.gyroX.length < 4) {
      state = state.copyWith(
        gxTotal: state.gxTotal + x,
        gyTotal: state.gyTotal + y,
        gzTotal: state.gzTotal + z,
      );
    }else if(state.gyroX.length >= 4){
      x -= (state.gxTotal / 3);
      y -= (state.gyTotal / 3);
      z -= (state.gzTotal / 3);
    }


    if(state.gyroX.length == 1) {
      curX = state.gyroX[0];
      curY = state.gyroY[0];
      curZ = state.gyroZ[0];

    }else if(state.gyroX.length > 1){
      curX = state.gyroX[0] * 0.8 + state.gyroX[1] * 0.2;
      curY = state.gyroY[0] * 0.8 + state.gyroY[1] * 0.2;
      curZ = state.gyroZ[0] * 0.8 + state.gyroZ[1] * 0.2;
    }else{
      // データなし
    }

    state.gyroX.insert(0, x);
    state.gyroY.insert(0, y);
    state.gyroZ.insert(0, z);

    state.rcGX.insert(0, curX);
    state.rcGY.insert(0, curY);
    state.rcGZ.insert(0, curZ);

    var limit = state.gyroX.length >= 50 ? 50 : state.gyroX.length;
    state.gyroX = state.gyroX.getRange(0, limit).toList();
    state.gyroY = state.gyroY.getRange(0, limit).toList();
    state.gyroZ = state.gyroZ.getRange(0, limit).toList();

    state.rcGX = state.rcGX.getRange(0, limit).toList();
    state.rcGY = state.rcGY.getRange(0, limit).toList();
    state.rcGZ = state.rcGZ.getRange(0, limit).toList();

    state = state.copyWith(
      gyroX: [...state.gyroX],
      gyroY: [...state.gyroY],
      gyroZ: [...state.gyroZ],
      rcGX: [...state.rcGX],
      rcGY: [...state.rcGY],
      rcGZ: [...state.rcGZ],
    );
  }
}