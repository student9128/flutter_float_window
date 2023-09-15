class FlutterAgoraLiveEventHandler {
  const FlutterAgoraLiveEventHandler(
      {this.onError,
      this.onConnectionChanged,
      this.onJoinChannelSuccess,
      this.onLeaveChannel,
      this.onUserJoined,
      this.onUserOffline,
      this.onFirstRemoteVideoFrame,
      this.onFirstRemoteVideoDecoded,
      this.onRemoteVideoStateChanged,
      this.onRemoteVideoMuted,
      this.onLivePipCloseClicked,
      this.onLivePipFullScreenClicked});

  ///加入直播间错误
  final Function(int error)? onError;

  ///正在连接
  final Function(int state, int reason)? onConnectionChanged;

  ///加入直播间成功
  final Function(int uid)? onJoinChannelSuccess;

  ///离开房间
  final Function()? onLeaveChannel;

  ///远端用户加入
  final Function(int uid)? onUserJoined;

  ///远端用户离开
  final Function(int uid, int reason)? onUserOffline;

  ///第一帧画面
  final Function(int uid)? onFirstRemoteVideoFrame;

  ///第一帧画面解码
  final Function(int uid)? onFirstRemoteVideoDecoded;

  ///远端视频状态改变
  final Function(int uid)? onRemoteVideoStateChanged;

  ///远端用户取消或恢复发布视频流回调
  final Function(int uid)? onRemoteVideoMuted;

  ///点击画中画关闭按钮
  final Function()? onLivePipCloseClicked;

  ///点击画中画全屏按钮
  final Function()? onLivePipFullScreenClicked;
}
