# flutter_float_window

A Flutter plugin for Android show float window.

## How to use

> if you have the permission show float window

```
FlutterFloatWindow.showFloatWindow();

FlutterFloatWindow.hideFloatWindow();

```
> if you have no permission show flot window

```
   if (await FlutterFloatWindow.canShowFloatWindow()) {
                    FlutterFloatWindow.showFloatWindow();
                  } else {
                    FlutterFloatWindow.openSetting();
                  }
```

> setVieoUrl

```
    Map<String, String> params = {
                    "videoUrl":""
                  };
                  FlutterFloatWindow.setVideoUrl(params);
```
