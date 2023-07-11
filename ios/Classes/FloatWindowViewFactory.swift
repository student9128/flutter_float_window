//
//  FloatWindowViewFactory.swift
//  flutter_float_window
//
//  Created by Kevin Jing on 2023/6/28.
//

import Foundation
import UIKit
class FloatWindowViewFactory: NSObject,FlutterPlatformViewFactory{
    private var messenger: FlutterBinaryMessenger
    
    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }
    
    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return FloatWindowView(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args,
            binaryMessenger: messenger)
    }
    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}
