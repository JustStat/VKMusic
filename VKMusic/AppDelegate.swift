//
//  AppDelegate.swift
//  VKMusic
//
//  Created by Kirill Varlamov on 01.11.15.
//  Copyright © 2015 Kirill Varlamov. All rights reserved.
//

import UIKit
import VK_ios_sdk
import Alamofire
import SwiftyJSON

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, VKSdkDelegate {

    var window: UIWindow?
    var VKSdkInstance: VKSdk!
    static let sharedInstance = AppDelegate()
    
    func vkAuthorization() {
        VKSdk.authorize([VK_PER_AUDIO, VK_PER_FRIENDS, VK_PER_GROUPS, VK_PER_STATUS], revokeAccess: true, forceOAuth: false, inApp: true, display: VK_DISPLAY_IOS)
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
        Alamofire.request(.GET, "http://api.vkontakte.ru/method/users.get?uids="+VKSdk.getAccessToken().userId+"&fields=photo_200").responseJSON(completionHandler: {(response) -> Void in
            let json = JSON(response.result.value!)
            print(json.description)
            let userImagePath = json["response"][0]["photo_200"].stringValue
            let fullName = json["response"][0]["first_name"].stringValue + " " + json["response"][0]["last_name"].stringValue
            let destination = Alamofire.Request.suggestedDownloadDestination(directory: .DocumentDirectory, domain: .UserDomainMask)
            Alamofire.download(.GET, userImagePath, destination: destination).response { request, response, _, error in
                let URL = destination(NSURL(string: "")!, response!)
                let ImagelocalUrl = URL.path
                DataBaseManager.sharedInstance.addUserInfoToDataBase([fullName, ImagelocalUrl!])
            }

        })

        let vc = storyboard.instantiateViewControllerWithIdentifier("revealController")
        self.window?.rootViewController = vc
        UITabBar.appearance().tintColor = GlobalConstants.colors.VKBlue
        UISlider.appearance().tintColor = GlobalConstants.colors.VKBlue
        UINavigationBar.appearance().tintColor = GlobalConstants.colors.VKBlue
        UISearchBar.appearance().tintColor = GlobalConstants.colors.VKBlue
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
            let vc = storyboard.instantiateViewControllerWithIdentifier("revealController")
            self.window?.rootViewController = vc
            UITabBar.appearance().tintColor = GlobalConstants.colors.VKBlue
            UISlider.appearance().tintColor = GlobalConstants.colors.VKBlue
            UINavigationBar.appearance().tintColor = GlobalConstants.colors.VKBlue
            UISearchBar.appearance().tintColor = GlobalConstants.colors.VKBlue
            self.window?.makeKeyAndVisible()
        } else {
            self.showHelloViewController(false)
        }
        return true
        
    }
    
    override func remoteControlReceivedWithEvent(event: UIEvent?) {
        if event!.type == UIEventType.RemoteControl {
            switch event!.subtype {
            case .RemoteControlPlay:
                AudioProvider.sharedInstance.player.play()
                break
            case .RemoteControlPreviousTrack:
                AudioProvider.sharedInstance.rewind()
                break
            case .RemoteControlPause:
                AudioProvider.sharedInstance.player.pause()
                break
            case .RemoteControlNextTrack:
                AudioProvider.sharedInstance.forward()
                break
            case .RemoteControlBeginSeekingForward:
                AudioProvider.sharedInstance.player.rate = 2
            case .RemoteControlEndSeekingForward:
                AudioProvider.sharedInstance.player.rate = 1
            case .RemoteControlBeginSeekingBackward:
                AudioProvider.sharedInstance.player.rate = -2
            case .RemoteControlEndSeekingBackward:
                AudioProvider.sharedInstance.player.rate = 1
            case .RemoteControlTogglePlayPause:
                if AudioProvider.sharedInstance.player.rate == 1 {
                    AudioProvider.sharedInstance.player.pause()
                } else {
                    AudioProvider.sharedInstance.player.play()
                }
                break
            default:
                break
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
        AudioProvider.sharedInstance.stopBroadcast()
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

