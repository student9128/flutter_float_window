import 'dart:async';

import 'package:flutter/services.dart';

class FlutterFloatWindow {
  static const MethodChannel _channel = MethodChannel('flutter_float_window');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  ///判断是否具有悬浮窗权限
  static Future<bool> canShowFloatWindow() async {
   return await _channel.invokeMethod('canShowFloatWindow');
  }

  ///打开设置页面
  static openSetting() async {
    await _channel.invokeMethod('openSetting');
  }

  ///初始化相关资源
  static initFloatWindow(dynamic url) async {
    await _channel.invokeMethod('initFloatWindow', url);
  }

  ///展示并播放
  static showFloatWindow() async {
    await _channel.invokeMethod('showFloatWindow');
  }

  static showFloatWindowWithInit(dynamic url) async {
    await _channel.invokeMethod('showFloatWindow',url);
  }

  static Future<int> hideFloatWindow() async {
   return await _channel.invokeMethod('hideFloatWindow');
  }
  ///锁屏的时候是否播放
  static isPlayWhenScreenOff(bool b) async{
    return await _channel.invokeMethod('isPlayWhenScreenOff',b);
  }

  ///切换url
  static setVideoUrl(dynamic url) async {
    await _channel.invokeMethod('setVideoUrl', url);
  }

  static play() async {
    await _channel.invokeMethod('play');
  }

  static pause() async {
    await _channel.invokeMethod('pause');
  }

  static stop() async {
    await _channel.invokeMethod('stop');
  }
  static seekTo(dynamic position) async{
    await _channel.invokeMethod('seekTo',position);
  }
}
