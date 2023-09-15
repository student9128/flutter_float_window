//
//  FlutterAgoraLiveViewFactory.swift
//  flutter_float_window
//
//  Created by Kevin Jing on 2023/7/31.
//

import Foundation
import UIKit
class FlutterAgoraLiveViewFactory: NSObject,FlutterPlatformViewFactory{
    private var messenger: FlutterBinaryMessenger
    private var eventSink: FlutterEventSink?
    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        printE("agoraLiveFactory====init")
        super.init()
        let channel =  FlutterMethodChannelManager.shared.registerMethodChannelAgoraLive(binaryMessenger: messenger)
        channel.setMethodCallHandler{call,result in
            self.handle(call, result: result)
        }
        let event = FlutterEventChannel(name: "flutter_agora_live/agora_events", binaryMessenger: messenger)
        event.setStreamHandler(self)
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotification), name:NSNotification.Name.init("agoraNotification") , object: nil)
    }
    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        printE("agoraLiveFactory====create")
        return FlutterAgoraLiveView(frame: frame, viewIdentifier: viewId, arguments: args, binaryMessenger: messenger)
    }
    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
    deinit{
        NotificationCenter.default.removeObserver(self)
        printE("FlutterAgoraLiveViewFactory==deinit")
    }
    
    private func handle(_ call: FlutterMethodCall,result:@escaping FlutterResult){
        printD("FlutterAgoraLiveViewFactory call method:\(call.method), args:\(String(describing: call.arguments))")
        switch (call.method){
        case "initAgora":
            if(call.arguments) is Dictionary<String,Any>?{
                let dic = call.arguments as! Dictionary<String,Any>
                let appId = dic["appId"] as? String
                let token = dic["token"] as? String
                let channelName = dic["channelName"] as? String
                let optionalUid = dic["optionalUid"] as? Int
                let title = dic["title"] as? String
                let artist = dic["artist"] as? String
                let coverUrl = dic["coverUrl"] as? String
                if let id = appId,let t = token,let cn = channelName,let oUid = optionalUid{
                    FlutterAgoraLiveManager.shared.initAgora(appId: id, token: t, channelName: cn,optionalUid: oUid,title: title ?? "",artist: artist ?? "",coverUrl:coverUrl ?? "")
                }
            }
            break
        case "destroyAgora":
//            NotificationCenter.default.removeObserver(self)
            FlutterAgoraLiveManager.shared.leavelChannel()
            break
        case "enablePipIOS":
            if(call.arguments) is Dictionary<String,Any>?{
                let dic = call.arguments as! Dictionary<String,Any>
                let enablePipIOS = dic["enablePipIOS"] as? Bool
                if let enable = enablePipIOS{
                    printE("走了吗-======🚀")
                    FlutterAgoraLiveManager.shared.enablePipBackgroundMode(enable: enable,result: result)
                }
            }
            break
        case "initPipIOS":
            FlutterAgoraLiveManager.shared.initPip()
            break
        case "startPipIOS":
            FlutterAgoraLiveManager.shared.startPip()
            break
        case "stopPipIOS":
            FlutterAgoraLiveManager.shared.stopPip()
            break
        case "showNowPlaying":
            if(call.arguments) is Dictionary<String,Any>?{
                let dic = call.arguments as! Dictionary<String,Any>
                let title = dic["title"] as? String
                let artist = dic["artist"] as? String
                let coverUrl = dic["coverUrl"] as? String
                if let t = title,let a = artist,let url = coverUrl{
                    FlutterAgoraLiveManager.shared.showNowPlayingCenter(title:t,artist: a,coverUrl: url)
                }
             
            }
            
            break
        case "mutedRemoteAudio":
            if(call.arguments) is Dictionary<String,Any>?{
                let dic = call.arguments as! Dictionary<String,Any>
                let muteRemoteAudio = dic["mutedRemoteAudio"] as? Bool
                if let mute = muteRemoteAudio{
                    FlutterAgoraLiveManager.shared.mutedRemoteAudio(mute: mute)
                }
            }
            break
        case "mutedRemoteVideo":
            if(call.arguments) is Dictionary<String,Any>?{
                let dic = call.arguments as! Dictionary<String,Any>
                let muteRemoteAudio = dic["mutedRemoteVideo"] as? Bool
                if let mute = muteRemoteAudio{
                    FlutterAgoraLiveManager.shared.mutedRemoteVideo(mute: mute)
                }
            }
            break
        default:
            break
        }
    }
    @objc func handleNotification(notification:Notification){
        printD("notification==\(notification)")
        if let result = notification.object as? String{
            var arguments:[String:Any]=["method":result]
            if let userInfo = notification.userInfo as? [String:Any]{
                for(key,value) in userInfo{
                    arguments[key]=value
                }
            }
            printI("arguments=\(arguments)")
            self.eventSink?(arguments)
        }
        
    }
}
extension FlutterAgoraLiveViewFactory:FlutterStreamHandler{
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
    
    
}

