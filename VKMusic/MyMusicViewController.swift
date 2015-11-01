//
//  MyMusicViewController.swift
//  VKMusic
//
//  Created by Kirill Varlamov on 01.11.15.
//  Copyright © 2015 Kirill Varlamov. All rights reserved.
//

import UIKit
import VK_ios_sdk

class MyMusicViewController: MusicTableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        dataManager.getDataFormVK("audio.get", params: [VK_API_USER_ID: VKSdk.accessToken().userId, VK_API_OFFSET: dataManager.songs.count, "count": 15])
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
