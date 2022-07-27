import 'dart:async';

import 'package:flutter/services.dart';

class FlutterFloatWindow {
  static const MethodChannel _channel = MethodChannel('flutter_float_window');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static showFloatWindow(dynamic url) async {
    await _channel.invokeMethod('showFloatWindow',url);
  }

  static hideFloatWindow() async {
    await _channel.invokeMethod('hideFloatWindow');
  }

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
}
