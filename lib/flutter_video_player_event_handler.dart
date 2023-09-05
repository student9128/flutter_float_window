class FlutterVideoPlayerEventHandler {
  const FlutterVideoPlayerEventHandler(
      {this.onInitialized,
      this.onVideoProgress,
      this.onVideoPlayEnd,
      this.onVideoInterruptionBegan,
      this.onVideoInterruptionEnded});

  final Function()? onInitialized;
  final Function()? onVideoPlayEnd;
  final Function()? onVideoInterruptionBegan;
  final Function()? onVideoInterruptionEnded;
  final Function(double position, double duration, double bufferedStart,
      double bufferedEnd)? onVideoProgress;
}
