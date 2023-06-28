//
//  FloatWindowView.swift
//  flutter_float_window
//
//  Created by Kevin Jing on 2023/6/28.
//

import Foundation
import UIKit
class FloatWindowView : NSObject,FlutterPlatformView{
    private var _view: UIView

      init(
          frame: CGRect,
          viewIdentifier viewId: Int64,
          arguments args: Any?,
          binaryMessenger messenger: FlutterBinaryMessenger?
      ) {
          _view = UIView()
          super.init()
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
              nativeLabel.frame=CGRect(x: 0, y: 50, width: 180, height: 50)
              _view.addSubview(nativeLabel)
          }
          createNativeView(view: _view)
      }

      func view() -> UIView {
          return _view
      }

      func createNativeView(view _view: UIView){
          _view.backgroundColor = UIColor.blue
          let nativeLabel = UILabel()
          nativeLabel.text = "Native text from iOS"
          nativeLabel.textColor = UIColor.white
          nativeLabel.textAlignment = .center
          nativeLabel.frame = CGRect(x: 0, y: 0, width: 180, height: 48.0)
          _view.addSubview(nativeLabel)
      }
}
