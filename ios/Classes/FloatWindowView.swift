//
//  FloatWindowView.swift
//  flutter_float_window
//
//  Created by Kevin Jing on 2023/6/28.
//

import Foundation
import UIKit
import AVKit
import AVFoundation
class FloatWindowView : NSObject,FlutterPlatformView{
    private var _view: UIView

      init(
          frame: CGRect,
          viewIdentifier viewId: Int64,
          arguments args: Any?,
          binaryMessenger messenger: FlutterBinaryMessenger?
      ) {
//          _view = UIView()
          _view = TestView()
          super.init()
          let channel = FlutterMethodChannel(name: "flutter_float_window", binaryMessenger: messenger!)
          channel.setMethodCallHandler { call, result in
              self.handle(call, result: result)
          }
          printE("frame=\(frame)")
          // iOS views can be created here
          printW("args=\(String(describing: args))")
//          if let paragms = args as? [String:Any]{
//              let text =  paragms["text"]
//              printI("flutter传参\(text)")
//          }
//          if let XX = args as? Dictionary<String,Any>?{
//              let text =  XX!["text"]
//              printI("flutter传参23\(text)")
//          }
          if args is Dictionary<String,Any>?{
              let dic = args as! Dictionary<String,Any>
              printI("flutter的传参：\(String(describing: dic["text"])),\(String(describing: dic["hello"]))")
              let nativeLabel = UILabel()
              nativeLabel.text = "\(dic["text"] as! String)\(dic["hello"] as! String)"
              nativeLabel.textColor = UIColor.white
//              nativeLabel.frame=CGRect(x: 0, y: 50, width: 180, height: 50)
              _view.addSubview(nativeLabel)
          }
//          createNativeView(view: _view,frame: frame)
      }

      func view() -> UIView {
          return _view
      }
    deinit {
        printE("走了吗XXXXX")
    }
//    var pipController:AVPictureInPictureController!
    func createNativeView(view _view: UIView,frame:CGRect){
          _view.backgroundColor = UIColor.blue
          let nativeLabel = UILabel()
          nativeLabel.text = "Native text from iOS"
          nativeLabel.textColor = UIColor.white
          nativeLabel.textAlignment = .center
          nativeLabel.frame = CGRect(x: 0, y: 0, width: 180, height: 48.0)
          let url = "https://live.idbhost.com/05d2556e74e9408db0ee370b41536282/d4d54975f8a34b21bd9061ac0464a092-bafd00dba653149fda08dc8743bf8820-sd.mp4"
          let width = UIScreen.main.bounds.size.width
          let height = UIScreen.main.bounds.size.height
          let playerItem = AVPlayerItem(url:URL(string: url)!)
          let videoURL = URL(string: url)!
          let player = AVPlayer(url: videoURL)
          let playerLayer = AVPlayerLayer(player: player)
          printI("frame=\(frame)")
          playerLayer.frame=CGRect(x: 0, y: 0, width: 200, height: 300)
//          _view.addSubview(player)
//          FloatWindowManager.shared.initFloatWindowManager(playerLayer: playerLayer)
//          pipController = AVPictureInPictureController(playerLayer: playerLayer)
//          pipController.delegate=self
          _view.layer.addSublayer(playerLayer)
          printI("player=\(playerLayer),\(player)")
          player.play()
//          do {
//              try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback,mode: AVAudioSession.Mode.default)
//                try AVAudioSession.sharedInstance().setActive(true)
//            } catch {
//                printE("初始化的时候Failed to enable background audio.")
//            }
          
      }
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        printD("floatwindowview call method=\(call.method)")
        switch (call.method) {
        case "canShowFloatWindow":
            break
        case "showFloatWindow":
            FloatWindowManager.shared.startPip()
//            printW("possible=\(pipController.isPictureInPicturePossible)")
//            pipController.startPictureInPicture()
            break
        case "hideFloatWindow":
//            pipController.startPictureInPicture()
            break
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
}
class TestView:UIView{
    let _nativeLabel = UILabel()
    var playerLayer:AVPlayerLayer?
    override init(frame: CGRect) {
        super.init(frame:frame)
        _nativeLabel.text = "Native text from iOS测试"
          _nativeLabel.textColor = UIColor.white
          _nativeLabel.backgroundColor = UIColor.red
          _nativeLabel.textAlignment = .center
          _nativeLabel.frame = CGRect.zero
          self.addSubview(_nativeLabel)
        
        let url = "https://live.idbhost.com/05d2556e74e9408db0ee370b41536282/d4d54975f8a34b21bd9061ac0464a092-bafd00dba653149fda08dc8743bf8820-sd.mp4"
        let width = UIScreen.main.bounds.size.width
        let height = UIScreen.main.bounds.size.height
        let playerItem = AVPlayerItem(url:URL(string: url)!)
//        let videoURL = URL(string: url)!
//        let player = AVPlayer(url: videoURL)
//        playerLayer = AVPlayerLayer(player: player)
//        printI("frame=\(frame)")
        FloatWindowManager.shared.initFloatWindowManager(videoUrl: url)
        
//          _view.addSubview(player)
//        FloatWindowManager.shared.initFloatWindowManager(playerLayer: playerLayer!)
//          pipController = AVPictureInPictureController(playerLayer: playerLayer)
//          pipController.delegate=self
        self.layer.addSublayer(FloatWindowManager.shared.playerLayerX!)
//        printI("player=\(playerLayer!),\(player)")
//        player.play()
   
    }
    
    required init?(coder: NSCoder) {
       super.init(coder: coder)
     }
    override func layoutSubviews() {
        print("current frame: \(self.frame)")
//        _nativeLabel.frame = CGRect(x: 10, y: 10, width: self.frame.width-20, height: self.frame.height-20)
//        playerLayer?.frame=frame
        FloatWindowManager.shared.playerLayerX?.frame=frame
        super.layoutSubviews()
    }
    
    deinit {
        printE("是否走了deinit")
    }
}

//extension FloatWindowView: AVPictureInPictureControllerDelegate{
//    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, failedToStartPictureInPictureWithError error: Error) {
//        printE("pictureInPictureController erro=\(error)")
//    }
//    func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
//
//    }
//    func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
//
//    }
//    func pictureInPictureControllerWillStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
//
//    }
//    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
//
//    }
//}
