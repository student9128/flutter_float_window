import 'dart:math';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_float_window/flutter_float_window.dart';
import 'package:flutter_float_window/flutter_float_window_view.dart';
import 'package:flutter_float_window_example/test_page.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(const MaterialApp(
    home: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver,TickerProviderStateMixin {
  String _platformVersion = 'Unknown';
  late TextEditingController _widthController;
  late TextEditingController _heightController;
  late TextEditingController _aspectRatioController;
  late TextEditingController _gravityController;
  int count = 0;
  int colorIndex = 0;
  late OverlayEntry overlayEntry;
  late OverlayEntry overlayEntryX;
  late VideoPlayerController _controller;
  double scaleFactor = 1.0;
  late AnimationController _animationController;
  late Animation _animationScale;
  @override
  void initState() {
      _animationController = AnimationController(duration: Duration(milliseconds: 200), vsync: this);
      _animationScale =
          Tween(begin: 1.0, end: 0.5).animate(_animationController)..addListener(() {
            setState(() {
            });
            overlayEntryX.markNeedsBuild();
          });
      _animationController.addStatusListener((status) {
        // if(_animationController.isCompleted){
        //   _animationController.reverse();
        // }else{
        //   _animationController.forward();
        // }
      });
    WidgetsBinding.instance?.addObserver(this);
    WidgetsBinding.instance?.addPostFrameCallback((timeStamp) {
      overlayEntryX = OverlayEntry(builder: (context) {
        return  Positioned(
              left: 0,
              top: 80,
              // width: MediaQuery.of(context).size.width,
              // height: 100,
              child:AnimatedBuilder(
                animation: _animationController,
                builder: (context,child){
                  return Transform.scale(
                    scale: _animationScale.value,
                    child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: 320,
                      height: 180,
                      color: Colors.yellow,
                      child: FlutterFloatWindowView(
                        text: "我是flutter层12",
                      ),
                    ),
                  ),);
                },
              )
        );
      });
      overlayEntry = OverlayEntry(builder: (context) {
        debugPrint('hello');
        return IgnorePointer(
          child: Material(
            color: Colors.transparent,
            child:
                // color: Colors.red.withOpacity(0.5),
                ListView.builder(
                    itemExtent: 100,
                    itemCount: 10,
                    itemBuilder: (context, index) {
                      return buildRow();
                    }),
          ),
        );
        // return Positioned(
        //     right: 0,
        //     bottom: 0,
        //     width: 200,
        //     height: 200,
        //     child: GestureDetector(
        //         behavior: HitTestBehavior.translucent,
        //         child: Material(
        //             color: Colors.blue.withOpacity(0.1),
        //             child: Container(
        //               color: Colors.red.withOpacity(0.5),
        //               child: Text('hello'),
        //             ))));
      });
      Overlay.of(context)?.insert(overlayEntry);
    });
    super.initState();
    // initVideoPlayer();
    initFloatListener();
    _widthController = TextEditingController()..addListener(() {});
    _heightController = TextEditingController()..addListener(() {});
    _aspectRatioController = TextEditingController()..addListener(() {});
    _gravityController = TextEditingController()..addListener(() {});
  }

  initVideoPlayer() async {
    // _controller = VideoPlayerController.network(
    //     "https://live.idbhost.com/da211fc4238d421984788089b7263566/4e589f50870b471095aa86d07a25a83e-a9a4e5e6da87e733106f697c8ab0de98-sd.mp4");
    // await _controller.initialize();
    // _controller.play();
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
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
        print("inactive");
        // FlutterFloatWindow.showFloatWindow();
        break;
      case AppLifecycleState.paused:
        print("paused");
        Map<String, String> params = {
          "videoUrl":
              'https://live.idbhost.com/da211fc4238d421984788089b7263566/4e589f50870b471095aa86d07a25a83e-a9a4e5e6da87e733106f697c8ab0de98-sd.mp4'
          // 'http://vfx.mtime.cn/Video/2019/03/18/mp4/190318231014076505.mp4'
        };
        // FlutterFloatWindow.showFloatWindowWithInit(params);
        debugPrint("hello");
        // FlutterFloatWindow.showFloatWindow();
        break;
      case AppLifecycleState.resumed:
        print("resumed");
        // FlutterFloatWindow.hideFloatWindow();
        break;
      default:
    }
  }

  @override
  Widget build(BuildContext context) {
    var fW = MediaQuery.of(context).size.width;
    var fH = MediaQuery.of(context).size.height;
    debugPrint('fw=$fW,fh=$fH,${window.devicePixelRatio}');
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Plugin example app'),
          ),
          body: SingleChildScrollView(
            child: Container(
              margin: EdgeInsets.only(bottom: 30),
              child: Wrap(
                spacing: 10,
                children: [
                  // AspectRatio(
                  //   aspectRatio: 1.7 / 1,
                  //   child: VideoPlayer(_controller),
                  // ),
                  // Container(
                  //   width: 200,
                  //   height: 100,
                  //   child: FlutterFloatWindowView(text: "我是flutter层",),
                  // ),
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
                              'https://live.idbhost.com/da211fc4238d421984788089b7263566/4e589f50870b471095aa86d07a25a83e-a9a4e5e6da87e733106f697c8ab0de98-sd.mp4'
                          // 'http://vfx.mtime.cn/Video/2019/03/18/mp4/190318231014076505.mp4'
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
                            FlutterFloatWindow.setGravity(
                                FloatWindowGravity.LEFT);
                            break;
                          case 2:
                            FlutterFloatWindow.setGravity(
                                FloatWindowGravity.TOP);
                            break;
                          case 3:
                            FlutterFloatWindow.setGravity(
                                FloatWindowGravity.RIGHT);
                            break;
                          case 4:
                            FlutterFloatWindow.setGravity(
                                FloatWindowGravity.BOTTOM);
                            break;
                          case 0:
                            FlutterFloatWindow.setGravity(
                                FloatWindowGravity.CENTER);
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
                  ElevatedButton(
                      onPressed: () {
                        FlutterFloatWindow.setNotificationChannelIdAndName(
                            '234567', '画中画通知');
                        FlutterFloatWindow.showPlaybackNotification(
                            "qeubee", "你猜猜~~~~~");
                      },
                      child: Text('test Push')),
                  ElevatedButton(
                    onPressed: () {
                      Overlay.of(context)?.insert(overlayEntry);
                    },
                    child: Text('test overlay'),
                  ),
                  ElevatedButton(
                      onPressed: () {
                        overlayEntry.remove();
                      },
                      child: Text('remove overlay')),
                  ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(CupertinoPageRoute(
                            builder: (context) => TestPage()));
                      },
                      child: Text('go next')),
                  ElevatedButton(
                      onPressed: () {
                        FlutterFloatWindow.showFloatWindow();
                      },
                      child: Text('弹画中画')),
                  ElevatedButton(
                      onPressed: () {
                        Overlay.of(context).insert(overlayEntryX);
                      },
                      child: Text('添加overaly')),
                  ElevatedButton(
                      onPressed: () {
                        overlayEntryX.remove();
                      },
                      child: Text('移除overaly')),
                  ElevatedButton(
                      onPressed: () {
                       _animationController.forward();
                        // overlayEntryX.markNeedsBuild();
                      },
                      child: Text('缩放overlay操作')),      ElevatedButton(
                      onPressed: () {
                       _animationController.reverse();
                        // overlayEntryX.markNeedsBuild();
                      },
                      child: Text('缩放overlay操作返回')),
                ],
              ),
            ),
            // IgnorePointer(
            //          child: Material(
            //        color: Colors.transparent,
            //        child:
            //          // color: Colors.red.withOpacity(0.5),
            //         ListView.builder(
            //              itemExtent: 100,
            //              itemCount: 10,
            //              itemBuilder: (context, index) {
            //                return buildRow();
            //              }),
            //        ),
            //      )
          )),
    );
  }

  Transform buildRow() {
    return Transform.rotate(
        angle: -pi / 4,
        child: FittedBox(
          fit: BoxFit.none,
          child: Row(
            children: [
              Text(
                'hello\t\t\t\t\t',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 30,
                    color: Colors.grey.withOpacity(0.1)),
              ),
              Text(
                'hello\t\t\t\t\t',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 30,
                    color: Colors.grey.withOpacity(0.1)),
              ),
              Text(
                'hello\t\t\t\t\t',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 30,
                    color: Colors.grey.withOpacity(0.1)),
              ),
              Text(
                'hello\t\t\t\t\t',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 30,
                    color: Colors.grey.withOpacity(0.1)),
              )
            ],
          ),
        ));
  }
}
