import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_float_window/flutter_float_window.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  String _platformVersion = 'Unknown';

  @override
  void initState() {
    WidgetsBinding.instance?.addObserver(this);
    super.initState();
    initPlatformState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        Map<String, String> params = {
          "videoUrl":
          'http://vfx.mtime.cn/Video/2019/03/18/mp4/190318231014076505.mp4'
        };
        FlutterFloatWindow.showFloatWindowWithInit(params);
        break;
      case AppLifecycleState.resumed:
        FlutterFloatWindow.hideFloatWindow();
        break;
      default:
    }
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion = await FlutterFloatWindow.platformVersion ??
          'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Column(
          children: [
            Center(
              child: Text('Running on: $_platformVersion\n'),
            ),
            ElevatedButton(
                onPressed: () {
                  Map<String, dynamic> params = {
                    "position":5000
                  };
                  FlutterFloatWindow.seekTo(params);
                },
                child: Text("测试seekTo")),
            ElevatedButton(
                onPressed: () {
                  Map<String, String> params = {
                    "videoUrl":
                        'https://live.idbhost.com/c7adf405ec28401f97977b83d62b79ca/2768b635d70f4c6ea968f18260fed746-deef987b58a54db78d0a11ef637f487f-sd.mp4'
                  };
                  FlutterFloatWindow.initFloatWindow(params);
                },
                child: Text("init")),
            ElevatedButton(
                onPressed: () async {
                  // Map<String, String> params = {
                  //   "videoUrl":
                  //   'http://vfx.mtime.cn/Video/2019/03/18/mp4/190318231014076505.mp4'
                  // };
                  // if(FlutterFloatWindow.)
                  if (await FlutterFloatWindow.canShowFloatWindow()) {
                    FlutterFloatWindow.showFloatWindow();
                  } else {
                    debugPrint('没有悬浮窗权限');
                    FlutterFloatWindow.openSetting();
                  }
                },
                child: Text("show")),
            ElevatedButton(
                onPressed: () async{
               var x =  await FlutterFloatWindow.hideFloatWindow();
               debugPrint('current position=$x');
                },
                child: Text("hide")),
            ElevatedButton(
                onPressed: () {
                  Map<String, String> params = {
                    "videoUrl":
                        'http://vfx.mtime.cn/Video/2019/03/19/mp4/190319212559089721.mp4'
                  };
                  FlutterFloatWindow.setVideoUrl(params);
                },
                child: Text("设置url2")),
            ElevatedButton(
                onPressed: () {
                  Map<String, String> params = {
                    "videoUrl":
                        'https://media.w3.org/2010/05/sintel/trailer.mp4'
                  };
                  FlutterFloatWindow.setVideoUrl(params);
                },
                child: Text("设置url")),
            ElevatedButton(
                onPressed: () {
                  Map<String, String> params = {
                    "position":
                    '1000'
                  };
                  FlutterFloatWindow.setVideoUrl(params);
                },
                child: Text("视频播放带位置")),
            ElevatedButton(
                onPressed: () {
                  FlutterFloatWindow.play();
                },
                child: Text("播放")),
            ElevatedButton(
                onPressed: () {
                  FlutterFloatWindow.pause();
                },
                child: Text("暂停")),
            ElevatedButton(
                onPressed: () {
                  FlutterFloatWindow.stop();
                },
                child: Text("停止播放"))
          ],
        ),
      ),
    );
  }
}
