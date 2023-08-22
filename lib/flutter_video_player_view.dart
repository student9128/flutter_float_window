import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_float_window/flutter_float_window.dart';

class FlutterVideoPlayerView extends StatelessWidget {
  const FlutterVideoPlayerView(
      {Key? key,
        required this.videoUrl,
        this.title = "",
        this.artist = "",
        this.coverUrl = "",
        this.position = 0,
        this.duration=0,
        this.speed=1.0})
      : super(key: key);
  final String videoUrl;
  final String title;
  final String artist;
  final String coverUrl;
  final int position;
  final int duration;
  final double speed;

  @override
  Widget build(BuildContext context) {
    return UiKitView(
        viewType: "flutter_video_player_view",
        creationParams: <String, dynamic>{
          "videoUrl": videoUrl,
          "title": title,
          "artist": artist,
          "coverUrl": coverUrl,
          "position": position,
          "duration":duration,
          "speed":speed
        },
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: (viewId) {
        });
  }
}
