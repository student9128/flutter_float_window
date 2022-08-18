import 'dart:async';

import 'package:flutter/services.dart';

class FlutterFloatWindow {
  static const MethodChannel _channel = MethodChannel('flutter_float_window');
  static MethodChannel get channel=>_channel;

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  ///获取屏幕锁屏时间
  ///
  ///如果在改时间内，没有对手机进行操作，手机会进行锁屏休眠
  static Future<int> getScreenOffTimeout() async {
    return await _channel.invokeMethod('getScreenOffTimeout');
  }

  ///设置屏幕锁屏所需时间
  static setScreenOffTimeout(int timeout) async {
    await _channel.invokeMethod("setScreenOffTimeout");
  }

  ///设置屏幕永久亮屏
  static setScreenOnForever() async {
    await _channel.invokeMethod("setScreenOnForever");
  }

  ///判断是否可以修改系统设置
  static Future<bool> canWriteSettings() async {
    return await _channel.invokeMethod('canWriteSettings');
  }

  ///判断是否具有悬浮窗权限
  static Future<bool> canShowFloatWindow() async {
    return await _channel.invokeMethod('canShowFloatWindow');
  }

  ///launch app
  static launchApp() async{
    await _channel.invokeMethod('launchApp');
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

  ///初始化并播放
  static showFloatWindowWithInit(dynamic url) async {
    await _channel.invokeMethod('showFloatWindow', url);
  }

  ///隐藏悬浮窗
  static Future<int> hideFloatWindow() async {
    return await _channel.invokeMethod('hideFloatWindow');
  }

  ///锁屏的时候是否播放
  static isPlayWhenScreenOff(bool b) async {
    return await _channel.invokeMethod('isPlayWhenScreenOff', b);
  }

  ///切换url
  static setVideoUrl(dynamic url) async {
    await _channel.invokeMethod('setVideoUrl', url);
  }

  ///播放
  static play() async {
    await _channel.invokeMethod('play');
  }

  ///暂停
  static pause() async {
    await _channel.invokeMethod('pause');
  }

  ///停止
  static stop() async {
    await _channel.invokeMethod('stop');
  }

  ///跳转到某个进度位置
  static seekTo(dynamic position) async {
    await _channel.invokeMethod('seekTo', position);
  }
}
