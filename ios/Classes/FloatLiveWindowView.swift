//
//  FloatLiveWindowView.swift
//  flutter_float_window
//
//  Created by Kevin Jing on 2023/7/18.
//

import Foundation
import UIKit
import AgoraRtcKit
class FloatLiveWindowView: NSObject,FlutterPlatformView{
    private var _view: UIView
    func view() -> UIView {
        return _view
    }
    
    init(frame: CGRect,
         viewIdentifier viewId: Int64,
         arguments args: Any?,
         binaryMessenger messenger: FlutterBinaryMessenger?){
        _view = FloatLiveView()
        super.init();
        printE("FloatLiveWindowView")
        _view.layer.cornerRadius=14
        _view.clipsToBounds=true
        let channel = FlutterMethodChannelManager.shared.registerMethodChannel(binaryMessenger: messenger!)
        channel.setMethodCallHandler { call, result in
            self.handle(call, result: result)}
        printE("args=\(String(describing: args))")
        if args is Dictionary<String,Any>?{
            let dic = args as! Dictionary<String,Any>
            let appId = dic["appId"] as? String
            let token = dic["token"] as? String
            let channelName = dic["channelName"] as? String
            let optionalUid = dic["optionalUid"] as? Int
            let title = dic["title"] as? String
            let artist = dic["artist"] as? String
            let coverUrl = dic["coverUrl"] as? String
            if let id = appId,let t = token,let cn = channelName,let oUid = optionalUid{
                printI("zou le ma")
                FloatLiveWindowManager.shared.initFloatLiveWindowManager(appId: id, token: t, channelName: cn,optionalUid: oUid,title: title ?? "",artist: artist ?? "",coverUrl:coverUrl ?? "")
                FloatLiveWindowManager.shared.joinChannel()
            }
        }
        
    }
    public func handle(_ call: FlutterMethodCall,result:@escaping FlutterResult){
        printD("FloatLiveWindowView call method:\(call.method), args:\(String(describing: call.arguments))")
        switch (call.method){
        case "showFloatWindow":
            FloatLiveWindowManager.shared.startPip()
            break
        case "leaveChannel":
            FloatLiveWindowManager.shared.leavelChannel()
            break
        default:
            break
        }
    }
    
}
class FloatLiveView: UIView{
    let remoteView: AgoraSampleBufferRender=AgoraSampleBufferRender()
    let closeContainer = UIView()
    let pipExitContainer = UIView()
    let pipExitImageView = UIImageView(image: UIImage(systemName:"pip.exit"))
    let closeImageView = UIImageView(image: UIImage(systemName:"xmark"))
    
    let liveView = UIView()
    let windowLiveView = UIView()
    let leaveChannelView = UIView()
    let windowLeaveChannelView = UIView()
    var isLiveOver = false
    var isButtonShown = true
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        leaveChannelView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        self.addSubview(leaveChannelView)
        leaveChannelView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            leaveChannelView.widthAnchor.constraint(equalTo: self.widthAnchor),
            leaveChannelView.heightAnchor.constraint(equalTo: self.heightAnchor)])
        
        let liveOverText = UITextView()
        liveOverText.text = "直播已结束";
        liveOverText.textAlignment = .center
        liveOverText.font = UIFont.systemFont(ofSize: 14)
        liveOverText.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0)
        liveOverText.textColor = UIColor(hex: "#FFECC8")
        leaveChannelView.addSubview(liveOverText)
        liveOverText.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([liveOverText.centerXAnchor.constraint(equalTo: leaveChannelView.centerXAnchor),
                                     liveOverText.centerYAnchor.constraint(equalTo: leaveChannelView.centerYAnchor),
                                     liveOverText.widthAnchor.constraint(equalToConstant: 100),
                                     liveOverText.heightAnchor.constraint(equalToConstant: 30)])
        
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
        
        let windowTextView = UITextView()
        windowTextView.text="直播中"
        windowTextView.textAlignment = .center
        windowTextView.textColor = UIColor(hex: "#FFECC8")
        windowTextView.backgroundColor=UIColor.red
        windowLiveView.addSubview(windowTextView)
        windowLiveView.layer.cornerRadius=10
        windowLiveView.clipsToBounds = true
        windowTextView.translatesAutoresizingMaskIntoConstraints=false
        NSLayoutConstraint.activate([
            windowTextView.widthAnchor.constraint(equalTo:windowLiveView.widthAnchor),
            windowTextView.heightAnchor.constraint(equalTo:windowLiveView.heightAnchor)])
        
        self.addSubview(liveView)
        liveView.translatesAutoresizingMaskIntoConstraints=false
        NSLayoutConstraint.activate([
            liveView.widthAnchor.constraint(equalToConstant: 65),
            liveView.heightAnchor.constraint(equalToConstant: 30),
            liveView.leftAnchor.constraint(equalTo: self.leftAnchor),
            liveView.topAnchor.constraint(equalTo: self.topAnchor)])
        let textView = UITextView()
        textView.text="直播中"
        textView.textAlignment = .center
        textView.textColor = UIColor(hex: "#FFECC8")
        textView.backgroundColor=UIColor.red
        liveView.addSubview(textView)
        liveView.layer.cornerRadius=10
        liveView.clipsToBounds = true
        textView.translatesAutoresizingMaskIntoConstraints=false
        NSLayoutConstraint.activate([
            textView.widthAnchor.constraint(equalTo:liveView.widthAnchor),
            textView.heightAnchor.constraint(equalTo:liveView.heightAnchor)])
        
        self.addSubview(remoteView)
        remoteView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            remoteView.widthAnchor.constraint(equalTo: self.widthAnchor),
            remoteView.heightAnchor.constraint(equalTo: self.heightAnchor)
        ])
        
        pipExitImageView.tintColor = UIColor.white
        closeImageView.tintColor = UIColor.white
        
        pipExitContainer.addSubview(pipExitImageView)
        pipExitImageView.translatesAutoresizingMaskIntoConstraints=false
        NSLayoutConstraint.activate([
            pipExitImageView.widthAnchor.constraint(equalToConstant: 25),
            pipExitImageView.heightAnchor.constraint(equalToConstant: 20),
            pipExitImageView.centerXAnchor.constraint(equalTo: pipExitContainer.centerXAnchor),
            pipExitImageView.centerYAnchor.constraint(equalTo: pipExitContainer.centerYAnchor)
        ])
        closeContainer.addSubview(closeImageView)
        closeImageView.translatesAutoresizingMaskIntoConstraints=false
        NSLayoutConstraint.activate([
            closeImageView.widthAnchor.constraint(equalToConstant: 20),
            closeImageView.heightAnchor.constraint(equalToConstant: 22),
            closeImageView.centerXAnchor.constraint(equalTo: closeContainer.centerXAnchor),
            closeImageView.centerYAnchor.constraint(equalTo: closeContainer.centerYAnchor)
        ])
        
        self.addSubview(pipExitContainer)
        self.addSubview(closeContainer)
        pipExitContainer.translatesAutoresizingMaskIntoConstraints=false
        closeContainer.translatesAutoresizingMaskIntoConstraints=false
        NSLayoutConstraint.activate([
            pipExitContainer.widthAnchor.constraint(equalToConstant: 45),
            pipExitContainer.heightAnchor.constraint(equalToConstant: 40),
            pipExitContainer.topAnchor.constraint(equalTo: self.topAnchor,constant: 0),
            pipExitContainer.rightAnchor.constraint(equalTo: self.rightAnchor,constant: 0),
            
            closeContainer.widthAnchor.constraint(equalToConstant: 40),
            closeContainer.heightAnchor.constraint(equalToConstant: 42),
            closeContainer.topAnchor.constraint(equalTo: self.topAnchor,constant: 0),
            closeContainer.leftAnchor.constraint(equalTo: self.leftAnchor,constant: 0),
        ])
        
        let currentViewClick = UITapGestureRecognizer(target: self, action: #selector(onCurrentViewClick))
        self.isUserInteractionEnabled=true
        self.addGestureRecognizer(currentViewClick)
        
        let fullScreenClick = UITapGestureRecognizer(target: self, action: #selector(onFullScreenClick))
        pipExitContainer.isUserInteractionEnabled=true
        pipExitContainer.addGestureRecognizer(fullScreenClick)
        
        let closeClick = UITapGestureRecognizer(target: self, action: #selector(onCloseClick))
        closeContainer.isUserInteractionEnabled=true
        closeContainer.addGestureRecognizer(closeClick)
        
        printD("FloatLiveView")
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotification), name:NSNotification.Name.init("agoraNotification") , object: nil)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func layoutSubviews() {
        remoteView.frame = frame
        printD("FloatLiveView layoutSubviews \(frame)")
        super.layoutSubviews()
        
        self.addSubview(remoteView)
        self.addSubview(liveView)
        liveView.isHidden = false
        self.addSubview(leaveChannelView)
        leaveChannelView.isHidden = true
        self.addSubview(pipExitContainer)
        self.addSubview(closeContainer)
        FloatLiveWindowManager.shared.agoraKit?.setVideoFrameDelegate(self)
        FloatLiveWindowManager.shared.initPip(view: remoteView)
    }
    var mTimer:Timer?
    override func didMoveToWindow() {
        hideButton()
        
    }
    func hideButton(){
        if(mTimer != nil){
            mTimer?.invalidate()
        }
        mTimer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(handleTimer), userInfo: nil, repeats: false)
    }
    func toggleButton(){
        FloatWindowManager.shared.updateForwardAndBackwardBtnStatus()
        if(isButtonShown){
            hiddenButton()
        }else{
            pipExitContainer.isHidden = false
            closeContainer.isHidden = false
            isButtonShown = true
            hideButton()
        }
    }
    func hiddenButton(){
        pipExitContainer.isHidden = true
        closeContainer.isHidden = true
        isButtonShown = false
    }
    @objc func handleTimer(){
        hiddenButton()
    }
    @objc func handleNotification(notification:Notification){
        printW("notification=\(notification)")
        if let result = notification.object as? String{
            switch (result){
            case "didJoinedOfUid":
                isLiveOver = false
                liveView.isHidden = false
                leaveChannelView.isHidden = true
                windowLeaveChannelView.isHidden = true
                windowLiveView.isHidden = false
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
            case "remoteUserLeaveChannel":
                printE("remoteUserLeaveChannel")
                isLiveOver = true
                //主播离开直播间
                liveView.isHidden = true
                leaveChannelView.isHidden = false
                windowLeaveChannelView.isHidden=false
                windowLiveView.isHidden = true
                break
            case "pipWillStart":
                if let window = UIApplication.shared.windows.first{
                    window.addSubview(windowLeaveChannelView)
                    windowLeaveChannelView.translatesAutoresizingMaskIntoConstraints = false
                    NSLayoutConstraint.activate([
                        windowLeaveChannelView.widthAnchor.constraint(equalTo: window.widthAnchor),
                        windowLeaveChannelView.heightAnchor.constraint(equalTo: window.heightAnchor)])
                    
                    window.addSubview(windowLiveView)
                    windowLiveView.translatesAutoresizingMaskIntoConstraints = false
                    NSLayoutConstraint.activate([
                        windowLiveView.widthAnchor.constraint(equalToConstant: 65),
                        windowLiveView.heightAnchor.constraint(equalToConstant: 30)])
                    if(isLiveOver){
                        windowLeaveChannelView.isHidden = false
                        windowLiveView.isHidden = true
                    }else{
                        windowLeaveChannelView.isHidden = true
                        windowLiveView.isHidden = false
                    }
                    
                }
                break
            default:
                break
            }
            
        }
    }
    @objc func onCloseClick(){
        NotificationCenter.default.removeObserver(self)
        FloatLiveWindowManager.shared.onCloseClick()
    }
    
    @objc func onFullScreenClick(){
        printE("onFullScreenClick")
        NotificationCenter.default.removeObserver(self)
        FloatLiveWindowManager.shared.onFullScreenClick()
        
    }
    @objc func onCurrentViewClick(){
        mTimer?.invalidate()
        toggleButton()
        
    }
}
extension FloatLiveView: AgoraVideoFrameDelegate{
    func onCapture(_ videoFrame: AgoraOutputVideoFrame, sourceType: AgoraVideoSourceType) -> Bool {
        true
    }
    func onRenderVideoFrame(_ videoFrame: AgoraOutputVideoFrame, uid: UInt, channelId: String) -> Bool {
        printI("onRenderVideoFrame")
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
extension UIColor {
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        var hexValue = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        if hexValue.count == 6 {
            hexValue = "FF" + hexValue
        }
        
        var color: UInt64 = 0
        Scanner(string: hexValue).scanHexInt64(&color)
        
        let red = CGFloat((color & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((color & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(color & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
