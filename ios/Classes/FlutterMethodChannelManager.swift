//
//  FlutterMethodChannelManager.swift
//  flutter_float_window
//
//  Created by Kevin Jing on 2023/7/6.
//

import Foundation
class FlutterMethodChannelManager: NSObject{
    public static let shared = FlutterMethodChannelManager()
    private override init() {
    }
    //MARK: float window channel
    private var _channel:FlutterMethodChannel?
    func channel()->FlutterMethodChannel{
        return _channel!
    }
    func registerMethodChannel(binaryMessenger messenger: FlutterBinaryMessenger?)->FlutterMethodChannel{
        self._channel = FlutterMethodChannel(name: "flutter_float_window", binaryMessenger: messenger!)
        return _channel!
    }
    
    func notifyFlutter(_ method:String,arguments:Any?){
        _channel?.invokeMethod(method, arguments:arguments)
    }
    //MARK: agora channel
    private var _agoraChannel:FlutterMethodChannel?
    func agoraChannel()->FlutterMethodChannel{
        return _agoraChannel!
    }
    func registerMethodChannelAgoraLive(binaryMessenger messenger: FlutterBinaryMessenger?)->FlutterMethodChannel{
        self._agoraChannel = FlutterMethodChannel(name: "flutter_agora_live", binaryMessenger: messenger!)
        return _agoraChannel!
    }
    func notifyFlutterAgoraLive(_ method:String,arguments:Any?){
        _agoraChannel?.invokeMethod(method, arguments:arguments)
    }
    
    // MARK: video player channel
    private var _videoPlayerChannel:FlutterMethodChannel?
    func videoPlayerChannel()->FlutterMethodChannel{
        return _videoPlayerChannel!
    }
    func registerMethodChannelVideoPlayer(binaryMessenger messenger: FlutterBinaryMessenger?)->FlutterMethodChannel{
        self._videoPlayerChannel = FlutterMethodChannel(name: "flutter_video_player", binaryMessenger: messenger!)
        return _videoPlayerChannel!
    }
    func notifyFlutterVideoPlayer(_ method:String,arguments:Any?){
        _videoPlayerChannel?.invokeMethod(method, arguments:arguments)
    }
    
}
