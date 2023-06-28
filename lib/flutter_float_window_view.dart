import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_float_window/flutter_float_window.dart';

class FlutterFloatWindowView extends StatelessWidget {
  const FlutterFloatWindowView({Key? key,this.text=''}) : super(key: key);
  static var channel = FlutterFloatWindow.channel;
  final String text;

  @override
  Widget build(BuildContext context) {
    return UiKitView(
      viewType: "flutter_float_window",
      creationParams: <String,dynamic>{"text":text,"hello":"hello"},
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated:(viewId){
        print("viewId===$viewId");
      } ,
    );
  }
}
