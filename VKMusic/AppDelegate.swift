//
//  AppDelegate.swift
//  VKMusic
//
//  Created by Kirill Varlamov on 01.11.15.
//  Copyright © 2015 Kirill Varlamov. All rights reserved.
//

import UIKit
import VK_ios_sdk


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, VKSdkDelegate {

    var window: UIWindow?
    var VKSdkInstance: VKSdk!
    static let sharedInstance = AppDelegate()
    
    func vkAuthorization() {
        VKSdk.authorize([VK_PER_AUDIO, VK_PER_FRIENDS, VK_PER_GROUPS], revokeAccess: true, forceOAuth: false, inApp: true, display: VK_DISPLAY_IOS)
    }
    
    func showHelloViewController(isErrorExist: Bool) {
        let storyboard:UIStoryboard = UIStoryboard(name: "Hello", bundle: nil)
        let navView = storyboard.instantiateInitialViewController() as! UINavigationController
        let helloView = navView.viewControllers.first as! HelloViewController
//        self.VKSdkInstance.registerDelegate(helloView)
//        VKSdkInstance.uiDelegate = helloView
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        self.window?.rootViewController = helloView
        self.window?.makeKeyAndVisible()
    }
    
    //VK DELEGATE FUNCS
    func vkSdkNeedCaptchaEnter(captchaError: VKError) { }
    func vkSdkTokenHasExpired(expiredToken: VKAccessToken) {
        print("test")
    }
    func vkSdkUserDeniedAccess(authorizationError: VKError) {
        self.window?.makeKeyAndVisible()
        
    }
    func vkSdkShouldPresentViewController(controller: UIViewController) {
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        let storyboard = UIStoryboard(name: "Hello", bundle: nil)
        let vc = storyboard.instantiateViewControllerWithIdentifier("HelloView") as! HelloViewController
        self.window?.rootViewController = vc
        self.window?.makeKeyAndVisible()
        self.window?.rootViewController?.presentViewController(controller, animated: true, completion: nil)
    }
    func vkSdkReceivedNewToken(newToken: VKAccessToken) {
        //VKSdkInfo.sharedInstance.UserID = VKSdk.getAccessToken().userId
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        //VKInfo.sharedInstance.UserID = VKSdk.getAccessToken().userId
        let vc = storyboard.instantiateViewControllerWithIdentifier("MainTabController") as! UITabBarController
        vc.customizableViewControllers = nil
        vc.moreNavigationController.view.tintColor = UIColor(red:0.14, green:0.43, blue:0.69, alpha:1.0)
        UITabBar.appearance().tintColor = UIColor(red:0.14, green:0.43, blue:0.69, alpha:1.0)
        UIProgressView.appearance().tintColor = UIColor(red:0.14, green:0.43, blue:0.69, alpha:1.0)
        self.window?.rootViewController = vc
        self.window?.makeKeyAndVisible()
        
    }
    //VK DELEGATE ENDS
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        if #available(iOS 9.0, *) {
            VKSdk.processOpenURL(url, fromApplication: UIApplicationOpenURLOptionsSourceApplicationKey)
        } else {
            VKSdk.processOpenURL(url, fromApplication: sourceApplication)
        }
        return true
    }

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        VKSdk.initializeWithDelegate(self, andAppId: "5066733")
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if VKSdk.wakeUpSession() {
            let vc = storyboard.instantiateViewControllerWithIdentifier("MainTabController") as! UITabBarController
            self.window?.rootViewController = vc
            vc.customizableViewControllers = nil
            vc.moreNavigationController.view.tintColor = UIColor(red:0.14, green:0.43, blue:0.69, alpha:1.0)
            UITabBar.appearance().tintColor = UIColor(red:0.14, green:0.43, blue:0.69, alpha:1.0)
            UISlider.appearance().tintColor = UIColor(red:0.14, green:0.43, blue:0.69, alpha:1.0)
            self.window?.makeKeyAndVisible()
        } else {
            self.showHelloViewController(false)
        }
        return true
//        let sema = dispatch_semaphore_create(0)
//        VKSdk.wakeUpSession([VK_PER_AUDIO, VK_PER_FRIENDS, VK_PER_GROUPS], completeBlock: {(state, error) -> Void in
//            dispatch_semaphore_signal(sema)
//            if state == VKAuthorizationState.Initialized {
//                self.showHelloViewController(false)
//            } else if state == VKAuthorizationState.Error {
//                print("error")
//            }
//        })
//        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER)
//        print("test")
        
    }
    
    override func remoteControlReceivedWithEvent(event: UIEvent?) {
        if event!.type == UIEventType.RemoteControl {
            if event!.subtype == UIEventSubtype.RemoteControlPlay {
                print("received remote play")
                AudioProvider.sharedInstance.player.play()
            } else if event!.subtype == UIEventSubtype.RemoteControlPause {
                print("received remote pause")
                AudioProvider.sharedInstance.player.pause()
            } else if event!.subtype == UIEventSubtype.RemoteControlNextTrack {
                print("received nex")
                AudioProvider.sharedInstance.forward()
            } else if event!.subtype == UIEventSubtype.RemoteControlPreviousTrack {
                AudioProvider.sharedInstance.rewind()
            }
        }
    }
    

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

