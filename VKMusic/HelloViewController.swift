//
//  HelloView.swift
//  VKMusic
//
//  Created by Kirill Varlamov on 01.11.15.
//  Copyright © 2015 Kirill Varlamov. All rights reserved.
//

import UIKit
import VK_ios_sdk

class HelloViewController: UIViewController {
    
    //MARK: properies
    
    
    //MARK: VKSdkUIDelegate FUNCS
    
    func vkSdkDidDismissViewController(controller: UIViewController!) {
        
    }
    
    func vkSdkNeedCaptchaEnter(captchaError: VKError!) {
        //
    }
    
    func vkSdkShouldPresentViewController(controller: UIViewController!) {
        self.presentViewController(controller, animated: true, completion: nil)
    }
    
    func vkSdkWillDismissViewController(controller: UIViewController!) {
        //
    }
    
    // VKSdkUIDelegate FUNCS END

    @IBAction func AuthorizeButtonClick(sender: AnyObject) {
        AppDelegate.sharedInstance.vkAuthorization()
//        VKSdk.authorize([VK_PER_AUDIO, VK_PER_FRIENDS, VK_PER_GROUPS], withOptions: VKAuthorizationOptions.DisableSafariController)
//        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
//        let mainBarController = storyBoard.instantiateInitialViewController() as! UITabBarController
//        self.presentViewController(mainBarController, animated: true, completion: nil)
//    } else {
//    let alertController = UIAlertController(title: "Ошибка!", message: "Произошла ошибка авторизации! Попробуйте авторизоваться снова", preferredStyle: UIAlertControllerStyle.Alert)
//    alertController.addAction(UIAlertAction(title: "Ок", style: UIAlertActionStyle.Default, handler: nil))
//    self.presentViewController(alertController, animated: true, completion: nil)


    }
}
