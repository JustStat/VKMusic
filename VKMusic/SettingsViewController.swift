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
import PKRevealController

class SettingsViewController: UIViewController, PKRevealing {

    @IBOutlet weak var deauthorizeButton: UIButton!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var openBackTableButton: UIBarButtonItem!
    
    @IBAction func unSignVK() {
        VKSdk.forceLogout()
        DataBaseManager.sharedInstance.deleteUserInfoFromDataBase()
        let storyboard = UIStoryboard(name: "Hello", bundle: nil)
        let vc = storyboard.instantiateViewControllerWithIdentifier("HelloView") as! HelloViewController
        self.presentViewController(vc, animated: true, completion: nil)
    }
    @IBAction func deleteDownloadedContent() {
        let docFolder = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0]
        do {let docContent: NSArray = try NSFileManager.defaultManager().contentsOfDirectoryAtPath(docFolder)
            let mp3Files = docContent.filteredArrayUsingPredicate(NSPredicate(format: "self ENDSWITH '.mp3'"))
            for file in mp3Files {
                print(docFolder.stringByAppendingString(file as! String))
                try NSFileManager.defaultManager().removeItemAtPath(docFolder.stringByAppendingString("/" + (file as! String)))
            }
            let alertController = UIAlertController(title: "Удаление", message: "Загруженные файлы были успешно удалены", preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: "ОК", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alertController, animated: true, completion: nil)
            DataBaseManager.sharedInstance.removeDownloadsDB()
            DataBaseManager.sharedInstance.reloadDB()
        } catch {
            print("Error while deleting")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.toolbar.hidden = true
        openBackTableButton.target = self.revealViewController()
        openBackTableButton.action = Selector("revealToggle:")
        let userInfo = DataBaseManager.sharedInstance.getUserInfoFromDataBase()
        if userInfo.count != 0 {
            self.userImage.image = UIImage(contentsOfFile: userInfo[1])
            self.userImage.layer.cornerRadius = self.userImage.frame.size.width / 2
            self.userImage.clipsToBounds = true
            self.userName.text = userInfo[0]
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func OpenGitHubURL(sender: AnyObject) {
        UIApplication.sharedApplication().openURL(NSURL(string: "https://github.com/JustStat/VKMusic")!)
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
