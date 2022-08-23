import 'dart:ui';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_float_window/flutter_float_window.dart';

void main() {
  runApp(const MaterialApp(home: MyApp(),));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  String _platformVersion = 'Unknown';
  late TextEditingController _widthController;
  late TextEditingController _heightController;
  late TextEditingController _aspectRatioController;
  late TextEditingController _gravityController;
  int count = 0;
  int colorIndex = 0;

  @override
  void initState() {
    WidgetsBinding.instance?.addObserver(this);
    super.initState();
    initPlatformState();
    initFloatListener();
    _widthController = TextEditingController()..addListener(() {});
    _heightController = TextEditingController()..addListener(() {});
    _aspectRatioController = TextEditingController()..addListener(() {});
    _gravityController = TextEditingController()..addListener(() {});
  }

  initFloatListener() async {
    var channel = FlutterFloatWindow.channel;
    channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case "onFullScreenClick":
          debugPrint('onFullScreenClick');
          FlutterFloatWindow.launchApp();
          break;
        case "onCloseClick":
          debugPrint('onCloseClick');
          break;
        case "onPlayClick":
          debugPrint('onPlayClick,${call.arguments}');
          break;
      }
    });
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
        // FlutterFloatWindow.showFloatWindowWithInit(params);
        break;
      case AppLifecycleState.resumed:
        // FlutterFloatWindow.hideFloatWindow();
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
    var fW=MediaQuery.of(context).size.width;
    var fH=MediaQuery.of(context).size.height;
    debugPrint('fw=$fW,fh=$fH,${window.devicePixelRatio}');
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Wrap(
          spacing: 10,
          children: [
            Center(
              child: Text('Running on: $_platformVersion\n'),
            ),
            ElevatedButton(
                onPressed: () {
                  Map<String, dynamic> params = {"position": 5000};
                  FlutterFloatWindow.seekTo(params);
                },
                child: const Text("test seekTo")),
            ElevatedButton(
                onPressed: () {
                  Map<String, String> params = {
                    "videoUrl":
                        'http://vfx.mtime.cn/Video/2019/03/18/mp4/190318231014076505.mp4'
                  };
                  FlutterFloatWindow.initFloatWindow(params);
                },
                child: const Text("init")),
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
                    debugPrint('no permission showing float window');
                    FlutterFloatWindow.openSetting();
                  }
                },
                child: const Text("show")),
            ElevatedButton(
                onPressed: () async {
                  var x = await FlutterFloatWindow.hideFloatWindow();
                  debugPrint('current position=$x');
                },
                child: const Text("hide")),
            ElevatedButton(
                onPressed: () {
                  Map<String, String> params = {
                    "videoUrl":
                        'http://vfx.mtime.cn/Video/2019/03/19/mp4/190319212559089721.mp4'
                  };
                  FlutterFloatWindow.setVideoUrl(params);
                },
                child: const Text("set url2")),
            ElevatedButton(
                onPressed: () {
                  Map<String, String> params = {
                    "videoUrl":
                        'https://media.w3.org/2010/05/sintel/trailer.mp4'
                  };
                  FlutterFloatWindow.setVideoUrl(params);
                },
                child: const Text("set url")),
            ElevatedButton(
                onPressed: () {
                  Map<String, String> params = {"position": '1000'};
                  FlutterFloatWindow.setVideoUrl(params);
                },
                child: const Text("video play with position")),
            ElevatedButton(
                onPressed: () {
                  FlutterFloatWindow.play();
                },
                child: const Text("play")),
            ElevatedButton(
                onPressed: () {
                  FlutterFloatWindow.pause();
                },
                child: const Text("pause")),
            ElevatedButton(
                onPressed: () {
                  FlutterFloatWindow.stop();
                },
                child: const Text("stop")),
            ElevatedButton(
                onPressed: () {
                  FlutterFloatWindow.isPlayWhenScreenOff(true);
                },
                child: const Text("isPlayWhenScreenOff-true")),
            ElevatedButton(
                onPressed: () {
                  FlutterFloatWindow.isPlayWhenScreenOff(false);
                },
                child: const Text("isPlayWhenScreenOff-false")),
            ElevatedButton(
                onPressed: () {
                  FlutterFloatWindow.isPlayWhenScreenOff(false);
                },
                child: const Text("canWriteSettings")),
            ElevatedButton(
                onPressed: () {
                  FlutterFloatWindow.isPlayWhenScreenOff(false);
                },
                child: const Text("getScreenOffTimeout")),
            ElevatedButton(
                onPressed: () {
                  FlutterFloatWindow.isPlayWhenScreenOff(false);
                },
                child: const Text("setScreenOnForever")),
            ElevatedButton(
                onPressed: () {
                  FlutterFloatWindow.isPlayWhenScreenOff(false);
                },
                child: const Text("setScreenOffTimeout")),
            Column(
              children: [
                TextField(
                  controller: _widthController,
                ),
                TextField(
                  controller: _heightController,
                ),
                ElevatedButton(
                    onPressed: () {
                      var width = _widthController.text.toString();
                      var height = _heightController.text.toString();
                      var map = {
                        "width": int.parse(width),
                        "height": int.parse(height)
                      };
                      FlutterFloatWindow.setWidthAndHeight(map);
                    },
                    child: const Text("setWidthAndHeight")),
              ],
            ),
            Column(
              children: [
                TextField(
                  controller: _aspectRatioController,
                ),
                ElevatedButton(
                    onPressed: () {
                      FlutterFloatWindow.setAspectRatio(0.7);
                    },
                    child: const Text("setAspectRatio")),
              ],
            ),
            ElevatedButton(
                onPressed: () {
                  ++count;
                  switch (count % 5) {
                    case 1:
                      FlutterFloatWindow.setGravity(FloatWindowGravity.LEFT);
                      break;
                    case 2:
                      FlutterFloatWindow.setGravity(FloatWindowGravity.TOP);
                      break;
                    case 3:
                      FlutterFloatWindow.setGravity(FloatWindowGravity.RIGHT);
                      break;
                    case 4:
                      FlutterFloatWindow.setGravity(FloatWindowGravity.BOTTOM);
                      break;
                    case 0:
                      FlutterFloatWindow.setGravity(FloatWindowGravity.CENTER);
                      break;
                  }
                },
                child: const Text("setGravity")),
            ElevatedButton(
                onPressed: () {
                  ++colorIndex;
                  switch (colorIndex % 4) {
                    case 1:
                      FlutterFloatWindow.setBackgroundColor("#009633");
                      break;
                    case 2:
                      FlutterFloatWindow.setBackgroundColor("#ffff00");
                      break;
                    case 3:
                      FlutterFloatWindow.setBackgroundColor("#5c3317");
                      break;
                    case 0:
                      FlutterFloatWindow.setBackgroundColor("#00000000");
                      break;
                  }
                },
                child: const Text("setBackgroundColor")),
          ],
        ),
      ),
    );
  }
}
