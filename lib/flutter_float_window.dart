import 'dart:async';

import 'package:flutter/services.dart';

class FlutterFloatWindow {
  static const MethodChannel _channel = MethodChannel('flutter_float_window');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static showFloatWindow() async {
    await _channel.invokeMethod('showFloatWindow');
  }

  static hideFloatWindow() async {
    await _channel.invokeMethod('hideFloatWindow');
  }
}
