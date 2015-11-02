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
    
    func showHelloViewController(isErrorExist: Bool) {
        let storyboard:UIStoryboard = UIStoryboard(name: "Hello", bundle: nil)
        let navView = storyboard.instantiateInitialViewController() as! UINavigationController
        let helloView = navView.viewControllers.first as! HelloViewController
        self.VKSdkInstance.registerDelegate(helloView)
        VKSdkInstance.uiDelegate = helloView
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        self.window?.rootViewController = helloView
        self.window?.makeKeyAndVisible()
    }
    
    //VKSdkDelegate Funcs
    
    func vkSdkAccessAuthorizationFinishedWithResult(result: VKAuthorizationResult!) {
        //
    }
    
    func vkSdkAccessTokenUpdated(newToken: VKAccessToken!, oldToken: VKAccessToken!) {
        //
    }
    
    func vkSdkTokenHasExpired(expiredToken: VKAccessToken!) {
        //
    }
    
    func vkSdkUserAuthorizationFailed(result: VKError!) {
       // print(result.description)
    }
    
    //VKSdkDelegate Funcs End
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        if #available(iOS 9.0, *) {
            VKSdk.processOpenURL(url, fromApplication: UIApplicationOpenURLOptionsSourceApplicationKey)
        } else {
            VKSdk.processOpenURL(url, fromApplication: sourceApplication)
        }
        return true
    }

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        self.VKSdkInstance = VKSdk.initializeWithAppId("5066733")
        self.VKSdkInstance.registerDelegate(self)
        VKSdk.wakeUpSession([VK_PER_AUDIO, VK_PER_FRIENDS, VK_PER_GROUPS], completeBlock: {(state, error) -> Void in
            if state == VKAuthorizationState.Initialized {
                self.showHelloViewController(false)
            } else if error != nil {
                print(error)
            }
        
        })
        return true
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

