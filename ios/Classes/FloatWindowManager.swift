//
//  FloatWindowManager.swift
//  flutter_float_window
//
//  Created by Kevin Jing on 2023/6/29.
//

import Foundation
import AVFoundation
import AVKit
import MediaPlayer
public class FloatWindowManager:NSObject{
    public static let shared = FloatWindowManager()
    private override init() {
    }
    //    public var isPlaying = true
    var pipController: AVPictureInPictureController?
    var playerLayerX:AVPlayerLayer?
    private var progressUpdateTimer: Timer?
    private var isPlayEnd = false;
    var nowPlayingInfo = [String : Any]()
    var mUrlString   : String?
    var mImageUrl    : String?
    var mAudioTitle  : String?
    var mArtist      : String?
    var mAlbumTitle  : String?
    var mDuration    : Int = 0
    var mPosition    : Int = 0
    var isRestore = false
    
    var isPlaying   : Bool = false {
        didSet {
            if let c = _isPlayingChanged{
                c(isPlaying)
            }
        }
    }
    var isReady     : Bool = false
    var progress    : Int = 0 {
        didSet {
            if let c = _progressChanged{
                c(progress)
            }
        }
    }
    private var _isPlayingChanged : ((Bool)->Void)?
    func onIsPlayingChanged(_ isPlayingChanged : @escaping ((Bool)->Void)){
        _isPlayingChanged = isPlayingChanged
    }
    
    private var _progressChanged : ((Int)->Void)?
    func onProgressChanged(_ progressChanged : @escaping ((Int)->Void)){
        _progressChanged = progressChanged
    }
    
    
    func initFloatWindowManager(videoUrl:String,title:String = "",artist:String = "",coverUrl:String = "",position:Int = 0,duration:Int = 0,speed:Float = 1.0){
//        printD("title=\(title),artist=\(artist),coverUrl=\(coverUrl),currentPosition=\(position)")
        let videoURL = URL(string: videoUrl)!
        let player = AVPlayer(url: videoURL)
        playerLayerX = AVPlayerLayer(player: player)
        player.seek(to: CMTimeMake(value: Int64(position/1000), timescale: 1))
        player.play()
        player.rate=speed
        isPlaying=true
        if #available(iOS 15.0, *) {
            player.audiovisualBackgroundPlaybackPolicy = AVPlayerAudiovisualBackgroundPlaybackPolicy.continuesIfPossible
        } else {
            // Fallback on earlier versions
        }
        player.preventsDisplaySleepDuringVideoPlayback=true
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            printE("AVAudioSession发生错误")
        }
        
        pipController = AVPictureInPictureController(playerLayer: playerLayerX!)
        pipController?.delegate=self
        
        //        if #available(iOS 14.0, *) {
        //            pipController?.requiresLinearPlayback=true //隐藏快进后退按钮
        //        } else {
        //            // Fallback on earlier versions
        //        }
        //        pipController?.setValue(1, forKey: "controlsStyle")//隐藏除关闭和退出画中画以外的其他按钮
        
        //        pipController?.setValue(1, forKey: "requiresLinearPlayback")//隐藏快进后退按钮
        //        pipController?.setValue(2, forKey: "controlsStyle")//隐藏所有按钮
        //根据视频形状去修改画中画形状
        //        NSURL *url = [[NSBundle mainBundle] URLForResource:videoName withExtension:@"MP4"];
        //        AVAsset *asset = [AVAsset assetWithURL:url];
        //        AVPlayerItem * item = [[AVPlayerItem alloc] initWithAsset:asset];
        //        [self.pipController.playerLayer.player replaceCurrentItemWithPlayerItem:item];
        
        
        if #available(iOS 14.2, *) {
            pipController?.canStartPictureInPictureAutomaticallyFromInline=true
        } else {
            // Fallback on earlier versions
        }
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)
        if(position>15000){
            NotificationCenter.default.post(name: NSNotification.Name("forwardAndBackwardBtnEnable"), object: "backwardEnabled")
        }else{
            NotificationCenter.default.post(name: NSNotification.Name("forwardAndBackwardBtnEnable"), object: "backwardDisabled")
        }
        if(duration-position>15000){
            NotificationCenter.default.post(name: NSNotification.Name("forwardAndBackwardBtnEnable"), object: "forwardEnabled")
        }else{
            NotificationCenter.default.post(name: NSNotification.Name("forwardAndBackwardBtnEnable"), object: "forwardDisabled")
        }
        
        mImageUrl = coverUrl
        mAudioTitle = title
        mArtist = artist
        mAlbumTitle = title
        
        mDuration = duration/1000
        mPosition = position/1000
        
        initRemoteCommand()
        initNowPlayingCenter()
    }
    @objc func playerDidFinishPlaying(notification:Notification){
        isPlayEnd=true;
        isPlaying=false;
        NotificationCenter.default.post(name: NSNotification.Name("PlayPause"), object: "pause")
        
    }
    public func pictureInPictureSwitchOn()->Bool{
        var isOn = true;
        if let pip = pipController{
            isOn = pip.isPictureInPicturePossible
        }
        return isOn
    }
    public func startPip(){
        pipController?.startPictureInPicture()
    }
    public func stopPip(){
        if let pc = pipController,pc.isPictureInPictureActive{
                pc.stopPictureInPicture()
        }
    }
    public func updateForwardAndBackwardBtnStatus(){
        if let playerLayer = playerLayerX{
            if let player = playerLayer.player{
                let progress = CMTimeGetSeconds(player.currentTime())
                let duration = CMTimeGetSeconds(player.currentItem?.duration ?? CMTime.zero)
                if(progress>15){
                    NotificationCenter.default.post(name: NSNotification.Name("forwardAndBackwardBtnEnable"), object: "backwardEnabled")
                }else{
                    NotificationCenter.default.post(name: NSNotification.Name("forwardAndBackwardBtnEnable"), object: "backwardDisabled")
                }
                if(duration-progress>15){
                    NotificationCenter.default.post(name: NSNotification.Name("forwardAndBackwardBtnEnable"), object: "forwardEnabled")
                }else{
                    NotificationCenter.default.post(name: NSNotification.Name("forwardAndBackwardBtnEnable"), object: "forwardDisabled")
                }
            }
        }
    }
    
    public func play(){
        if(isPlayEnd){
            playerLayerX?.player?.seek(to:CMTimeMake(value:0, timescale: 1))
        }
        printI("play")
        isPlaying=true
        playerLayerX?.player?.play()
    }
    public func pause(){
        isPlaying=false
        playerLayerX?.player?.pause()
    }
    public func playPause(){
        if(isPlayEnd){
            playerLayerX?.player?.seek(to:CMTimeMake(value:0, timescale: 1))
        }
        if(isPlaying){
            playerLayerX?.player?.pause()
            isPlaying=false
            NotificationCenter.default.post(name: NSNotification.Name("PlayPause"), object: "pause")
        }else{
            playerLayerX?.player?.play()
            isPlaying=true
            NotificationCenter.default.post(name: NSNotification.Name("PlayPause"), object: "play")
        }
        if let playerLayer = playerLayerX{
            if let player = playerLayer.player{
                let progress = CMTimeGetSeconds(player.currentTime())
                updateNowPlayingInfoProgress(Float(progress))
                createTimers(true)
            }
        }}
    public func backward(){
        if let playerLayer = playerLayerX{
            if let player = playerLayer.player{
                let progress = CMTimeGetSeconds(player.currentTime())
                let duration = CMTimeGetSeconds(player.currentItem?.duration ?? CMTime.zero)
                if(progress-15>15){
                    
                    player.seek(to:CMTimeMake(value: Int64(progress-15.0), timescale: 1))
                    NotificationCenter.default.post(name: NSNotification.Name("forwardAndBackwardBtnEnable"), object: "backwardEnabled")
                    NotificationCenter.default.post(name: NSNotification.Name("forwardAndBackwardBtnEnable"), object: "forwardEnabled")
                }else{
                    NotificationCenter.default.post(name: NSNotification.Name("forwardAndBackwardBtnEnable"), object: "backwardDisabled")
                    player.seek(to:CMTimeMake(value: 0, timescale: 1))
                    NotificationCenter.default.post(name: NSNotification.Name("forwardAndBackwardBtnEnable"), object: duration-progress>15 ? "forwardEnabled" : "forwardDisabled")
                }
                
                
                
                updateNowPlayingInfoProgress(Float(progress))
            }
        }else{
            
        }
        
    }
    public func forward(){
        if let playerLayer = playerLayerX{
            if let player = playerLayer.player{
                let duration = CMTimeGetSeconds(player.currentItem?.duration ?? CMTime.zero)
                let progress = CMTimeGetSeconds(player.currentTime())
                if(duration>0 && duration-progress>15){
                    NotificationCenter.default.post(name: NSNotification.Name("forwardAndBackwardBtnEnable"), object: "forwardEnabled")
                    player.seek(to:CMTimeMake(value: Int64(progress+15.0), timescale: 1))
                    NotificationCenter.default.post(name: NSNotification.Name("forwardAndBackwardBtnEnable"), object: "backwardEnabled")
                }else{
                    NotificationCenter.default.post(name: NSNotification.Name("forwardAndBackwardBtnEnable"), object: "forwardDisabled")
                    player.seek(to:CMTimeMake(value: Int64(duration), timescale: 1))
                    NotificationCenter.default.post(name: NSNotification.Name("forwardAndBackwardBtnEnable"), object: duration>15 ? "backwardEnabled" : "backwardDisabled")
                }
                
                
                updateNowPlayingInfoProgress(Float(progress))
            }
        }else{
            
        }
    }
    ///关闭
    public func onCloseClick(){
        NotificationCenter.default.removeObserver(self)
        if let playerLayer = playerLayerX{
            if let player = playerLayer.player{
                player.pause()
                resetNowingPlayCenter()
                let progress = CMTimeGetSeconds(player.currentTime())
                let channel = FlutterMethodChannelManager.shared.channel()
                let args=["position":progress*1000]
                channel.invokeMethod("onCloseClick", arguments: args)
            }
        }
    }
    public func onFullScreenClick(){
        NotificationCenter.default.removeObserver(self)
        if let playerLayer = playerLayerX{
            if let player = playerLayer.player{
                player.pause()
                let progress = CMTimeGetSeconds(player.currentTime())
                let channel = FlutterMethodChannelManager.shared.channel()
                let args=["position":progress*1000]
                channel.invokeMethod("onFullScreenClick", arguments: args)
            }
        }
    }
    public func seekTo(position:Int){
        if let playerLayer = playerLayerX{
            if let player = playerLayer.player{
                player.seek(to:CMTimeMake(value: Int64(position), timescale: 1))
                updateNowPlayingInfoProgress(Float(position))
            }
        }
    }
    func initRemoteCommand(){
        let commondCenter: MPRemoteCommandCenter = MPRemoteCommandCenter.shared()
        commondCenter.playCommand.isEnabled=true
        commondCenter.pauseCommand.isEnabled=true
        commondCenter.skipForwardCommand.isEnabled=true
        commondCenter.skipBackwardCommand.isEnabled=true
        commondCenter.skipForwardCommand.preferredIntervals=[15]
        commondCenter.skipBackwardCommand.preferredIntervals=[15]
        commondCenter.skipBackwardCommand.addTarget{ [unowned self]event in
            backward()
            return .success
        }
        commondCenter.skipForwardCommand.addTarget{[unowned self] event in
            forward()
            return .commandFailed
        }
        commondCenter.playCommand.addTarget{[unowned self]event in
            playPause()
            return .success
        }
        commondCenter.pauseCommand.addTarget{ [unowned self]event in
            playPause()
            return .success
            
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
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = mDuration
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = mPosition
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    func resetNowingPlayCenter(){
        let nowPlayingInfo = [String : Any]()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
        
    
    func createTimers(_ create: Bool) {
        if create {
            createTimers(false)
            progressUpdateTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.updateProgress(_:)), userInfo: nil, repeats: true)
        } else {
            if let put = progressUpdateTimer {
                put.invalidate()
                progressUpdateTimer = nil
            }
        }
    }
    
    func updateNowPlayingInfoProgress(_ progress: Float) {
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = progress
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    @objc func updateProgress(_ updatedTimer: Timer?) {
        if isPlaying {
            if let playerLayer = playerLayerX{
                if let player = playerLayer.player{
                    progress = Int(CMTimeGetSeconds(player.currentTime())) *  1000
                }
            }
        }
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

extension FloatWindowManager:AVPictureInPictureControllerDelegate{
    
    public func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
        printE("error=\(error)")
    }
    public func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        //        printI("pictureInPictureControllerWillStartPictureInPicture")
        let channel = FlutterMethodChannelManager.shared.channel()
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
        printI("pictureInPictureControllerDidStopPictureInPicture")
        if(!isRestore){
            onCloseClick()
        }
    }
    public func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        printE("pictureInPictureControllerDidStopPictureInPicture")
        isRestore = true
        onFullScreenClick()
        completionHandler(true)
    }
}
