import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_float_window/flutter_agora_constants.dart';
import 'package:flutter_float_window/flutter_agora_live_event_handler.dart';
import 'package:flutter_float_window/flutter_agora_live_engine.dart';
import 'package:flutter_float_window/flutter_video_player_constants.dart';
import 'package:flutter_float_window/flutter_video_player_event_handler.dart';
export 'package:flutter_float_window/flutter_agora_live_event_handler.dart';
export 'package:flutter_float_window/flutter_agora_live_engine.dart';
export 'package:flutter_float_window/flutter_agora_constants.dart';
export 'package:flutter_float_window/flutter_video_player_engine.dart';
export 'package:flutter_float_window/flutter_video_player_progress_bar_colors.dart';
export 'package:flutter_float_window/flutter_video_player_progress_bar.dart';

enum FloatWindowGravity {
  ///left
  left,

  ///top
  top,

  ///right
  right,

  ///bottom
  bottom,

  ///center
  center,

  ///top and left
  topLeft,

  ///top and right
  topRight,

  ///bottom and right
  bottomRight,

  ///bottom and left
  bottomLeft
}

class FlutterFloatWindow {
  static const MethodChannel _channel = MethodChannel('flutter_float_window');
  static const EventChannel _eventChannel =
  EventChannel('flutter_agora_live/events');

  static MethodChannel get channel => _channel;

  static EventChannel get eventChannel => _eventChannel;

  static const MethodChannel _channelAgoraIOS =
  MethodChannel('flutter_agora_live');

  static MethodChannel get channelAgoraIOS => _channelAgoraIOS;
  static const MethodChannel _channelVideoPlayerIOS =
  MethodChannel('flutter_video_player');

  static MethodChannel get channelVideoPlayerIOS => _channelVideoPlayerIOS;

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
  static launchApp() async {
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

  ///设置宽高
  static setWidthAndHeight(dynamic map) async {
    await _channel.invokeMethod('setWidthAndHeight', map);
  }

  ///设置高宽比
  ///0.0~1.0,不能等于0
  static setAspectRatio(double aspectRatio) async {
    assert(aspectRatio > 0.0);
    await _channel.invokeMethod('setAspectRatio', aspectRatio);
  }

  ///设置位置
  static setGravity(FloatWindowGravity gravity, {isLive = false}) async {
    switch (gravity) {
      case FloatWindowGravity.left:
        Map<String, dynamic> params = {'gravity': "left", 'isLive': isLive};
        await _channel.invokeMethod('setGravity', params);
        break;
      case FloatWindowGravity.top:
        Map<String, dynamic> params = {'gravity': "top", 'isLive': isLive};
        await _channel.invokeMethod('setGravity', params);
        break;
      case FloatWindowGravity.right:
        Map<String, dynamic> params = {'gravity': "right", 'isLive': isLive};
        await _channel.invokeMethod('setGravity', params);
        break;
      case FloatWindowGravity.bottom:
        Map<String, dynamic> params = {'gravity': "bottom", 'isLive': isLive};
        await _channel.invokeMethod('setGravity', params);
        break;
      case FloatWindowGravity.center:
        Map<String, dynamic> params = {'gravity': "center", 'isLive': isLive};
        await _channel.invokeMethod('setGravity', params);
        break;
      case FloatWindowGravity.topLeft:
        Map<String, dynamic> params = {'gravity': "tl", 'isLive': isLive};
        await _channel.invokeMethod('setGravity', params);
        break;
      case FloatWindowGravity.topRight:
        Map<String, dynamic> params = {'gravity': "tr", 'isLive': isLive};
        await _channel.invokeMethod('setGravity', params);
        break;
      case FloatWindowGravity.bottomLeft:
        Map<String, dynamic> params = {'gravity': "bl", 'isLive': isLive};
        await _channel.invokeMethod('setGravity', params);
        break;
      case FloatWindowGravity.bottomRight:
        Map<String, dynamic> params = {'gravity': "br", 'isLive': isLive};
        await _channel.invokeMethod('setGravity', params);
        break;
    }
  }

  ///设置背景色
  static setBackgroundColor(String color) async {
    if (!color.startsWith("#")) {
      assert(color.length >= 6 && color.length <= 8);
      color = "#$color";
    } else {
      assert(color.length >= 7 && color.length <= 9);
    }
    await _channel.invokeMethod('setBackgroundColor', color);
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

  ///设置视频播放速度
  static setPlaybackSpeed(double speed) async {
    Map<String, double> params = {'speed': speed};
    await _channel.invokeMethod("setPlaybackSpeed", params);
  }

  ///快进或者快退的时间间隔，以毫秒为单位
  static setFastForwardMillisecond(int millisecond) async {
    Map<String, int> params = {'fastForwardMillisecond': millisecond};
    await _channel.invokeMethod('setFastForwardMillisecond', params);
  }

  /// agora SDK appId
  static Future<String> initFloatLive(String appId, String token,
      String channelName, int optionalUid) async {
    Map<String, dynamic> params = {
      'appId': appId,
      'token': token,
      'channelName': channelName,
      'optionalUid': optionalUid
    };
    return await _channel.invokeMethod('initFloatLive', params);
  }

  /// join channel
  static Future<String> joinChannel(String token, String channelName,
      int optionalUid) async {
    Map<String, dynamic> params = {
      'token': token,
      'channelName': channelName,
      'optionalUid': optionalUid
    };
    return await _channel.invokeMethod('joinChannel', params);
  }

  /// leave channel
  static Future<String> leaveChannel() async {
    return await _channel.invokeMethod('leaveChannel');
  }

  /// is show live float window
  static isLive(bool isLive) async {
    Map<String, bool> params = {'isLive': isLive};
    await _channel.invokeMethod("isLive", params);
  }

  ///* channelId:  Notification channel id
  ///* channelName:  Notification channel name
  static setNotificationChannelIdAndName(String channelId,
      String channelName) async {
    Map<String, String> params = {
      "channelId": channelId,
      "channelName": channelName
    };
    await _channel.invokeMethod("setNotificationChannelIdAndName", params);
  }

  /// 判断设备是否对app开启通知权限
  ///
  static Future<bool> canShowNotification() async {
    return await _channel.invokeMethod("canShowNotification");
  }

  /// 去设置页面
  static goSettingNotificationPage() async {
    await _channel.invokeMethod("goSettingPage");
  }

  static showPlaybackNotification(String title, String content) async {
    Map<String, String> params = {"title": title, "content": content};
    await _channel.invokeMethod('showPlaybackNotification', params);
  }

  static showLiveNotification(String title, String content) async {
    Map<String, String> params = {"title": title, "content": content};
    await _channel.invokeMethod('showLiveNotification', params);
  }

  /// only iOS
  static initAgora(String appId, String token, String channelName,
      int optionalUid,
      {String title = '', String artist = '', String coverUrl = ''}) async {
    Map<String, dynamic> params = {
      'appId': appId,
      'token': token,
      'channelName': channelName,
      'optionalUid': optionalUid,
      'title': title,
      'artist': artist,
      'coverUrl': coverUrl
    };
    var handler = FlutterAgoraLiveEngine.instance.mHandler;
    EventChannel _eventChannel =
    const EventChannel("flutter_agora_live/agora_events");
    _eventChannel.receiveBroadcastStream().listen((event) {
      var map = Map<String, dynamic>.from(event);
      handleAgoraEvent(map, handler);
    });
    return await _channelAgoraIOS.invokeMethod('initAgora', params);
  }

  static destroyAgora() async {
    await _channelAgoraIOS.invokeMethod("destroyAgora");
  }

  static enablePipIOS(bool enable) async {
    assert(Platform.isIOS == true);
    Map<String, dynamic> params = {
      'enablePipIOS': enable,
    };
    await _channelAgoraIOS.invokeMethod('enablePipIOS', params);
  }

  static initPipIOS() async {
    await _channelAgoraIOS.invokeMethod('initPipIOS');
  }

  static startPipIOS() async {
    await _channelAgoraIOS.invokeMethod('startPipIOS');
  }

  static stopPipIOS() async {
    await _channelAgoraIOS.invokeMethod('stopPipIOS');
  }

  static mutedRemoteAudio(bool mute) async {
    Map<String, dynamic> params = {
      'mutedRemoteAudio': mute,
    };
    await _channelAgoraIOS.invokeMethod("mutedRemoteAudio", params);
  }

  static showNowPlaying(
      {String title = '', String artist = '', String coverUrl = ''}) async {
    assert(Platform.isIOS == true);
    Map<String, dynamic> params = {
      'title': title,
      'artist': artist,
      'coverUrl': coverUrl
    };
    await _channelAgoraIOS.invokeMethod('showNowPlaying', params);
  }

  static handleAgoraEvent(Map<String, dynamic> event,
      FlutterAgoraLiveEventHandler? handler) {
    var method = event['method'];
    int uid = event['uid'] ?? -1;
    switch (method) {
      case FlutterAgoraConstants.onError:
        handler?.onError?.call(event['error']);
        break;
      case FlutterAgoraConstants.onConnectionChanged:
        handler?.onConnectionChanged?.call(event['state'], event['reason']);
        break;
      case FlutterAgoraConstants.onJoinChannelSuccess:
        handler?.onJoinChannelSuccess?.call(uid);
        break;
      case FlutterAgoraConstants.onLeaveChannel:
        handler?.onLeaveChannel;
        break;
      case FlutterAgoraConstants.onUserJoined:
        handler?.onUserJoined?.call(uid);
        break;
      case FlutterAgoraConstants.onUserOffline:
        handler?.onUserOffline?.call(uid, event['reason'] ?? -1);
        break;
      case FlutterAgoraConstants.onFirstRemoteVideoFrame:
        handler?.onFirstRemoteVideoFrame?.call(uid);
        break;
      case FlutterAgoraConstants.onFirstRemoteVideoDecoded:
        handler?.onFirstRemoteVideoDecoded?.call(uid);
        break;
      case FlutterAgoraConstants.onRemoteVideoStateChanged:
        handler?.onRemoteVideoStateChanged?.call(uid);
        break;
      case FlutterAgoraConstants.onRemoteVideoMuted:
        handler?.onRemoteVideoMuted?.call(uid);
        break;
      default:
    }
  }

  static initVideoPlayerIOS({required String url,
    String title = '',
    String artist = "",
    String coverUrl = "",
    int position = 0,
    double speed = 1.0}) async {
    assert(Platform.isIOS == true);
    Map<String, dynamic> params = {
      "videoUrl": url,
      "title": title,
      "artist": artist,
      "coverUrl": coverUrl,
      "position": position,
      "speed": speed
    };
    await _channelVideoPlayerIOS.invokeMethod("initVideoPlayerIOS", params);
  }

  ///播放
  static playVideoIOS() async {
    assert(Platform.isIOS == true);
    await _channelVideoPlayerIOS.invokeMethod('playVideoIOS');
  }

  ///暂停
  static pauseVideoIOS() async {
    assert(Platform.isIOS == true);
    await _channelVideoPlayerIOS.invokeMethod('pauseVideoIOS');
  }

  static destroyVideoPlayerIOS() async {
    assert(Platform.isIOS == true);
    await _channelVideoPlayerIOS.invokeMethod('destroyVideoPlayerIOS');
  }

  static seekVideoIOS(Map<String, int> position) async {
    assert(Platform.isIOS == true);
    await _channelVideoPlayerIOS.invokeMethod('seekVideoIOS', position);
  }

  static enablePipVideoIOS(bool enable) async {
    assert(Platform.isIOS == true);
    Map<String, dynamic> params = {
      'enablePipIOS': enable,
    };
    await _channelVideoPlayerIOS.invokeMethod('enablePipVideoIOS', params);
  }

  static startPipVideoIOS() async {
    assert(Platform.isIOS == true);
    await _channelVideoPlayerIOS.invokeMethod('startPipVideoIOS');
  }

  static stopPipVideoIOS() async {
    assert(Platform.isIOS == true);
    await _channelVideoPlayerIOS.invokeMethod('stopPipVideoIOS');
  }

  static Future<Map<String, dynamic>> getDurationAndPosition() async {
    assert(Platform.isIOS == true);
    var future =
    await _channelVideoPlayerIOS.invokeMethod('durationAndPosition');
    var map = {'position': future['position'], 'duration': future['duration']};
    return map;
  }

  static Future<bool> isPlaying() async {
    assert(Platform.isIOS == true);
    return await _channelVideoPlayerIOS.invokeMethod("isVideoPlayingIOS");
  }

  static initVideoPlayerListener(FlutterVideoPlayerEventHandler handler) {
    // var handler = FlutterVideoPlayerEngine.instance.mHandler;
    EventChannel _eventChannel =
    const EventChannel("flutter_video_player/video_events");
    _eventChannel.receiveBroadcastStream().listen((event) {
      var map = Map<String, dynamic>.from(event);
      // var method = map['method'];
      // if (method == 'onVideoProgress') {
      //   var position = map['position'];
      //   var duration = map['duration'];
      //   var start = map['bufferedStart'];
      //   var end = map['bufferedEnd'];
      //   handler?.onVideoProgress?.call(position, duration, start, end);
      // }
      handleVideoPlayerEvent(map, handler);
    });
  }

  static handleVideoPlayerEvent(Map<String, dynamic> event,
      FlutterVideoPlayerEventHandler? handler) {
    var method = event['method'];
    switch (method) {
      case FlutterVideoPlayerConstants.onInitialized:
        handler?.onInitialized?.call();
        break;
      case FlutterVideoPlayerConstants.onVideoProgress:
        var position = event['position'];
        var duration = event['duration'];
        var start = event['bufferedStart'];
        var end = event['bufferedEnd'];
        handler?.onVideoProgress?.call(position, duration, start, end);
        break;
    }
  }
}
