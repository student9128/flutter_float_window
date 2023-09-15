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

  ///视频初始化
  final Function()? onInitialized;

  ///视频播放结束
  final Function()? onVideoPlayEnd;

  ///视频暂停
  final Function()? onVideoPlayPaused;

  ///视频被打断
  final Function()? onVideoInterruptionBegan;

  ///视频被打断后恢复
  final Function()? onVideoInterruptionEnded;

  ///视频进度监听
  final Function(double position, double duration, double bufferedStart,
      double bufferedEnd)? onVideoProgress;

  ///点击视频画中画关闭按钮
  final Function()? onVideoPipCloseClicked;

  ///点击视频画中画全屏按钮
  final Function()? onVideoPipFullScreenClicked;
}
