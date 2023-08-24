import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FlutterFloatWindowView extends StatelessWidget {
  const FlutterFloatWindowView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return UiKitView(
        viewType: "flutter_float_window",
        creationParams: const <String, dynamic>{},
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: (viewId) {});
  }
}
