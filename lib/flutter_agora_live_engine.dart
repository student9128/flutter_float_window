import 'package:flutter_float_window/flutter_agora_live_event_handler.dart';

class FlutterAgoraLiveEngine {
  FlutterAgoraLiveEngine._();
  static FlutterAgoraLiveEngine? _instance;
  static FlutterAgoraLiveEngine get instance => _getInstance();
  static FlutterAgoraLiveEngine _getInstance() {
    _instance ??= FlutterAgoraLiveEngine._();
    return _instance!;
  }

  static FlutterAgoraLiveEngine create() {
    _instance ??= FlutterAgoraLiveEngine._();
    return _instance!;
  }

  FlutterAgoraLiveEventHandler? mHandler;
  ///设置直播间相关方法监听
  void setAgoraLiveEventHandler(FlutterAgoraLiveEventHandler handler) {
    mHandler = handler;
  }
}
