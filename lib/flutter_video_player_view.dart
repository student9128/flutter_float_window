import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_float_window/flutter_float_window.dart';

class FlutterVideoPlayerView extends StatelessWidget {
  const FlutterVideoPlayerView(
      {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return UiKitView(
        viewType: "flutter_video_player_view",
        creationParams: const <String, dynamic>{},
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: (viewId) {
        });
  }
}
