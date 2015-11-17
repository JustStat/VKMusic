//
//  SettingsViewController.swift
//  VKMusic
//
//  Created by Kirill Varlamov on 12.11.15.
//  Copyright © 2015 Kirill Varlamov. All rights reserved.
//

import UIKit
import VK_ios_sdk
import SwiftyJSON
import Alamofire
import SDWebImage

class SettingsViewController: UIViewController {

    @IBOutlet weak var deauthorizeButton: UIButton!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var userImage: UIImageView!
    
    @IBAction func unSignVK() {
        VKSdk.forceLogout()
    }
    @IBAction func deleteDownloadedContent() {
        let docFolder = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0]
        do {let docContent = try NSFileManager.defaultManager().contentsOfDirectoryAtPath(docFolder)
            for file in docContent {
                print(docFolder.stringByAppendingString(file))
                try NSFileManager.defaultManager().removeItemAtPath(docFolder.stringByAppendingString("/" + file))
            }
            let alertController = UIAlertController(title: "Удаление", message: "Загруженные файлы были успешно удалены", preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: "ОК", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alertController, animated: true, completion: nil)
        } catch {
            print("Error while deleting")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Alamofire.request(.GET, "http://api.vkontakte.ru/method/users.get?uids="+VKSdk.getAccessToken().userId+"&fields=photo_200").responseJSON(completionHandler: {(response) -> Void in
//            if response.result.value != nil {
            let json = JSON(response.result.value!)
            print(json.description)
            let userImagePath = json["response"][0]["photo_200"].stringValue
            let fullName = json["response"][0]["first_name"].stringValue + " " + json["response"][0]["last_name"].stringValue
            self.userImage.sd_setImageWithURL(NSURL(string: userImagePath), placeholderImage: UIImage(named: "UserIcon"))
            self.userImage.layer.cornerRadius = self.userImage.frame.size.width / 2
            self.userImage.clipsToBounds = true
            self.userName.text = fullName
//            } else {
//            }
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
