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
        printE("怎么走的")
        printW("args=12\(String(describing: args))")
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
