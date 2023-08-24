import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_float_window/flutter_float_window.dart';
import 'package:flutter_float_window/flutter_float_window_view.dart';
import 'package:flutter_float_window_example/navigation_util.dart';
import 'package:flutter_float_window_example/test_flutter_video_view.dart';
import 'package:flutter_float_window_example/test_page.dart';

void main() {
  runApp(MaterialApp(
    home: MyApp(),
    navigatorObservers: [NavigationUtil.getInstance()],
    initialRoute: 'main',
    routes: NavigationUtil.configRoutes,
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  String _platformVersion = 'Unknown';
  late TextEditingController _widthController;
  late TextEditingController _heightController;
  late TextEditingController _aspectRatioController;
  late TextEditingController _gravityController;
  int count = 0;
  int colorIndex = 0;
  late OverlayEntry overlayEntry;
  late OverlayEntry overlayEntryX;
  double scaleFactor = 0.5;
  late AnimationController _animationController;
  late Animation _animationScale;
  bool isScaled = false;
  double x = 16;
  double y = 80;
  double hPadding = 16; //横轴边距
  double vPadding = 50; //竖轴边距
  String videoUrl = "https://media.w3.org/2010/05/sintel/trailer.mp4";
  String videoUrlMp4 = "http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4";
  var scaleAlignment = Alignment.topLeft;

  ///设计小窗大小：4/5*width
  ///
  _initFloatWindowMethodCallHandler() async {
    var channel = FlutterFloatWindow.channel;
    channel.setMethodCallHandler((call) async {
      debugPrint(
          '_initFloatWindowMethodCallHandler=======${call.method},=${call.arguments}');
      switch (call.method) {
        case "onFullScreenClick":
          // FlutterFloatWindow.pause();
          overlayEntryX.remove();
          Navigator.of(context)
              .push(CupertinoPageRoute(builder: (context) => TestPage()));
          break;
        case "onPictureInPictureWillStart":
          //在开始的时候修改app内的窗口为播放视频也的视频的位置，方便下次进来进入播放视频页面的位置
          x = 0;
          y = 80;
          overlayEntryX.markNeedsBuild();
          break;
        case "onCloseClick":
          //关闭的时候存储时间
          // FlutterFloatWindow.pause();
          overlayEntryX.remove();
          break;
        default:
          break;
      }
    });
      var videoChannel = FlutterFloatWindow.channelVideoPlayerIOS;
    videoChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onVideoCloseClick':
          FlutterFloatWindow.destroyVideoPlayerIOS();
          break;
        case 'onVideoFullScreenClick':
          List<String> routeNames = NavigationUtil.getInstance().routeNames;
          debugPrint("onVideoFullScreenClick=====${routeNames}");
          if (routeNames.last != 'testFlutterVideoView') {
            NavigationUtil.getInstance().pushPage(
                context, "testFlutterVideoView",
                widget: TestFlutterVideoViewPage(isFromPip: true,));
          }
          break;
      }
    });
  }

  @override
  void initState() {
    _animationController =
        AnimationController(duration: Duration(milliseconds: 200), vsync: this);
    _animationScale =
        Tween(begin: 1.0, end: scaleFactor).animate(_animationController)
          ..addListener(() {
            setState(() {});
            overlayEntryX.markNeedsBuild();
          });
    _animationController.addStatusListener((status) {
      if (_animationController.isCompleted) {
        // _animationController.reverse();
        setState(() {
          isScaled = true;
        });
      } else {
        setState(() {
          isScaled = false;
        });
        // _animationController.forward();
      }
    });
    WidgetsBinding.instance?.addObserver(this);
    if (Platform.isIOS) {
      WidgetsBinding.instance?.addPostFrameCallback((timeStamp) {
        _initFloatWindowMethodCallHandler();
        overlayEntryX = OverlayEntry(builder: (context) {
          var screenWidth = MediaQuery.of(context).size.width;
          var screenHeight = MediaQuery.of(context).size.height;
          return Positioned(
              left: x,
              top: y,
              child: GestureDetector(
                  onTap: () {},
                  onDoubleTap: () {
                    if (isScaled) {
                      _animationController.reverse();
                      setState(() {
                        isScaled = false;
                      });
                    } else {
                      _animationController.forward();
                      setState(() {
                        isScaled = true;
                      });
                    }
                  },
                  onPanUpdate: (DragUpdateDetails details) {
                    x += details.delta.dx;
                    y += details.delta.dy;
                    print("x=$x,y=$y");
                    overlayEntryX.markNeedsBuild();
                  },
                  onPanEnd: (DragEndDetails details) {
                    var originWidth = (MediaQuery.of(context).size.width - 32);
                    var originHeight = originWidth * 9 / 16;
                    var width =
                        isScaled ? originWidth * scaleFactor : originWidth;
                    var height = width * 9 / 16;
                    var centerX = x + width / 2;
                    var centerY = y + height / 2;
                    if (isScaled) {
                      if (scaleAlignment == Alignment.topLeft) {
                        centerX = x + width / 2;
                        centerY = y + height / 2;
                        print("走了这里 topLeft");
                      }
                      if (scaleAlignment == Alignment.topRight) {
                        //由于缩放后，x,y轴的位置数值不变，所以需要手动计算出在屏幕上的centerX,centerY作为temp判断在屏幕上的用户看到的位置
                        centerX =
                            x + width / 2 + screenWidth * (1 - scaleFactor);
                        centerY = y + height / 2;
                      }
                      if (scaleAlignment == Alignment.bottomLeft) {
                        //bottom的时候
                        //y轴坐标位置不变，处理坐标的时候，y值应该首先减去1.0时的y值大小 即(MediaQuery.of(context).size.width - 32)*9/16,然后再减去距离y轴的边距
                        centerX = x + width / 2;
                        centerY = y + height / 2;
                        print("走了这里 bottomLeft");
                      }
                      if (scaleAlignment == Alignment.bottomRight) {
                        centerX =
                            x + width / 2 + screenWidth * (1 - scaleFactor);
                        centerY = y + height / 2;
                      }
                    }
                      print(
                          "screenHeight=$screenHeight,y=$y,x=$x,alignment=$scaleAlignment,isScaled=$isScaled,centerX=$centerX,centerY=$centerY");
                      setState(() {
                        if (centerX < screenWidth / 2 &&
                            centerY < screenHeight / 2) {
                          scaleAlignment = Alignment.topLeft; //左上为基准
                          print('走了这里 左上为基准');
                          x = hPadding;
                          if (y <= vPadding) y = vPadding;
                        }
                        if (centerX < screenWidth / 2 &&
                            centerY > screenHeight / 2) {
                          print('走了这里 左下为基准');
                          scaleAlignment = Alignment.bottomLeft;
                          if (x <= hPadding) x = hPadding;
                          if (y > screenHeight - originHeight - vPadding) {
                            y = screenHeight - originHeight - vPadding;
                          }
                        }
                        if (centerX >= screenWidth / 2 &&
                            centerY < screenHeight / 2) {
                          scaleAlignment = Alignment.topRight; //右上为基准
                          print('走了这里 右上为基准');
                          x =isScaled? screenWidth * scaleFactor - width:screenWidth - width - hPadding;
                          if (y <= vPadding) y = vPadding;
                        }
                        if (centerX >= screenWidth / 2 &&
                            centerY > screenHeight / 2) {
                          print('走了这里 右下为基准');
                          scaleAlignment = Alignment.bottomRight;
                           x =isScaled? screenWidth * scaleFactor - width:screenWidth - width - hPadding;
                          if (y > screenHeight - originHeight - vPadding) {
                            y = screenHeight - originHeight - vPadding;
                          }
                        }
                      });
                    overlayEntryX.markNeedsBuild();
                  },
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _animationScale.value,
                        alignment: scaleAlignment,
                        child: Material(
                          color: Colors.transparent,
                          child: Container(
                            decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(16)),
                            width: MediaQuery.of(context).size.width - 32,
                            height: (MediaQuery.of(context).size.width - 32) *
                                9 /
                                16,
                            child: Stack(
                              children: [
                                FlutterFloatWindowView(
                                  videoUrl: videoUrl,
                                  title: "flutterWindow",
                                  artist: "videoTest",
                                  position: 10000,
                                  duration: 180000,
                                  coverUrl:
                                      "https://t7.baidu.com/it/u=2621658848,3952322712&fm=193&f=GIF",
                                  speed: 2.0,
                                ),
                                // Center(
                                //   child: Row(
                                //     mainAxisAlignment: MainAxisAlignment.spaceAround,
                                //     children: [
                                //       IconButton(onPressed:(){
                                //
                                //       }, icon: Icon(Icons.arrow_back_ios,color: Colors.white,)),
                                //       IconButton(onPressed:(){}, icon: Icon(Icons.fullscreen,color: Colors.white,)),
                                //       IconButton(onPressed:(){}, icon: Icon(Icons.arrow_forward_ios,color: Colors.white,))
                                //     ],
                                //   ),
                                // ),
                                // Positioned(
                                //   left: 0,
                                //     top: 0,
                                //     child: ElevatedButton(onPressed:(){
                                //   FlutterFloatWindow.pause();
                                //   overlayEntryX.remove();
                                // } ,child: Text('关闭'),))
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  )));
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
    }

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
    //     "http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4");
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
              'http://vfx.mtime.cn/Video/2019/03/18/mp4/190318231014076505.mp4'
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
    // debugPrint('fw=$fW,fh=$fH,${window.devicePixelRatio}');
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
                  Center(
                    child: Text('Running on: $_platformVersion\n'),
                  ),
                  Platform.isAndroid?Wrap(
                    spacing: 10,
                    children: [ElevatedButton(
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
                            FlutterFloatWindow.setGravity(
                                FloatWindowGravity.left);
                            break;
                          case 2:
                            FlutterFloatWindow.setGravity(
                                FloatWindowGravity.top);
                            break;
                          case 3:
                            FlutterFloatWindow.setGravity(
                                FloatWindowGravity.right);
                            break;
                          case 4:
                            FlutterFloatWindow.setGravity(
                                FloatWindowGravity.bottom);
                            break;
                          case 0:
                            FlutterFloatWindow.setGravity(
                                FloatWindowGravity.center);
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
                      child: Text('test Push'))],
                  ):Wrap(
                    spacing: 10,
                    children: [

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
                        FlutterFloatWindow.pause();
                        overlayEntryX.remove();
                      },
                      child: Text('移除overaly')),
                  ElevatedButton(
                      onPressed: () {
                        _animationController.forward();
                        // overlayEntryX.markNeedsBuild();
                      },
                      child: Text('缩放overlay操作')),
                  ElevatedButton(
                      onPressed: () {
                        _animationController.reverse();
                        // overlayEntryX.markNeedsBuild();
                      },
                      child: Text('缩放overlay操作返回')),
                  ElevatedButton(
                      onPressed: () {
                        setState(() {
                          videoUrl = videoUrlMp4;
                        });
                      },
                      child: Text('切换VideoUrl')),
                  ElevatedButton(
                      onPressed: () async {
                        var canShowFloatWindow =
                            await FlutterFloatWindow.canShowFloatWindow();
                        print("canShowFloatWindow=$canShowFloatWindow");
                      },
                      child: Text('canShow for ios')),
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
                        FlutterFloatWindow.pause();
                        overlayEntryX.remove();
                      },
                      child: Text('移除overaly')),
                  ElevatedButton(
                      onPressed: () {
                        _animationController.forward();
                        // overlayEntryX.markNeedsBuild();
                      },
                      child: Text('缩放overlay操作')),
                  ElevatedButton(
                      onPressed: () {
                        _animationController.reverse();
                        // overlayEntryX.markNeedsBuild();
                      },
                      child: Text('缩放overlay操作返回')),
                  ElevatedButton(
                      onPressed: () {
                        setState(() {
                          videoUrl = videoUrlMp4;
                        });
                      },
                      child: Text('切换VideoUrl')),
                  ElevatedButton(
                      onPressed: () async {
                        var canShowFloatWindow =
                            await FlutterFloatWindow.canShowFloatWindow();
                        print("canShowFloatWindow=$canShowFloatWindow");
                      },
                      child: Text('canShow for ios')),
                    ElevatedButton(
                      onPressed: () async {
                       NavigationUtil.getInstance().pushPage(context, 'testFlutterVideoView', widget: TestFlutterVideoViewPage());
                      },
                      child: Text('testFlutterVideoView')),
                  ],),
                  
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
