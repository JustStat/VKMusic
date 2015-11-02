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

    @IBOutlet weak var playerInfoView: UIView!
    
    override func viewDidLoad() {
        self.request = VKRequest(method: "audio.get", andParameters: [VK_API_USER_ID: VKSdk.accessToken().userId, "count": 16])
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        tableView.addPullToRefreshWithActionHandler({
            () -> Void in
            if !self.dataManager.isBusy {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                    self.request = VKRequest(method: "audio.get", andParameters: [VK_API_USER_ID: VKSdk.accessToken().userId, VK_API_OFFSET: 0, "count": 16])
                    self.dataManager.getDataFormVK(self.request, refresh: true)
                    print("xcxzxc")
                    dispatch_async(dispatch_get_main_queue()) {
                        sleep(2)
                        self.tableView.pullToRefreshView.stopAnimating()
                    }
                }
            }
        })
        tableView.addInfiniteScrollingWithActionHandler({() -> Void in
            if !self.dataManager.isBusy {
                self.tableView.showsInfiniteScrolling = true
                self.tableView.infiniteScrollingView.startAnimating()
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            self.tableView.infiniteScrollingView.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.Gray
            self.request = VKRequest(method: "audio.get", andParameters: [VK_API_USER_ID: VKSdk.accessToken().userId, VK_API_OFFSET: self.dataManager.songs.count, "count": 15])
            self.loadMore()
                }
            self.tableView.infiniteScrollingView.stopAnimating()
            }
        })

    }
    
//    func refresh() {
//        
//    }
    
//    override func scrollViewWillBeginDragging(scrollView: UIScrollView) {
//        
//        //super.scrollViewWillBeginDragging(scrollView)
//    }
    

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
