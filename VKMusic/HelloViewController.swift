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
        //
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
    }
}
