
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:developer' as developer;

class Logger{

  static List<String> logList = [];

  static String _applicationName = "";

  /// ログに出力するアプリ名を設定する
  static void setApplicationName(String applicationName){
    _applicationName = applicationName;
  }

  /// アプリの情報を取得する
  static void _getAppInfo() async {
    if(_applicationName == '' || _applicationName == 'UNKNOWN'){
      try{
        PackageInfo packageInfo = await PackageInfo.fromPlatform();
        _applicationName = packageInfo.appName;
      }catch(e){
        _applicationName = 'UNKNOWN';
      }
    }
  }

  /// インフォメーションログを出力する
  static info(String log){
    String stackTrace = StackTrace.current.toString();
    String topStack = stackTrace.split("#1")[1].split("#2")[0];

    _getAppInfo();

    var msg = "[INFO ][${DateTime.now()}][${topStack.substring(0, topStack.indexOf(")")).trim()}] $log";
    logList.add(msg);
    while(logList.length > 1000){
      logList.removeAt(logList.length - 1);
    }
    //print(msg);
    developer.log(msg,
        name: _applicationName,
    );
  }

  /// デバッグログを出力する
  static debug(String log){
    if(kReleaseMode){
      return;
    }
    String stackTrace = StackTrace.current.toString();
    String topStack = stackTrace.split("#1")[1].split("#2")[0];

    _getAppInfo();

    var msg = "[DEBUG][${DateTime.now()}][${topStack.substring(0, topStack.indexOf(")")).trim()}] $log";
    logList.add(msg);
    while(logList.length > 1000){
      logList.removeAt(logList.length - 1);
    }
    //print(msg);
    developer.log(msg,
      name: _applicationName,
    );
  }

  /// 警告ログを出力する
  static warn(String log){
    String stackTrace = StackTrace.current.toString();
    String topStack = stackTrace.split("#1")[1].split("#2")[0];

    _getAppInfo();

    var msg = "[WARN ][${DateTime.now()}][${topStack.substring(0, topStack.indexOf(")")).trim()}] $log";
    logList.add(msg);
    while(logList.length > 1000){
      logList.removeAt(logList.length - 1);
    }
    //print(msg);
    developer.log(msg,
        name: _applicationName,
    );
  }

  /// エラーログを出力する
  static error(String log, {Object? exception}){
    String stackTrace = StackTrace.current.toString();
    String topStack = stackTrace.split("#1")[1].split("#2")[0];

    _getAppInfo();

    //print("[${DateTime.now()}][${topStack.substring(0, topStack.indexOf(")")).trim()}][ERROR] $log");

    var msg = "[ERROR][${DateTime.now()}][${topStack.substring(0, topStack.indexOf(")")).trim()}] $log";
    logList.add(msg);
    while(logList.length > 1000){
      logList.removeAt(logList.length - 1);
    }

    if(null != exception){
      developer.log("$msg\n${exception.toString()}",
        name: _applicationName,
        error: exception,
        stackTrace: StackTrace.current,
      );

    }else{
      developer.log(msg,
        name: _applicationName,
        stackTrace: StackTrace.current,
      );
    }
  }
}