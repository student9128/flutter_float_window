class FlutterAgoraLiveEventHandler{
  const FlutterAgoraLiveEventHandler({
    this.onError,
    this.onConnectionChanged,
    this.onJoinChannelSuccess,
    this.onLeaveChannel,
    this.onUserJoined,
    this.onUserOffline,
    this.onFirstRemoteVideoFrame,
    this.onFirstRemoteVideoDecoded,
    this.onRemoteVideoStateChanged,
    this.onRemoteVideoMuted
  });
  final Function(int error)? onError;
  final Function(int state,int reason)? onConnectionChanged;
  final Function(int uid)? onJoinChannelSuccess;
  final Function()? onLeaveChannel;
  final Function(int uid)? onUserJoined;
  final Function(int uid,int reason)? onUserOffline;
  final Function(int uid)? onFirstRemoteVideoFrame;
  final Function(int uid)? onFirstRemoteVideoDecoded;
  final Function(int uid)? onRemoteVideoStateChanged;
  final Function(int uid)? onRemoteVideoMuted;
}