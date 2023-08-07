//
//  FlutterAgoraLiveView.swift
//  flutter_float_window
//
//  Created by Kevin Jing on 2023/7/31.
//

import Foundation
import UIKit
import AgoraRtcKit
class FlutterAgoraLiveView: NSObject,FlutterPlatformView{
    private var _view: UIView
    func view() -> UIView {
        return _view
    }
    init(frame: CGRect,
         viewIdentifier viewId: Int64,
         arguments args: Any?,
         binaryMessenger messenger: FlutterBinaryMessenger?){
        _view = AgoraLiveView.shared
        super.init()
        printE("FlutterAgoraLiveView====create")
        AgoraLiveView.shared.layoutSubviews()
        
    }
    deinit{
        printW("FlutterAgoraLiveView===deinit")
    }
    
}
class AgoraLiveView: UIView{
    static let shared = AgoraLiveView()
    let remoteView: AgoraSampleBufferRender=AgoraSampleBufferRender()
    let windowLeaveChannelView = UIView()
    var isLiveOver = false
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        windowLeaveChannelView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        let windowLiveOverText = UITextView()
        windowLiveOverText.text = "直播已结束";
        windowLiveOverText.textAlignment = .center
        windowLiveOverText.font = UIFont.systemFont(ofSize: 14)
        windowLiveOverText.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0)
        windowLiveOverText.textColor = UIColor(hex: "#FFECC8")
        windowLeaveChannelView.addSubview(windowLiveOverText)
        windowLiveOverText.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([windowLiveOverText.centerXAnchor.constraint(equalTo: windowLeaveChannelView.centerXAnchor),
                                     windowLiveOverText.centerYAnchor.constraint(equalTo: windowLeaveChannelView.centerYAnchor),
                                     windowLiveOverText.widthAnchor.constraint(equalToConstant: 100),
                                     windowLiveOverText.heightAnchor.constraint(equalToConstant: 30)])
        
        
        self.addSubview(remoteView)
        printE("AgoraLiveView===init")
        remoteView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            remoteView.widthAnchor.constraint(equalTo: self.widthAnchor),
            remoteView.heightAnchor.constraint(equalTo: self.heightAnchor)
        ])
        FlutterAgoraLiveManager.shared.initPip(view: remoteView)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotification), name:NSNotification.Name.init("agoraNotification") , object: nil)
    }
    deinit{
        printW("AgoraLiveView 也deinit了吗")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func layoutSubviews() {
        printE("agoraLiveView layoutSubviews \(frame)")
        remoteView.frame = frame
        super.layoutSubviews()
        
        self.addSubview(remoteView)
        FlutterAgoraLiveManager.shared.agoraKit?.setVideoFrameDelegate(self)
//        FlutterAgoraLiveManager.shared.initPip(view: remoteView)

        
    }
    @objc func handleNotification(notification:Notification){
        printW("notification=\(notification)")
        if let result = notification.object as? String{
            switch (result){
            case "delegateVideoStream":
                if let agoraKit:AgoraRtcEngineKit = FlutterAgoraLiveManager.shared.agoraKit{
                    printE("agoraKit===走了吗================")
                    agoraKit.setVideoFrameDelegate(self)
                }
                break
            case "onUserJoined":
                if let agoraKit:AgoraRtcEngineKit = FlutterAgoraLiveManager.shared.agoraKit{
                    printE("agoraKit===走了吗===12=============")
                    agoraKit.setVideoFrameDelegate(self)
                }
                isLiveOver = false
//                liveView.isHidden = false
//                leaveChannelView.isHidden = true
                windowLeaveChannelView.isHidden = true
//                windowLiveView.isHidden = false
                remoteView.reset()
                //                if let userInfo = notification.userInfo{
                //                    if userInfo["uid"] is UInt{
                ////                        let videoCanvas = AgoraRtcVideoCanvas()
                ////                        videoCanvas.uid = uid
                ////                        videoCanvas.renderMode = .hidden
                ////                        videoCanvas.view = remoteView
                ////                        FloatLiveWindowManager.shared.agoraKit?.setupRemoteVideo(videoCanvas)
                ////                        printD("uid====\(uid)")
                ////
                //
                //                    }
                //
                //                }
                break
            case "onUserOffline":
                printE("remoteUserLeaveChannel")
                isLiveOver = true
//                //主播离开直播间
//                liveView.isHidden = true
//                leaveChannelView.isHidden = false
                windowLeaveChannelView.isHidden=false
//                windowLiveView.isHidden = true
                break
            case "pipWillStart":
                if let window = UIApplication.shared.windows.first{
                    printW("pipWillStrt走了aaaaaaaaaaaaaa,\(window.bounds.width),\(window.bounds.height)")
//                    windowLeaveChannelView.backgroundColor = UIColor.red
//                    let windowLiveOverText = UITextView()
//                    windowLiveOverText.text = "直播已结束";
//                    windowLiveOverText.textAlignment = .center
//                    windowLiveOverText.font = UIFont.systemFont(ofSize: 14)
//                    windowLiveOverText.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0)
//                    windowLiveOverText.textColor = UIColor(hex: "#FFECC8")
//                    windowLeaveChannelView.addSubview(windowLiveOverText)
//                    windowLiveOverText.translatesAutoresizingMaskIntoConstraints = false
//                    NSLayoutConstraint.activate([windowLiveOverText.centerXAnchor.constraint(equalTo: windowLeaveChannelView.centerXAnchor),
//                                                 windowLiveOverText.centerYAnchor.constraint(equalTo: windowLeaveChannelView.centerYAnchor),
//                                                 windowLiveOverText.widthAnchor.constraint(equalToConstant: 100),
//                                                 windowLiveOverText.heightAnchor.constraint(equalToConstant: 30)])
                    window.addSubview(windowLeaveChannelView)
                    windowLeaveChannelView.translatesAutoresizingMaskIntoConstraints = false
                    NSLayoutConstraint.activate([
                        windowLeaveChannelView.widthAnchor.constraint(equalTo: window.widthAnchor),
                        windowLeaveChannelView.heightAnchor.constraint(equalTo: window.heightAnchor)])
//
//                    window.addSubview(windowLiveView)
//                    windowLiveView.translatesAutoresizingMaskIntoConstraints = false
//                    NSLayoutConstraint.activate([
//                        windowLiveView.widthAnchor.constraint(equalToConstant: 65),
//                        windowLiveView.heightAnchor.constraint(equalToConstant: 30)])
                    if(isLiveOver){
                        windowLeaveChannelView.isHidden = false
//                        windowLiveView.isHidden = true
                    }else{
                        windowLeaveChannelView.isHidden = true
//                        windowLiveView.isHidden = false
                    }
                    
                }else{
                    printW("pipWillStrt走了else aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
                }
                break
            case "initPiP":
                FlutterAgoraLiveManager.shared.initPip(view: remoteView)
                break
            default:
                break
            }
            
        }
    }
}
extension AgoraLiveView:AgoraVideoFrameDelegate{
    func onCapture(_ videoFrame: AgoraOutputVideoFrame, sourceType: AgoraVideoSourceType) -> Bool {
        true
    }
    func onRenderVideoFrame(_ videoFrame: AgoraOutputVideoFrame, uid: UInt, channelId: String) -> Bool {
//        printI("onRenderVideoFrame")
        remoteView.renderVideoPixelBuffer(videoFrame)
        return true
    }
    func getVideoFormatPreference() -> AgoraVideoFormat {
        .cvPixelBGRA
    }
    func getRotationApplied() -> Bool {
        true
    }
}
