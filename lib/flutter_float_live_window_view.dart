import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FlutterFloatLiveWindowView extends StatelessWidget {
  const FlutterFloatLiveWindowView({
    Key? key,
    required this.appId,
    required this.token,
    required this.channelName,
    required this.optionalUid,
    this.title = "",
    this.artist = "",
    this.coverUrl = "",
  }) : super(key: key);
  final String appId;
  final String token;
  final String channelName;
  final int optionalUid;
  final String title;
  final String artist;
  final String coverUrl;

  @override
  Widget build(BuildContext context) {
    return UiKitView(
      viewType: "flutter_float_live_window",
      creationParams: <String, dynamic>{
        "appId": appId,
        "token": token,
        "channelName": channelName,
        "optionalUid": optionalUid,
        "title": title,
        "artist": artist,
        "coverUrl": coverUrl,
      },
      creationParamsCodec: const StandardMessageCodec(),
    );
  }
}
