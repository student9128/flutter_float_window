class FlutterVideoPlayerEventHandler {
  const FlutterVideoPlayerEventHandler({this.onVideoProgress});

  final Function(double position, double duration, double bufferedStart,
      double bufferedEnd)? onVideoProgress;
}
