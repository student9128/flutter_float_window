import UIKit
import Flutter
import flutter_float_window
import AVFoundation
import Foundation
@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        GeneratedPluginRegistrant.register(with: self)
        //      let audioSession = AVAudioSession.sharedInstance()
        //      do {
        //          try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default,options: [.allowAirPlay, .allowBluetooth])
        //          try AVAudioSession.sharedInstance().setActive(true)
        //      } catch {
        //          printE("Error setting category or activating audio session: \(error.localizedDescription)")
        //      }
//                 UIApplication.shared.beginReceivingRemoteControlEvents()
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    override func applicationWillResignActive(_ application: UIApplication) {
        printI("application===applicationWillResignActive")
        //        DispatchQueue.main.asyncAfter(deadline: .now()+1){
        //            FloatWindowManager.shared.startPip()
        //        }
        
    }
    override func applicationWillEnterForeground(_ application: UIApplication) {
    }
    override func applicationDidEnterBackground(_ application: UIApplication) {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
//            try AVAudioSession.sharedInstance().setActive(true,options:.notifyOthersOnDeactivation)
        } catch {
            printE("进入后台的时候Failed to enable background audio.")
        }
    }
    override func applicationDidBecomeActive(_ application: UIApplication) {
    }
    override func applicationWillTerminate(_ application: UIApplication) {
    }
}
