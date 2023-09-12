//
//  FlutterVideoPlayerManager.swift
//  flutter_float_window
//
//  Created by Kevin Jing on 2023/8/21.
//

import Foundation
import MediaPlayer
import AVFoundation
import AVKit
public class FlutterVideoPlayerManager : NSObject{
    public static let shared = FlutterVideoPlayerManager()
    var pipController: AVPictureInPictureController?
    var avPlayerLayer:AVPlayerLayer?
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
    var hasInit = false
    var timerObserverToken: Any?//监听播放进度
    
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
    private func postNotification(method:String,args:Dictionary<String,Any>?){
        NotificationCenter.default.post(name: NSNotification.Name("videoPlayerNotification"), object: method,userInfo:args )
    }
    
    func initVideoPlayer(videoUrl:String,title:String = "",artist:String = "",coverUrl:String = "",position:Int = 0,speed:Float = 1.0){
        if(hasInit){
            printE("hasInit==========@@@@@@@@@@@@@@@@@@@@@@@@@@@@✈️==")
            pipController?.stopPictureInPicture()
//            avPlayerLayer?.player?.play()
            if let playerLayer = avPlayerLayer{
                if let player = playerLayer.player{
                    printD("播放走了吗")
                    player.playImmediately(atRate: speed)
                }
            }else{
                printD("播放 else")
            }
            self.postNotification(method: "onInitialized", args: [String : Any]())
            printD("播放 onInitialized")
            avPlayerLayer?.player?.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), context: nil)
            return
        }
        hasInit = true
        printE("initVideoPlayer=\(videoUrl)")
        let videoURL = URL(string: videoUrl)!
        let player = AVPlayer(url: videoURL)
        avPlayerLayer = AVPlayerLayer(player: player)
        player.seek(to: CMTimeMake(value: Int64(position/1000), timescale: 1))
        player.addObserver(self, forKeyPath: #keyPath(AVPlayer.status),options:[.new], context: nil)
        player.addObserver(self, forKeyPath: #keyPath(AVPlayer.timeControlStatus),options: [.new], context: nil)
        player.currentItem?.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), context: nil)
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
        
        pipController = AVPictureInPictureController(playerLayer: avPlayerLayer!)
        pipController?.delegate=self
        
        if #available(iOS 14.2, *) {
            pipController?.canStartPictureInPictureAutomaticallyFromInline=true
        } else {
            // Fallback on earlier versions
        }
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)
        NotificationCenter.default.addObserver(self, selector: #selector(handleAudioSessionInterruption), name: AVAudioSession.interruptionNotification, object: nil)
        
        mImageUrl = coverUrl
        mAudioTitle = title
        mArtist = artist
        mAlbumTitle = title
        
//        mDuration = duration/1000
        mPosition = position/1000
        printD("hahahahaha")
        
//        initRemoteCommand()
//        initNowPlayingCenter()
        
    }
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        printD("keypath=\(keyPath),object=\(object),change\(change)")
        if keyPath == #keyPath(AVPlayer.status),let player = object as? AVPlayer {
            switch player.status{
            case .readyToPlay:
                player.play()
                print("AVPlayer loaded successfully")
                break
            case .failed:
                print("AVPlayer loading status unknown")
                break
            case .unknown:
                print("AVPlayer loading status unknown")
                break
            default:
                break
            }
        }else if keyPath == #keyPath(AVPlayer.timeControlStatus),let change = change, let newValue = change[NSKeyValueChangeKey.newKey] as? Int{
            let newStatus = AVPlayer.TimeControlStatus(rawValue: newValue)
            switch newStatus{
            case .paused:
                isPlaying=false
                break
            case .playing:
                isPlaying=true
                break
            case .waitingToPlayAtSpecifiedRate:
                if(isPlayEnd){
                    isPlayEnd=false
                    avPlayerLayer?.player?.seek(to:CMTimeMake(value:0, timescale: 1))
                }
                break
            default:
                break
            }
        }
        else if keyPath == #keyPath(AVPlayerItem.status),let playerItem = object as? AVPlayerItem{
            if playerItem.status == .readyToPlay{
                let duration = CMTimeGetSeconds(playerItem.duration)
                self.mDuration = Int(duration)
                initRemoteCommand()
                initNowPlayingCenter()
                if let playerLayer = avPlayerLayer{
                    if let player = playerLayer.player{
                        player.play()
                        self.postNotification(method: "onInitialized", args: [String : Any]())
                        timerObserverToken = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), queue:DispatchQueue.main){time in
                            let currentTime = CMTimeGetSeconds(time)
                            let timeRanges = playerItem.loadedTimeRanges
                            let first = timeRanges.first as? CMTimeRange
                            let start = CMTimeGetSeconds(first?.start ?? CMTime.zero)
                            let end = CMTimeGetSeconds(first?.end ?? CMTime.zero)
                            
                            let args:[String : Any] = ["duration":duration,"position":currentTime,"bufferedStart":start,"bufferedEnd":end]
                            self.postNotification(method: "onVideoProgress", args: args)
                        }
                    }
                }
            }
        }
    }
    @objc func playerDidFinishPlaying(notification:Notification){
        isPlayEnd=true;
        isPlaying=false;
        self.postNotification(method: "onVideoPlayEnd", args: [String : Any]())
//        NotificationCenter.default.post(name: NSNotification.Name("PlayPause"), object: "pause")
        
    }
    @objc func handleAudioSessionInterruption(notification:Notification){
        guard let userInfo = notification.userInfo,
              let interruptionTypeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let interruptionType = AVAudioSession.InterruptionType(rawValue: interruptionTypeValue) else {
            return
        }
        switch interruptionType {
            case .began: // 中断开始，例如来电
//                player?.pause()
            printE("began")
            self.postNotification(method: "onVideoInterruptionBegan", args: [String : Any]())
            case .ended: // 中断结束，例如电话挂断
            printE("end")
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else {
                return
            }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                //                    player?.play()
                printI("end")
                self.postNotification(method: "onVideoInterruptionEnded", args: [String : Any]())
            }
            default:
                break
            }
    }
    func destroyVideoPlayer(){
        hasInit = false
        if let playerLayer = avPlayerLayer{
            if let player = playerLayer.player{
                player.pause()
                player.removeObserver(self, forKeyPath: "status")
                player.removeObserver(self, forKeyPath: #keyPath(AVPlayer.timeControlStatus))
                player.currentItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
            }
        }
        if let token = timerObserverToken{
            avPlayerLayer?.player?.removeTimeObserver(token)
            timerObserverToken = nil
        }
        NotificationCenter.default.removeObserver(self, name: AVAudioSession.interruptionNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        avPlayerLayer = nil
        pipController?.delegate = nil
        pipController = nil
        resetNowingPlayCenter()
    }
    func enablePipBackgroundMode(enable:Bool = true,result:@escaping FlutterResult){
        if(enable){
            if let playerLayer = avPlayerLayer{
                pipController = AVPictureInPictureController(playerLayer: playerLayer)
                pipController?.delegate=self
                if #available(iOS 14.2, *) {
                    pipController?.canStartPictureInPictureAutomaticallyFromInline=true
                } else {
                    // Fallback on earlier versions
                }
            }
            
        }else{
            pipController?.delegate = nil
            pipController = nil
        }
        result(true)
    }
    func setVideoSpeed(speed:Float){
        if let playerLayer = avPlayerLayer{
            if let player = playerLayer.player{
                player.rate = speed
            }
        }
    }
    func durationAndPosition(result:@escaping FlutterResult){
        if let playerLayer = avPlayerLayer{
            if let player = playerLayer.player{
                let progress = CMTimeGetSeconds(player.currentTime())
                let duration = CMTimeGetSeconds(player.currentItem?.duration ?? CMTime.zero)
                let args : [String:Any] = ["duration":duration,"position":progress]
                result(args)
            }}else{
                let args : [String:Any] = ["duration":0,"position":0]
                result(args)
            }
    }
    func startPip(){
        if let p = pipController{
            printE("startPip")
            
        }else{
            printE("startPip else")
        }
        pipController?.startPictureInPicture()
    }
    func stopPip(){
        pipController?.stopPictureInPicture()
    }
    func onCloseClick(){
        let channel = FlutterMethodChannelManager.shared.videoPlayerChannel()
        channel.invokeMethod("onVideoCloseClick", arguments: nil)
    }
    func onFullScreenClick(){
        let channel = FlutterMethodChannelManager.shared.videoPlayerChannel()
        channel.invokeMethod("onVideoFullScreenClick", arguments: nil)
    }
    public func seekTo(position:Int){
        printE("seekTo===\(position)")
        if let playerLayer = avPlayerLayer{
            if let player = playerLayer.player{
                if(position<self.mDuration){
                    isPlayEnd = false
                    player.seek(to: CMTimeMake(value: Int64(position), timescale: 1), toleranceBefore: CMTimeMake(value: 1, timescale: 2), toleranceAfter: CMTimeMake(value: 1, timescale: 2)){ isFinished in
                        printI("isFinished=\(isFinished)")
                    }
                    updateNowPlayingInfoProgress(Float(position))
                }else{
                    isPlayEnd = false
                    player.seek(to: CMTimeMake(value: Int64(0), timescale: 1), toleranceBefore: CMTimeMake(value: 0, timescale: 1), toleranceAfter: CMTimeMake(value: 0, timescale: 1)){ isFinished in
                        printI("isFinished=\(isFinished)")
                    }
                    updateNowPlayingInfoProgress(Float(0))
                }
            
            }
        }
    }
    public func play(){
        if(isPlayEnd){
            printE("isPlayEnd")
            isPlayEnd=false
            avPlayerLayer?.player?.seek(to:CMTimeMake(value:0, timescale: 1))
        }
        printI("play")
        isPlaying=true
        avPlayerLayer?.player?.play()
    }
    public func pause(){
        isPlaying=false
        avPlayerLayer?.player?.pause()
        self.postNotification(method: "onVideoPlayPaused", args: [String : Any]())
    }
    public func playPause(){
        printE("playPause")
        if(isPlayEnd){
            isPlayEnd=false
            avPlayerLayer?.player?.seek(to:CMTimeMake(value:0, timescale: 1))
        }
        if(isPlaying){
            avPlayerLayer?.player?.pause()
            isPlaying=false
            NotificationCenter.default.post(name: NSNotification.Name("PlayPause"), object: "pause")
        }else{
            avPlayerLayer?.player?.play()
            isPlaying=true
            NotificationCenter.default.post(name: NSNotification.Name("PlayPause"), object: "play")
        }
        if let playerLayer = avPlayerLayer{
            if let player = playerLayer.player{
                let progress = CMTimeGetSeconds(player.currentTime())
                updateNowPlayingInfoProgress(Float(progress))
                createTimers(true)
            }
        }}
    public func backward(){
        if let playerLayer = avPlayerLayer{
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
        if let playerLayer = avPlayerLayer{
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
            return .success
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
        printI("progress====\(progress)")
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = progress
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    @objc func updateProgress(_ updatedTimer: Timer?) {
        if isPlaying {
            if let playerLayer = avPlayerLayer{
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
extension FlutterVideoPlayerManager:AVPictureInPictureControllerDelegate{
    
    public func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
        printE("error=\(error)")
    }
    public func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        //        printI("pictureInPictureControllerWillStartPictureInPicture")
        let channel = FlutterMethodChannelManager.shared.videoPlayerChannel()
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
        }else{
            isRestore = false
        }
    }
    public func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        printE("restoreUserInterfaceForPictureInPictureStopWithCompletionHandler")
        isRestore = true
        onFullScreenClick()
        completionHandler(true)
    }
}
