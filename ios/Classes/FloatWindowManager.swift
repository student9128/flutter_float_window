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
    public var isPlaying = true
    var pipController: AVPictureInPictureController?
    var playerLayerX:AVPlayerLayer?
    var player:AVPlayer?
    func initFloatWindowManager(videoUrl:String){
        let videoURL = URL(string: videoUrl)!
        let player = AVPlayer(url: videoURL)
        playerLayerX = AVPlayerLayer(player: player)
        player.seek(to: CMTimeMake(value: 30, timescale: 1))
        player.play()
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
        
//        initRemoteCommand()
//        initNowingPlayCenter()
    }
    public func startPip(){
        pipController?.startPictureInPicture()
    }
    public func stopPip(){
        pipController?.stopPictureInPicture()
    }
  
    public func play(){
        printI("play")
        isPlaying=true
        playerLayerX?.player?.play()
    }
    public func pause(){
        isPlaying=false
        playerLayerX?.player?.pause()
    }
    public func backward(backwardBtnEnable:(Bool)->Void){
        if let playerLayer = playerLayerX{
            if let player = playerLayer.player{
                let progress = CMTimeGetSeconds(player.currentTime())
                
                if(progress-15>15){
                    backwardBtnEnable(true)
                    player.seek(to:CMTimeMake(value: Int64(progress-15.0), timescale: 1))
                }else{
                    backwardBtnEnable(false)
                    player.seek(to:CMTimeMake(value: 0, timescale: 1))
                }
            }
        }else{
            backwardBtnEnable(false)
        }
        
    }
    public func forward(forwardBtnEnable:(Bool)->Void){
        if let playerLayer = playerLayerX{
            if let player = playerLayer.player{
                let duration = CMTimeGetSeconds(player.currentItem?.duration ?? CMTime.zero)
                let progress = CMTimeGetSeconds(player.currentTime())
                if(duration>0 && duration-progress>15){
                    forwardBtnEnable(true)
                    player.seek(to:CMTimeMake(value: Int64(progress+15.0), timescale: 1))
                }else{
                    forwardBtnEnable(false)
                    player.seek(to:CMTimeMake(value: Int64(duration), timescale: 1))
                }
            }
        }else{
            forwardBtnEnable(false)
        }
    }
    ///关闭
    public func onCloseClick(){
        let channel = FlutterMethodChannelManager.shared.channel()
        channel.invokeMethod("onCloseClick", arguments: nil)
    }
    public func onFullScreenClick(){
        if let playerLayer = playerLayerX{
            if let player = playerLayer.player{
                let progress = CMTimeGetSeconds(player.currentTime())
                let channel = FlutterMethodChannelManager.shared.channel()
                var args=["test":progress*1000]
                channel.invokeMethod("onFullScreenClick", arguments: args)
            }
        }
    }
    public func seekTo(){
        if let playerLayer = playerLayerX{
            if let player = playerLayer.player{
                let progress = CMTimeGetSeconds(player.currentTime())
                player.seek(to:CMTimeMake(value: Int64(progress+15.0), timescale: 1))
            }
        }
//        if(playerLayerX !=nil && playerLayerX!.player !=nil){
//            let progress = CMTimeGetSeconds(playerLayerX!.player!.currentTime())
//            playerLayerX?.player?.seek(to:CMTimeMake(value: Int64(progress+15.0), timescale: 1))
//        }
      
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
//            if isPlaying {
//                let progress = CMTimeGetSeconds(player!.currentTime())
//                player?.seek(to: CMTimeMake(value: Int64(progress - 15.0), timescale: 1))
//                updateNowPlayingInfoProgress(Float(progress))
//            }
            return .success
        }
        commondCenter.skipForwardCommand.addTarget{[unowned self] event in
//            if isPlaying {
//                let progress = CMTimeGetSeconds(player!.currentTime())
//                player?.seek(to: CMTimeMake(value: Int64(progress + 15.0), timescale: 1)){finish in}
//                updateNowPlayingInfoProgress(Float(progress))
//            }
            return .commandFailed
        }
        commondCenter.playCommand.addTarget{[unowned self]event in
//            playPause()
            return .success
//            if player?.rate == 0.0 {
//                playPause()
//                return .success
//            }else{
//                print("播放失败")
//            }
//            return .commandFailed
        }
        commondCenter.pauseCommand.addTarget{ [unowned self]event in
//            playPause()
            return .success
//            if player?.rate == 1.0 {
//                playPause()
//                return .success
//            }else{
//                print("暂停失败")
//            }
//            return .commandFailed
        }
    }
    func initNowingPlayCenter(){
        
//        if let url = URL(string: imageUrl ?? "") {
//            downloadImage(url:url) { image in
//                self.nowPlayingInfo[MPMediaItemPropertyArtwork] =
//                MPMediaItemArtwork(boundsSize: image.size) { size in
//                    return image
//                }
//                MPNowPlayingInfoCenter.default().nowPlayingInfo = self.nowPlayingInfo
//            }
//        }
        var nowPlayingInfo = [String : Any]()
        let totalDuration = Float (60000 / 1000)
        nowPlayingInfo[MPMediaItemPropertyTitle] = "title"
        nowPlayingInfo[MPMediaItemPropertyArtist] = "artist"
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = "albumTitle"
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = "10000"
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = 0
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    
}
extension FloatWindowManager:AVPictureInPictureControllerDelegate{
    
    public func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
    printE("error=\(error)")
    }
    public func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        printI("pictureInPictureControllerWillStartPictureInPicture")
        let channel = FlutterMethodChannelManager.shared.channel()
        var args=["test":"start"]
        channel.invokeMethod("onPictureInPictureWillStart", arguments: args)
    }
    public func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        printI("pictureInPictureControllerDidStartPictureInPicture")
    }
    public func pictureInPictureControllerWillStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        printI("pictureInPictureControllerWillStopPictureInPicture")
    }
    public func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        printI("pictureInPictureControllerDidStopPictureInPicture")
    }
    public func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        printE("pictureInPictureControllerDidStopPictureInPicture")
        if let playerLayer = playerLayerX{
            if let player = playerLayer.player{
                let progress = CMTimeGetSeconds(player.currentTime())
//                player.seek(to:CMTimeMake(value: Int64(progress+15.0), timescale: 1))
                let channel = FlutterMethodChannelManager.shared.channel()
                var args=["test":progress*1000]
                channel.invokeMethod("onFullScreenClick", arguments: args)
            }
        }
   
        completionHandler(true)
    }
}
