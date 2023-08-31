//
//  FlutterVideoPlayerFactory.swift
//  flutter_float_window
//
//  Created by Kevin Jing on 2023/8/21.
//

import Foundation
class FlutterVideoPlayerFactory : NSObject,FlutterPlatformViewFactory{
    private var messenger: FlutterBinaryMessenger
    private var eventSink: FlutterEventSink?
    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
        let channel = FlutterMethodChannelManager.shared.registerMethodChannelVideoPlayer(binaryMessenger: messenger)
        channel.setMethodCallHandler{call,result in
            self.handle(call, result: result)
        }
        let event = FlutterEventChannel(name: "flutter_video_player/video_events", binaryMessenger: messenger)
        event.setStreamHandler(self)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotification), name:NSNotification.Name.init("videoPlayerNotification") , object: nil)
    }
    deinit{
        NotificationCenter.default.removeObserver(self)
        printE("FlutterVideoPlayerFactory==deinit")
    }
    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        printE("FlutterVideoPlayerFactory")
        return FlutterVideoPlayerView(frame: frame, viewIdentifier: viewId, arguments: args, binaryMessenger: messenger)
    }
    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
    private func handle(_ call: FlutterMethodCall,result:@escaping FlutterResult){
        switch call.method {
        case "initVideoPlayerIOS":
            if call.arguments is Dictionary<String,Any>?{
                let dic = call.arguments as! Dictionary<String,Any>
                let url = dic["videoUrl"] as? String
                if let videoUlr=url{
                    let title = dic["title"] as? String
                    let artist = dic["artist"] as? String
                    let coverUrl = dic["coverUrl"] as? String
                    let currentPosition = dic["position"] as? Int
                    let speed = dic["speed"] as? Float
                    printE("initVideoPlayer======")
                    FlutterVideoPlayerManager.shared.initVideoPlayer(videoUrl: videoUlr,title: title ?? "",artist: artist ?? "",coverUrl:coverUrl ?? "",position:currentPosition ?? 0,speed: speed ?? 1.0)}}
            break
        case "destroyVideoPlayerIOS":
            FlutterVideoPlayerManager.shared.destroyVideoPlayer()
            break
        case "playVideoIOS":
            FlutterVideoPlayerManager.shared.play()
            break
        case "pauseVideoIOS":
            FlutterVideoPlayerManager.shared.pause()
            break
        case "seekVideoIOS":
            if call.arguments is Dictionary<String,Any>?{
                let dic = call.arguments as! Dictionary<String,Any>
                if let position = dic["position"] as? Int{
                    FlutterVideoPlayerManager.shared.seekTo(position: position)
                }
            }
            break
        case "enablePipVideoIOS":
            if(call.arguments) is Dictionary<String,Any>?{
                let dic = call.arguments as! Dictionary<String,Any>
                let enablePipIOS = dic["enablePipIOS"] as? Bool
                if let enable = enablePipIOS{
                    FlutterVideoPlayerManager.shared.enablePipBackgroundMode(enable: enable)
                }
            }
            break
        case "startPipVideoIOS":
            FlutterVideoPlayerManager.shared.startPip()
            break
        case "stopPipVideoIOS":
            FlutterVideoPlayerManager.shared.stopPip()
            break
        case "durationAndPosition":
            FlutterVideoPlayerManager.shared.durationAndPosition(result: result)
            break
        case "isVideoPlayingIOS":
            result(FlutterVideoPlayerManager.shared.isPlaying)
            break
        default:
            break
        }
        
    }
    @objc func handleNotification(notification:Notification){
//        printD("notification==\(notification)")
        if let result = notification.object as? String{
            var arguments:[String:Any]=["method":result]
            if let userInfo = notification.userInfo as? [String:Any]{
                for(key,value) in userInfo{
                    arguments[key]=value
                }
            }
//            printI("arguments=\(arguments)")
            self.eventSink?(arguments)
        }
    }
}
extension FlutterVideoPlayerFactory : FlutterStreamHandler{
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}
