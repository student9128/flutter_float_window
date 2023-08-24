//
//  FlutterVideoPlayerView.swift
//  flutter_float_window
//
//  Created by Kevin Jing on 2023/8/21.
//

import Foundation
import UIKit
import AVKit
import AVFoundation
class FlutterVideoPlayerView : NSObject,FlutterPlatformView{
    private var _view: UIView
    func view() -> UIView {
        return _view
    }
    init( frame: CGRect,
          viewIdentifier viewId: Int64,
          arguments args: Any?,
          binaryMessenger messenger: FlutterBinaryMessenger?){
        _view = VideoPlayerView.shared
        super.init()
        VideoPlayerView.shared.layoutSubviews()
        //       if args is Dictionary<String,Any>?{
        //           let dic = args as! Dictionary<String,Any>
        //           let url = dic["videoUrl"] as? String
        //           if let videoUlr=url{
        //               let title = dic["title"] as? String
        //               let artist = dic["artist"] as? String
        //               let coverUrl = dic["coverUrl"] as? String
        //               let currentPosition = dic["position"] as? Int
        //               let duration = dic["duration"] as? Int
        //               let speed = dic["speed"] as? Float
        //               printE("initVideoPlayer======")
        //               FlutterVideoPlayerManager.shared.initVideoPlayer(videoUrl: videoUlr,title: title ?? "",artist: artist ?? "",coverUrl:coverUrl ?? "",position:currentPosition ?? 0,speed: speed ?? 1.0)
            _view.layer.addSublayer(FlutterVideoPlayerManager.shared.avPlayerLayer!)
        //
        //           }
        
    }
    @objc func handleNotification(notification:Notification){
        printW("video notification=\(notification)")
    }
    
    
}
class VideoPlayerView : UIView{
    static let shared = VideoPlayerView()
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        printE("initVideoPlayer=====VideoPlayerView=")
        //        self.layer.addSublayer(FlutterVideoPlayerManager.shared.avPlayerLayer!)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func layoutSubviews() {
        FlutterVideoPlayerManager.shared.avPlayerLayer?.frame = frame
        super.layoutSubviews()
        
        printE("initVideoPlayer=====VideoPlayerView12=\(frame)")
    }
}
