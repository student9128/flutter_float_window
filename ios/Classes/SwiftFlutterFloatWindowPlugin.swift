import Flutter
import UIKit
import AVKit
import AVFoundation
import MediaPlayer
public class SwiftFlutterFloatWindowPlugin: NSObject, FlutterPlugin,AVPictureInPictureControllerDelegate {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = SwiftFlutterFloatWindowPlugin()
        
        let channel = FlutterMethodChannel(name: "flutter_float_window", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: channel)
        
        let flutterAgoraChannel = FlutterMethodChannel(name: "flutter_agora_live", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: flutterAgoraChannel)
        
        let factory = FloatWindowViewFactory(messenger: registrar.messenger())
        registrar.register(factory, withId: "flutter_float_window")
        
        let liveFactory = FloatLiveWindowViewFactory(messenger: registrar.messenger())
        registrar.register(liveFactory, withId: "flutter_float_live_window")
        
        let agoraLiveFactory = FlutterAgoraLiveViewFactory(messenger: registrar.messenger())
        registrar.register(agoraLiveFactory, withId: "flutter_agora_live_view")
    }
}
