//
//  AppDelegate.swift
//  ffmpeg-test-ios-swift
//
//  Created by Mark Khmelnitskii on 01.07.2022.
//

import UIKit
import ffmpegkit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    //MARK: ERROR!!!
//    static func listFFprobeSessions() {
//        guard let ffprobeSessions = FFprobeKit.listFFprobeSessions() as? [AnyObject] else { return }
//        print("Listing FFprobe sessions")
//
//        for (i, session) in ffprobeSessions.enumerated() {
//            let startTime: String = session.getStartTime()
//            print("Session \(i) = id: \(session.getSessionId()), startTime: \(startTime), duration: \(session.getDuration()), state: \(FFmpegKitConfig.sessionState(toString: session.getState()) ?? ""), returnCode: \(String(describing: session.getReturnCode()))")
//        }
//
//        print("Listed FFprobe sessions")
//    }
    
//    static func listFFmpegSessions() {
//        guard let ffmpegSessions = FFmpegKit.listSessions() as? [AnyObject] else { return }
//        print("Listing FFmpeg sessions")
//
//        for (i, session) in ffmpegSessions.enumerated() {
//            let startTime: String = session.getStartTime()
//            print("Session \(i) = id: \(session.getSessionId()), startTime: \(startTime), duration: \(session.getDuration()), state: \(FFmpegKitConfig.sessionState(toString: session.getState()) ?? ""), returnCode: \(String(describing: session.getReturnCode()))")
//        }
//
//        print("Listed FFmpeg sessions")
//    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        //MARK: font for subtitles in video (dont need to me)
        //let resourceFolder:String! = NSBundle.mainBundle().resourcePath()
        //let fontNameMapping:NSDictionary! = ["MyFontName" : "Doppio One"]
        //FFmpegKitConfig.setFontDirectoryList([AnyObject](objects:resourceFolder, "/System/Library/Fonts", nil), with:fontNameMapping)
        FFmpegKitConfig.ignore(Signal.xcpu)
        FFmpegKitConfig.logLevel(toString: Int32(Level.avLogInfo.rawValue))
        return true
    }
}
