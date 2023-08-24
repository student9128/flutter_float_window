class FlutterVideoPlayerEventHandler {
  const FlutterVideoPlayerEventHandler(
      {this.onInitialized, this.onVideoProgress});

  final Function()? onInitialized;
  final Function(double position, double duration, double bufferedStart,
      double bufferedEnd)? onVideoProgress;
}
