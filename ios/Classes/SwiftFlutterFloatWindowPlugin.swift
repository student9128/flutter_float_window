import Flutter
import UIKit
import AVKit
import AVFoundation
import MediaPlayer
public class SwiftFlutterFloatWindowPlugin: NSObject, FlutterPlugin,AVPictureInPictureControllerDelegate {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_float_window", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterFloatWindowPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        let factory = FloatWindowViewFactory(messenger: registrar.messenger())
        registrar.register(factory, withId: "flutter_float_window")
        let liveFactory = FloatLiveWindowViewFactory(messenger: registrar.messenger())
        registrar.register(liveFactory, withId: "flutter_float_live_window")
    }
}
