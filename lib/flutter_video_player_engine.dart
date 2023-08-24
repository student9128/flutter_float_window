import 'package:flutter_float_window/flutter_video_player_event_handler.dart';

class FlutterVideoPlayerEngine{
  FlutterVideoPlayerEngine._();
  static FlutterVideoPlayerEngine? _instance;
  static FlutterVideoPlayerEngine get instance =>_getInstance();
  static FlutterVideoPlayerEngine _getInstance(){
    _instance??= FlutterVideoPlayerEngine._();
    return _instance!;
  }
  static FlutterVideoPlayerEngine create() {
    _instance??= FlutterVideoPlayerEngine._();
    return _instance!;
  }

  FlutterVideoPlayerEventHandler? mHandler;
  void setVideoPlayerEventHandler(FlutterVideoPlayerEventHandler handler) {
    mHandler = handler;
  }
}