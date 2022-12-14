# flutter_float_window

A Flutter plugin for Android show float window about video & agora Live.

## How to use

> if you have the permission show float window

```
Map<String, String> params = {"videoUrl":''};
FlutterFloatWindow.initFloatWindow(params);

FlutterFloatWindow.showFloatWindow();

FlutterFloatWindow.hideFloatWindow();

FlutterFloatWindow.play();

FlutterFloatWindow.pause();

FlutterFloatWindow.stop();

```

> if you have no permission show flot window

```
if (await FlutterFloatWindow.canShowFloatWindow()) {
    FlutterFloatWindow.showFloatWindow();
} else {
    FlutterFloatWindow.openSetting();
}
```

> setVideoUrl

```
Map<String, String> params = {"videoUrl":""};
FlutterFloatWindow.setVideoUrl(params);
```

> isPlayWhenScreenOff

```
FlutterFloatWindow.isPlayWhenScreenOff(true);

```

> some native actions send to flutter

```
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

```
FlutterFloatWindow.setBackgroundColor("#5c3317");
```

> setGravity

```
 FlutterFloatWindow.setGravity(FloatWindowGravity.CENTER);
```
> setWidthAndHeight
```
var map = {
"width": int.parse(width),
"height": int.parse(height)};
FlutterFloatWindow.setWidthAndHeight(map);
```
> setAspectRatio
```
 FlutterFloatWindow.setAspectRatio(0.7);
```
> live float window
```
///init and show live float window
await FlutterFloatWindow.initFloatLive(_mAppId,_token, _channelName, _mOptionalUid);

///hide live float window and leave channel
FlutterFloatWindow.leaveChannel();
```