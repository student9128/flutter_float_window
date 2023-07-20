//
//  FloatLiveWindowManager.swift
//  flutter_float_window
//
//  Created by Kevin Jing on 2023/7/18.
//

import Foundation
import AgoraRtcKit
import MediaPlayer
public class FloatLiveWindowManager:NSObject{
    public static let shared = FloatLiveWindowManager()
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
    var mImageUrl    : String?
    var mAudioTitle  : String?
    var mArtist      : String?
    var mAlbumTitle  : String?
    
    private override init() {
    }
    func initPip(view:AgoraSampleBufferRender){
        if(hasInitPip){return}
        hasInitPip=true
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            printE("AVAudioSession发生错误")
        }
        pipController = AgoraPictureInPictureController(displayView: view)
        if #available(iOS 14.2, *) {
            pipController?.pipController.canStartPictureInPictureAutomaticallyFromInline = true
        }
        pipController?.pipController.delegate = self
        pipController?.pipController.setValue(1, forKey: "controlsStyle")
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
    func onCloseClick(){
        leavelChannel()
        let channel = FlutterMethodChannelManager.shared.channel()
        channel.invokeMethod("onLiveCloseClick", arguments: nil)
    }
    func onFullScreenClick(){
        leavelChannel()
        let channel = FlutterMethodChannelManager.shared.channel()
        channel.invokeMethod("onLiveFullScreenClick", arguments: nil)
    }
    deinit{
        printI("deinit走了吗")
        pipController?.releasePIP()
    }
    func initFloatLiveWindowManager(appId:String,token:String,channelName:String,optionalUid:Int = -1,title:String = "",artist:String = "",coverUrl:String = ""){
        printI("initFloatLiveWindowManager")
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
        agoraKit?.joinChannel(byToken: mToken, channelId: mChannelName, info: nil, uid: UInt(mOptionalUid))
        
        mImageUrl = coverUrl
        mAudioTitle = title
        mArtist = artist
        mAlbumTitle = title
        
        initRemoteCommand()
        initNowPlayingCenter()
        
    }
    func joinChannel(){
//        let option = AgoraRtcChannelMediaOptions()
//        option.publishLocalAudio=false
//        option.publishLocalVideo=false
//        agoraKit?.joinChannel(byToken: mToken, channelId: mChannelName, info: nil, uid: UInt(mOptionalUid), options: option)
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
        if let url = URL(string: mImageUrl ?? "") {
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
    }
    func resetNowingPlayCenter(){
        let nowPlayingInfo = [String : Any]()
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
extension FloatLiveWindowManager:AgoraRtcEngineDelegate{

    public func rtcEngine(_ engine: AgoraRtcEngineKit, connectionChangedTo state: AgoraConnectionState, reason: AgoraConnectionChangedReason) {
        printD("connectionChangedTo\(reason),,\(reason.rawValue)")
    }
    public func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        //远端用户（通信场景）/主播（直播场景）加入当前频道回调
        printD("didJoinedOfUid,\(uid)")
//        let videoCanvas = AgoraRtcVideoCanvas()
//        videoCanvas.uid = uid
//        videoCanvas.renderMode = .hidden
//        videoCanvas.view = remoteView
//        agoraKit?.setupRemoteVideo(videoCanvas)
        NotificationCenter.default.post(name: NSNotification.Name("agoraNotification"), object: "didJoinedOfUid",userInfo:["uid":uid] )
        
    }
    public func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        //本地用户加入频道成功
        printD("didJoinChannel,\(uid)")
        
    }
    public func rtcEngine(_ engine: AgoraRtcEngineKit, firstRemoteVideoFrameOfUid uid: UInt, size: CGSize, elapsed: Int) {
        //首帧渲染 上线
        printD("firstRemoteVideoFrameOfUid")
    }
    public func rtcEngine(_ engine: AgoraRtcEngineKit, firstRemoteVideoDecodedOfUid uid: UInt, size: CGSize, elapsed: Int) {
        //解码远端视频
        printD("firstRemoteVideoDecodedOfUid")
        
    }
    public func rtcEngine(_ engine: AgoraRtcEngineKit, didLeaveChannelWith stats: AgoraChannelStats) {
        printD("didLeaveChannelWith")
    }
    public func rtcEngine(_ engine: AgoraRtcEngineKit, remoteVideoStateChangedOfUid uid: UInt, state: AgoraVideoRemoteState, reason: AgoraVideoRemoteReason, elapsed: Int) {
        if(reason.rawValue==7){
            NotificationCenter.default.post(name: NSNotification.Name("agoraNotification"), object: "remoteUserLeaveChannel")
        }
        printD("remoteVideoStateChangedOfUid,state=\(state),reason=\(reason)")
    }
    public func rtcEngine(_ engine: AgoraRtcEngineKit, didVideoMuted muted: Bool, byUid uid: UInt) {
        //画面不可用
        printE("didVideoMuted")
    }
}
extension FloatLiveWindowManager: AVPictureInPictureControllerDelegate{
    
    public func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
        printE("error=\(error)")
    }
    public func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        NotificationCenter.default.post(name: NSNotification.Name("agoraNotification"), object: "pipWillStart" )
        let channel = FlutterMethodChannelManager.shared.channel()
        channel.invokeMethod("onPictureInPictureWillStart", arguments: nil)
    }
    public func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
//        isRestore = false
        //        printI("pictureInPictureControllerDidStartPictureInPicture")
    }
    public func pictureInPictureControllerWillStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        //        printI("pictureInPictureControllerWillStopPictureInPicture")
    }
    public func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        printI("pictureInPictureControllerDidStopPictureInPicture")
        if(!isRestore){
            onCloseClick()
        }
    }
    public func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
//        printE("pictureInPictureControllerDidStopPictureInPicture")
        isRestore = true
        onFullScreenClick()
        completionHandler(true)
    }
}

