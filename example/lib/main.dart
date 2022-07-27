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
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
    initPlatformState();
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
                  Map<String, String> params = {
                    "videoUrl":
                    'http://vfx.mtime.cn/Video/2019/03/18/mp4/190318231014076505.mp4'
                  };
                  FlutterFloatWindow.showFloatWindow(params);
                },
                child: Text("show")),
            ElevatedButton(
                onPressed: () {
                  FlutterFloatWindow.hideFloatWindow();
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
                child: Text("设置url2")),   ElevatedButton(
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
