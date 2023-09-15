//
//  FlutterAgoraLiveManager.swift
//  flutter_float_window
//
//  Created by Kevin Jing on 2023/7/31.
//

import Foundation
import AgoraRtcKit
import MediaPlayer
public class FlutterAgoraLiveManager:NSObject{
    public static let shared = FlutterAgoraLiveManager()
    var mAppId : String = ""
    var mToken : String = ""
    var mChannelName : String = ""
    var mOptionalUid : Int = -1
    var agoraKit : AgoraRtcEngineKit?
    var remoteView : UIView?
    var pipController: AgoraPictureInPictureController?
    var hasInitPip=false
    var isRestore = false
    var nowPlayingInfo = [String : Any]()
    var mImageUrl    : String = ""
    var mAudioTitle  : String = ""
    var mArtist      : String = ""
    var mAlbumTitle  : String = ""
    
    public override init() {
    }
    func initPip(view:AgoraSampleBufferRender){
        printD("initPip")
        if(hasInitPip){return}
        pipController?.releasePIP()
        printE("initPip================")
        hasInitPip=true
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            printE("AVAudioSession发生错误")
        }
        pipController = AgoraPictureInPictureController(displayView: view)
        pipController?.pipController.delegate = self
        pipController?.pipController.setValue(1, forKey: "controlsStyle")
        
        if #available(iOS 14.2, *) {
            pipController?.pipController.canStartPictureInPictureAutomaticallyFromInline = true
        }
    }
    func initPip(){
        postNotification(method: "initPiP", args: nil)
    }
    func startPip(){
        if let pc = pipController{
            pc.pipController.startPictureInPicture()
        }
    }
    func stopPip(){
        if let pipController = pipController?.pipController, pipController.isPictureInPictureActive {
            pipController.stopPictureInPicture()
        }
    }
    func enablePipBackgroundMode(enable:Bool = true,result:@escaping FlutterResult){
        if(enable){
            postNotification(method: "initPiP", args: nil)
            
        }else{
            hasInitPip = false
            pipController?.releasePIP()
        }
        result(true)
    }
    func onCloseClick(){
        self.postNotification(method: "onLivePipCloseClicked", args: [String : Any]())
        let channel = FlutterMethodChannelManager.shared.agoraChannel()
        channel.invokeMethod("onLiveCloseClick", arguments: nil)
    }
    func onFullScreenClick(){
        self.postNotification(method: "onLivePipFullScreenClicked", args: [String : Any]())
        let channel = FlutterMethodChannelManager.shared.agoraChannel()
        channel.invokeMethod("onLiveFullScreenClick", arguments: nil)
    }
    func initAgora(appId:String,token:String,channelName:String,optionalUid:Int = -1,title:String = "",artist:String = "",coverUrl:String = ""){
        mAppId = appId
        mToken = token
        mChannelName = channelName
        mOptionalUid = optionalUid
        let config = AgoraRtcEngineConfig()
        config.appId = appId
        agoraKit = AgoraRtcEngineKit.sharedEngine(with: config, delegate: self)
        agoraKit?.setChannelProfile(AgoraChannelProfile.liveBroadcasting)
        agoraKit?.setClientRole(AgoraClientRole.audience)
        agoraKit?.enableVideo()
        agoraKit?.enableLocalAudio(false)
        agoraKit?.enableLocalVideo(false)
        agoraKit?.muteAllRemoteAudioStreams(false)
        agoraKit?.joinChannel(byToken: mToken, channelId: mChannelName, info: nil, uid: UInt(mOptionalUid))

        mImageUrl = String(coverUrl)
        mAudioTitle = String(title)
        mArtist = String(artist)
        mAlbumTitle = String(title)
        
        initRemoteCommand()
        initNowPlayingCenter()

        
    }
    ///远端视频是否播放声音
    func mutedRemoteAudio(mute:Bool){
        agoraKit?.muteAllRemoteAudioStreams(mute)
    }
    func leavelChannel(){
        hasInitPip = false
        agoraKit?.leaveChannel{result in
            printW("duration=\(result.duration)")
        }
        AgoraRtcEngineKit.destroy()
        pipController?.releasePIP()
        resetNowingPlayCenter()
        
    }
    func initRemoteCommand(){
        let commondCenter: MPRemoteCommandCenter = MPRemoteCommandCenter.shared()
        commondCenter.playCommand.isEnabled=false
        commondCenter.pauseCommand.isEnabled=false
        commondCenter.skipForwardCommand.isEnabled=false
        commondCenter.skipBackwardCommand.isEnabled=false
        commondCenter.togglePlayPauseCommand.isEnabled=false
        // 将按钮颜色设置为灰色
        commondCenter.playCommand.addTarget { _ in
            return .commandFailed
        }

        commondCenter.pauseCommand.addTarget { _ in
            return .commandFailed
        }
        commondCenter.togglePlayPauseCommand.addTarget{_ in
            return .commandFailed
        }
        commondCenter.skipForwardCommand.addTarget{_ in
            return .commandFailed
        }
        commondCenter.skipBackwardCommand.addTarget{_ in
            return .commandFailed
        }
    }
    func initNowPlayingCenter(){
        printW("initNowPlayingCenter::\(mAudioTitle),\(mArtist),\(mImageUrl)")
        if let url = URL(string: mImageUrl) {
            downloadImage(url:url) { image in
                self.nowPlayingInfo[MPMediaItemPropertyArtwork] =
                MPMediaItemArtwork(boundsSize: image.size) { size in
                    return image
                }
                MPNowPlayingInfoCenter.default().nowPlayingInfo = self.nowPlayingInfo
            }
        }
        
        nowPlayingInfo[MPMediaItemPropertyTitle] = mAudioTitle
        nowPlayingInfo[MPMediaItemPropertyArtist] = mArtist
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = mAudioTitle
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        if let x = MPNowPlayingInfoCenter.default().nowPlayingInfo{
            for (key,value) in x{
                printW("key=\(key),value=\(value)")
            }
        }
      
    }
    func showNowPlayingCenter(title:String = "",artist:String = "",coverUrl:String = ""){
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback,mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let error as NSError{
            printE("AVAudioSession发生错误 \(error.localizedDescription)")
        }
        mImageUrl = coverUrl
        mAudioTitle = title
        mArtist = artist
        mAlbumTitle = title
        initRemoteCommand()
        initNowPlayingCenter()
    }
    func resetNowingPlayCenter(){
        nowPlayingInfo = [String : Any]()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    func downloadImage(url: URL, callback: @escaping  (UIImage)->() ) {
        getDataFromUrl(url: url) { (data, response, error)  in
            guard let data = data, error == nil else {
                return
            }
            DispatchQueue.main.async() { () -> Void in
                callback(UIImage(data: data) ?? UIImage())
            }
        }
    }
    
    func getDataFromUrl(url: URL, completion: @escaping (_ data: Data?, _  response: URLResponse?, _ error: Error?) -> Void) {
        URLSession.shared.dataTask(with: url) {
            (data, response, error) in
            completion(data, response, error)
        }.resume()
    }
    
}
extension FlutterAgoraLiveManager:AgoraRtcEngineDelegate{
    private func postNotification(method:String,args:Dictionary<String,Any>?){
        NotificationCenter.default.post(name: NSNotification.Name("agoraNotification"), object: method,userInfo:args )
    }
    public func rtcEngine(_ engine: AgoraRtcEngineKit, didOccur errorType: AgoraEncryptionErrorType) {
        let args:[String : Any]=["error":errorType.rawValue]
        postNotification(method: "onError", args: args)
    }
    public func rtcEngine(_ engine: AgoraRtcEngineKit, connectionChangedTo state: AgoraConnectionState, reason: AgoraConnectionChangedReason) {
        printD("connectionChangedTo\(reason),,\(reason.rawValue)")
        let args:[String : Any] = ["state":state.rawValue,"reason":reason.rawValue]
        postNotification(method: "onConnectionChanged", args: args)
    }
    public func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        //远端用户（通信场景）/主播（直播场景）加入当前频道回调
        printD("didJoinedOfUid,\(uid)")
        let args:[String : Any]=["uid":uid,"elapsed":elapsed]
        postNotification(method: "onUserJoined", args: args)
        
    }
    public func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        //远端用户（通信场景）/主播（直播场景）离开当前频道回调
        let args:[String : Any]=["uid":uid,"reason":reason.rawValue]
        postNotification(method: "onUserOffline", args: args)
    }
    public func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        //本地用户加入频道成功
        printD("didJoinChannel,\(uid)")
        let args:[String : Any]=["uid":uid,"elapsed":elapsed]
        postNotification(method: "onJoinChannelSuccess", args: args)
        FlutterMethodChannelManager.shared.notifyFlutterAgoraLive("onJoinChannelSuccess", arguments: args)
        
    }
    public func rtcEngine(_ engine: AgoraRtcEngineKit, firstRemoteVideoFrameOfUid uid: UInt, size: CGSize, elapsed: Int) {
        //首帧渲染 上线
        printD("firstRemoteVideoFrameOfUid")
        let args:[String : Any]=["uid":uid,"elapsed":elapsed]
        postNotification(method: "onFirstRemoteVideoFrame", args: args)
    }
    public func rtcEngine(_ engine: AgoraRtcEngineKit, firstRemoteVideoDecodedOfUid uid: UInt, size: CGSize, elapsed: Int) {
        //解码远端视频
        printD("firstRemoteVideoDecodedOfUid")
        let args:[String : Any]=["uid":uid,"elapsed":elapsed]
        postNotification(method: "onFirstRemoteVideoDecoded", args: args)
        NotificationCenter.default.post(name: NSNotification.Name("agoraNotification"), object: "delegateVideoStream" )

    }
    public func rtcEngine(_ engine: AgoraRtcEngineKit, didLeaveChannelWith stats: AgoraChannelStats) {
        printD("didLeaveChannelWith")
        postNotification(method: "onLeaveChannel", args: nil)
    }
    public func rtcEngine(_ engine: AgoraRtcEngineKit, remoteVideoStateChangedOfUid uid: UInt, state: AgoraVideoRemoteState, reason: AgoraVideoRemoteReason, elapsed: Int) {
//        FlutterMethodChannelManager.shared.notifyFlutter("remoteVideoStateChanged", arguments: nil)
//        if(reason.rawValue==7){
//            NotificationCenter.default.post(name: NSNotification.Name("agoraNotification"), object: "remoteUserLeaveChannel")
//        }
        let args:[String : Any]=["uid":uid,"elapsed":elapsed]
        postNotification(method: "onRemoteVideoStateChanged", args: args)
        printD("remoteVideoStateChangedOfUid,state=\(state),reason=\(reason)")
    }
    public func rtcEngine(_ engine: AgoraRtcEngineKit, didVideoMuted muted: Bool, byUid uid: UInt) {
        //画面不可用
        printE("didVideoMuted")
        let args:[String : Any]=["uid":uid]
        postNotification(method: "onRemoteVideoMuted", args: args)

    }

}
extension FlutterAgoraLiveManager:AVPictureInPictureControllerDelegate{
    
    public func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
        printE("error=\(error)")
    }
    public func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        
        NotificationCenter.default.post(name: NSNotification.Name("agoraNotification"), object: "pipWillStart" )
        let channel = FlutterMethodChannelManager.shared.agoraChannel()
        channel.invokeMethod("onPictureInPictureWillStart", arguments: nil)
        
    }
    public func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        isRestore = false
        //        printI("pictureInPictureControllerDidStartPictureInPicture")
    }
    public func pictureInPictureControllerWillStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        //        printI("pictureInPictureControllerWillStopPictureInPicture")
    }
    public func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        printI("pictureInPictureControllerDidStopPictureInPicture \(isRestore)")
        if(!isRestore){
            onCloseClick()
        }else{
            isRestore = false
        }
    }
    public func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        isRestore = true
        onFullScreenClick()
        printE("restoreUserInterfaceForPictureInPictureStopWithCompletionHandler")
        completionHandler(true)
    }
}
