//
//  SceneDelegate.swift
//  ffmpeg-test-ios-swift
//
//  Created by Mark Khmelnitskii on 01.07.2022.
//

import UIKit
import ffmpegkit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let vc1 = CommandViewController()
        let vc2 = VideoViewController()
        let vc3 = HttpsViewController()
        let vc4 = AudioViewController()
        let vc5 = SubtitleViewController()
        let vc6 = VidStabViewController()
        let vc7 = PipeViewController()
        let vc8 = ConcurrentExecutionViewController()
        let vc9 = OtherViewController()
        
        vc1.tabBarItem = UITabBarItem(title: "COMMAND", image: nil, tag: 1)
        vc2.tabBarItem = UITabBarItem(title: "VIDEO", image: nil, tag: 2)
        vc3.tabBarItem = UITabBarItem(title: "HTTPS", image: nil, tag: 3)
        vc4.tabBarItem = UITabBarItem(title: "AUDIO", image: nil, tag: 4)
        vc5.tabBarItem = UITabBarItem(title: "SUBTITLE", image: nil, tag: 5)
        vc6.tabBarItem = UITabBarItem(title: "VID.STAB", image: nil, tag: 6)
        vc7.tabBarItem = UITabBarItem(title: "PIPE", image: nil, tag: 7)
        vc8.tabBarItem = UITabBarItem(title: "CONCURRENT", image: nil, tag: 8)
        vc9.tabBarItem = UITabBarItem(title: "OTHER", image: nil, tag: 9)
        let tabbarList = [vc1, vc2, vc3, vc4, vc5, vc6, vc7, vc8, vc9]
        // SELECTED BAR ITEM
        UITabBarItem.appearance().setTitleTextAttributes([.foregroundColor : UIColor(red:244.0/255.0, green:104.0/255.0, blue:66.0/255.0, alpha: 1.0),
                                                          .font : UIFont.boldSystemFont(ofSize: 14)], for: .selected)
        let tabbarcontroller = UITabBarController()
        tabbarcontroller.selectedIndex = 0
        tabbarcontroller.tabBar.backgroundColor = .black
        tabbarcontroller.tabBar.unselectedItemTintColor = UIColor(red:189.0/255.0, green:195.0/255.0, blue:199.0/255.0, alpha: 1.0)
        tabbarcontroller.viewControllers = tabbarList
        
        window = UIWindow(windowScene: windowScene)
        window?.overrideUserInterfaceStyle = .light
        window?.rootViewController = tabbarcontroller
        window?.makeKeyAndVisible()
    }
}
