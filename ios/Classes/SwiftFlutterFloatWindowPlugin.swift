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
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        printD("call method=\(call.method)")
        switch(call.method){
        case "canShowFloatWindow":
            result(AVPictureInPictureController.isPictureInPictureSupported())
            break
        case "initFloatWindow":
            printI("url=\(String(describing: call.arguments))")
//           var videoUrl = call.argument as String
            if let arguments = call.arguments as? Dictionary<String, Any>{
                videoUrl = arguments["videoUrl"] as? String ?? ""
                initFloatWindow()
                  }
            break
        case "showFloatWindow":
            printW("\(pipController?.isPictureInPicturePossible)")
            startPip()
            break
        case "showFloatWindowWithInit":
            break
        case "hideFloatWindow":
            stopPip()
            break
        case "play":
            player?.play()
            break
        case "pause":
            player?.pause()
            break
        case "stop":
            
            break
        case "seekTo":
            break
        case "setPlaybackSpeed":
            break
        case "isLive":
            break
        case "initFloatLive":
            break
        case "leaveChannel":
            break
        case "openSetting":
            break
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    private var videoUrl=""
    private var player:AVPlayer?
    private var playerLayer:AVPlayerLayer?
    private var pipController:AVPictureInPictureController?
    func initFloatWindow(){
        if(videoUrl.isEmpty){return}
        player = AVPlayer(url: URL(string: videoUrl)!)
        playerLayer=AVPlayerLayer(player: player!)
        playerLayer?.player?.play()
        pipController = AVPictureInPictureController(playerLayer: playerLayer!)
        pipController?.delegate=self
        printI("初始化了吗")
        
    }
    func startPip(){
        pipController?.startPictureInPicture()
    }
    func stopPip(){
        pipController?.stopPictureInPicture()
        player=nil
        playerLayer=nil
        pipController=nil
    }
    public func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
    
    }
    public func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        printI("pictureInPictureControllerDidStartPictureInPicture")
//        initRemoteCommand()
//        initNowingPlayCenter()
    }
    public func pictureInPictureControllerWillStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        printI("pictureInPictureControllerWillStopPictureInPicture==")
    }
    public func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        printI("pictureInPictureControllerDidStopPictureInPicture")
    }
    public func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
        printI("failedToStartPictureInPictureWithError=\(error)")
    }
    public func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        printI("restoreUserInterfaceForPictureInPictureStopWithCompletionHandler")
        completionHandler(true)
    }
}
