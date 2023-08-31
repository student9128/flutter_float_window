import 'package:flutter/material.dart';
import 'package:flutter_float_window/flutter_float_window.dart';
import 'package:flutter_float_window/flutter_video_player_engine.dart';
import 'package:flutter_float_window/flutter_video_player_event_handler.dart';
import 'package:flutter_float_window/flutter_video_player_progress_bar.dart';
import 'package:flutter_float_window/flutter_video_player_view.dart';

class TestFlutterVideoViewPage extends StatefulWidget {
  const TestFlutterVideoViewPage({Key? key,this.isFromPip = false}) : super(key: key);
  final bool isFromPip;

  @override
  State<TestFlutterVideoViewPage> createState() =>
      _TestFlutterVideoViewPageState();
}

class _TestFlutterVideoViewPageState extends State<TestFlutterVideoViewPage> {
  String videoUrlMp4 =
      "https://v-cdn.zjol.com.cn/277001.mp4";
  bool hasInitialized = false;
  double position = 0;
  double duration = 0;
  double bufferedStart = 0;
  double bufferedEnd = 0;
  FlutterVideoPlayerEngine? create;
  @override
  void initState() {
    super.initState();
    if(!widget.isFromPip){
    FlutterFloatWindow.destroyVideoPlayerIOS();
    }
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final String videoUrl = videoUrlMp4;
      final String title = 'test';
      final String artist = 'testArtist';
      final String coverUrl =
          'https://t7.baidu.com/it/u=2621658848,3952322712&fm=193&f=GIF';
      final int positionX = 0;
      FlutterFloatWindow.initVideoPlayerIOS(
          url: videoUrlMp4,
          title: title,
          artist: artist,
          coverUrl: coverUrl,
          position: positionX);
      create = FlutterVideoPlayerEngine.create();
      create?.setVideoPlayerEventHandler(
          FlutterVideoPlayerEventHandler(onInitialized: () {
        print("onInitialized");
        setState(() {
          hasInitialized = true;
        });
      },onVideoProgress:
        (double position, double duration, double bufferedStart,
            double bufferedEnd) {
      if (mounted) {
        setState(() {
          this.position = position;
          this.duration = duration;
          this.bufferedStart = bufferedStart;
          this.bufferedEnd = bufferedEnd;
        });
      }
    }));
      FlutterFloatWindow.initVideoPlayerListener(create!.mHandler!);
    });
  }

  @override
  void dispose() {
    create?.setVideoPlayerEventHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('测试FlutterVideoPlayerView的使用'),
        leading: IconButton(
            onPressed: () {
              FlutterFloatWindow.destroyVideoPlayerIOS();
              Navigator.pop(context);
            },
            icon: Icon(Icons.arrow_back_ios)),
      ),
      body: SafeArea(
          child: Column(
        children: [
          hasInitialized
              ? Column(
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.width * 9 / 16,
                      color: Colors.black,
                      child: const FlutterVideoPlayerView(),
                    ),
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 16,vertical: 10),
                      child: Column(
                        children: [
                    FlutterVideoPlayerProgressBar(
                        position: position,
                        duration: duration,
                        bufferedStart: bufferedStart,
                        bufferedEnd: bufferedEnd,
                        barHeight: 5,
                        handleHeight: 16,
                        drawShadow: false,onSeek: (barPosition){
                          if(duration==0)return;
                          var pos = barPosition*duration;
                          setState(() {
                            this.position = pos;
                            this.bufferedStart = 0;
                            this.bufferedEnd = 0;
                          });
                          print("pos===$pos,$barPosition");
                          FlutterFloatWindow.seekVideoIOS({'position': pos.toInt()});
                          
                        },),
                    Container(
                      margin: EdgeInsets.only(top: 10),
                      child: FlutterVideoPlayerProgressBar(
                        position: position,
                        duration: duration,
                        bufferedStart: bufferedStart,
                        bufferedEnd: bufferedEnd,
                        barHeight: 5,
                        handleHeight: 10,
                        drawShadow: false,
                        drawHandle: false,
                        drawBuffer: false,
                        colors: FlutterVideoPlayerProgressBarColors(playedColor: Colors.blue,backgroundColor: Colors.green),
                      ),
                    )

                        ],
                      ),
                    )
                  ],
                )
              : Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.width * 9 / 16,
                  color: Colors.green,
                ),
          SizedBox(
            height: 10,
          ),
          Wrap(
            spacing: 10,
            children: [
              ElevatedButton(
                  onPressed: () {
                    FlutterFloatWindow.startPipVideoIOS();
                    Navigator.pop(context);
                  },
                  child: Text('弹出画中画')),
              ElevatedButton(
                  onPressed: () {
                    FlutterFloatWindow.stopPipVideoIOS();
                  },
                  child: Text('关闭画中画')),
              ElevatedButton(
                  onPressed: () {
                    FlutterFloatWindow.playVideoIOS();
                  },
                  child: Text('视频播放')),
              ElevatedButton(
                  onPressed: () {
                    FlutterFloatWindow.pauseVideoIOS();
                  },
                  child: Text('视频暂停')),
              ElevatedButton(
                  onPressed: () async {
                    var x = await FlutterFloatWindow.getDurationAndPosition();
                    var position = x['position'];
                    var duration = x['duration'];
                    print("position=$position,duration=$duration");
                  },
                  child: Text('获取播放进度')),
              ElevatedButton(
                  onPressed: () {
                    FlutterFloatWindow.enablePipVideoIOS(false);
                  },
                  child: Text('暂停使用画中画')),
              ElevatedButton(
                  onPressed: () {
                    FlutterFloatWindow.enablePipVideoIOS(true);
                  },
                  child: Text('开启使用画中画')),
              ElevatedButton(
                  onPressed: () async {
                    var x = await FlutterFloatWindow.isPlaying();
                    print("状态$x.");
                  },
                  child: Text('播放状态')),
            ],
          )
        ],
      )),
    );
  }
}
