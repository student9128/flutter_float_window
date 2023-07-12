//
//  FlutterMethodChannelManager.swift
//  flutter_float_window
//
//  Created by Kevin Jing on 2023/7/6.
//

import Foundation
class FlutterMethodChannelManager: NSObject{
    public static let shared = FlutterMethodChannelManager()
    private override init() {
    }
    private var _channel:FlutterMethodChannel?
    func channel()->FlutterMethodChannel{
        return _channel!
    }
    func registerMethodChannel(name:String,binaryMessenger messenger: FlutterBinaryMessenger?)->FlutterMethodChannel{
        self._channel = FlutterMethodChannel(name: "flutter_float_window", binaryMessenger: messenger!)
        return _channel!
    }
}
