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
    var pipController: AVPictureInPictureController?
    var playerLayerX:AVPlayerLayer?
    var player:AVPlayer?
    func initFloatWindowManager(videoUrl:String){
        let videoURL = URL(string: videoUrl)!
        let player = AVPlayer(url: videoURL)
        playerLayerX = AVPlayerLayer(player: player)
        player.play()
        do {
             try AVAudioSession.sharedInstance().setCategory(.playback)
//             try AVAudioSession.sharedInstance().setActive(true, options: [])
         } catch {
             printE("AVAudioSession发生错误")
         }
        pipController = AVPictureInPictureController(playerLayer: playerLayerX!)
        pipController?.delegate=self
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
        playerLayerX?.player?.play()
        if((playerLayerX?.isReadyForDisplay) != nil){
            playerLayerX?.player?.play()
        }else{
            printI("XXX==")
        }
    }
    public func pause(){
        
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
}
