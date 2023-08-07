import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FlutterAgoraLiveView extends StatelessWidget {
  const FlutterAgoraLiveView({Key? key,
    this.title = "",
    this.artist = "",
    this.coverUrl = ""}) :super(key: key);
  final String title;
  final String artist;
  final String coverUrl;

  @override
  Widget build(BuildContext context) {
    return UiKitView(
      viewType: "flutter_agora_live_view",
      creationParams: <String, dynamic>{
        "title": title,
        "artist": artist,
        "coverUrl": coverUrl,
      },
      creationParamsCodec: const StandardMessageCodec(),
    );
  }
}

