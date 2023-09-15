# flutter_float_window

A Flutter plugin show float window on Android and show picture in picture on iOS.

## How to use

> if you have the permission show float window

```dart
Map<String, String> params = {"videoUrl":''};
FlutterFloatWindow.initFloatWindow(params);

FlutterFloatWindow.showFloatWindow();

FlutterFloatWindow.hideFloatWindow();

FlutterFloatWindow.play();

FlutterFloatWindow.pause();

FlutterFloatWindow.stop();

```

> if you have no permission show flot window

```dart
if (await FlutterFloatWindow.canShowFloatWindow()) {
    FlutterFloatWindow.showFloatWindow();
} else {
    FlutterFloatWindow.openSetting();
}
```

> setVideoUrl

```dart
Map<String, String> params = {"videoUrl":""};
FlutterFloatWindow.setVideoUrl(params);
```

> isPlayWhenScreenOff

```dart 
FlutterFloatWindow.isPlayWhenScreenOff(true);

```

> some native actions send to flutter

```dart
 var channel = FlutterFloatWindow.channel;
    channel.setMethodCallHandler((call) async{
      switch (call.method) {
        case "onFullScreenClick":
          debugPrint('onFullScreenClick');
          break;
        case "onCloseClick":
          debugPrint('onCloseClick');
         break;
        case "onPlayClick":
          debugPrint('onPlayClick,${call.arguments}');
          break;
      }
    });

```

> setBackgroundColor

```dart
FlutterFloatWindow.setBackgroundColor("#5c3317");
```

> setGravity

```dart
 FlutterFloatWindow.setGravity(FloatWindowGravity.CENTER);
```
> setWidthAndHeight
```dart
var map = {
"width": int.parse(width),
"height": int.parse(height)};
FlutterFloatWindow.setWidthAndHeight(map);
```
> setAspectRatio
```dart
 FlutterFloatWindow.setAspectRatio(0.7);
```
> live float window
```dart
///init and show live float window
await FlutterFloatWindow.initFloatLive(_mAppId,_token, _channelName, _mOptionalUid);

///hide live float window and leave channel
FlutterFloatWindow.leaveChannel();
```
## for iOS

```dart
//video player
FlutterVideoPlayerView()

//agora
FlutterAgoraLiveView()
```
> init video player
```dart
  FlutterFloatWindow.initVideoPlayerIOS(
          url: dataSource,
          title: title,
          artist: artist,
          coverUrl: cover,
          position: 0,
          speed: 1.0);
      FlutterVideoPlayerEngine playerEngine = FlutterVideoPlayerEngine.create();
      playerEngine.setVideoPlayerEventHandler(FlutterVideoPlayerEventHandler(
          onInitialized: () {
      }, onVideoProgress: (double position, double duration,
              double bufferedStart, double bufferedEnd) {
      }, onVideoPlayPaused: () {
      }, onVideoPlayEnd: () {
      }, onVideoInterruptionBegan: () {
      }, onVideoInterruptionEnded: () {
      }, onVideoPipCloseClicked: (){
      }, onVideoPipFullScreenClicked:(){}));
      FlutterFloatWindow.initVideoPlayerListener(playerEngine.mHandler!);
```
> init agora
```dart
  FlutterAgoraLiveEngine live = FlutterAgoraLiveEngine.create();
      live.setAgoraLiveEventHandler(FlutterAgoraLiveEventHandler(
          onConnectionChanged: (state, reason) {
          },onJoinChannelSuccess: (uid) {
          },onUserJoined: (uid) {
          },onUserOffline: (uid, reason) {
          },onFirstRemoteVideoFrame: (uid) { 
          },onFirstRemoteVideoDecoded: (uid) {
          },onRemoteVideoMuted: (uid) {
          },onRemoteVideoStateChanged: (uid) {
          },onLeaveChannel: () {
          },onLivePipCloseClicked:(){
          },onLivePipFullScreenClicked:(){}));
      FlutterFloatWindow.initAgora(_, _, _, _,title:title, artist: artist, coverUrl:cover);
```
> use picture in picture

```dart
FlutterFloatWindow.startPipIOS();
FlutterFloatWindow.stopPipIOS();

FlutterFloatWindow.startPipVideoIOS();
FlutterFloatWindow.stopPipVideoIOS();
```