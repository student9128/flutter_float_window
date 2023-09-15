class FlutterVideoPlayerEventHandler {
  const FlutterVideoPlayerEventHandler(
      {this.onInitialized,
      this.onVideoProgress,
      this.onVideoPlayEnd,
      this.onVideoPlayPaused,
      this.onVideoInterruptionBegan,
      this.onVideoInterruptionEnded,
      this.onVideoPipCloseClicked,
      this.onVideoPipFullScreenClicked});

  final Function()? onInitialized;
  final Function()? onVideoPlayEnd;
  final Function()? onVideoPlayPaused;
  final Function()? onVideoInterruptionBegan;
  final Function()? onVideoInterruptionEnded;
  final Function(double position, double duration, double bufferedStart,
      double bufferedEnd)? onVideoProgress;
  final Function()? onVideoPipCloseClicked;
  final Function()? onVideoPipFullScreenClicked;
}
