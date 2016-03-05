//
//  MainMenuTableViewController.swift
//  VKMusic
//
//  Created by Kirill Varlamov on 11.11.15.
//  Copyright © 2015 Kirill Varlamov. All rights reserved.
//

import UIKit

class MainMenuTableViewController: UITableViewController {
    
    struct menuItem {
        var title: String!
        var image: UIImage!
    }
    
    var searchController: UISearchController!
    var menuItems = [menuItem]()
    var curItem: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        self.addMenuItems()
        self.tableView.tableFooterView = UIView(frame: CGRectZero)
    }
    
    override func viewWillAppear(animated: Bool) {

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

//    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
//        // #warning Incomplete implementation, return the number of sections
//        return 0
//    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return menuItems.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("menuItemCell", forIndexPath: indexPath)
        cell.imageView?.image = menuItems[indexPath.row].image
        cell.textLabel?.text = menuItems[indexPath.row].title
        cell.textLabel?.textColor = GlobalConstants.colors.VKBlue
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row < 4 {
            if indexPath.row != curItem {
                let vc = storyboard!.instantiateViewControllerWithIdentifier("MainMusicViewController") as! MusicTableViewController
                vc.number = indexPath.row
                let nvc = self.revealViewController().frontViewController as! UINavigationController
                nvc.setViewControllers([vc], animated: false)
            }
        }

        if indexPath.row == 6 {
            let vc = storyboard!.instantiateViewControllerWithIdentifier("SettingsVC") as! SettingsViewController
            let nvc = self.revealViewController().frontViewController as! UINavigationController
            nvc.setViewControllers([vc], animated: false)
        }
        
        if indexPath.row == 4 || indexPath.row == 5 {
            let vc = storyboard!.instantiateViewControllerWithIdentifier("PlaylistsTableViewController") as! PlaylistsTableViewController
            let nvc = self.revealViewController().frontViewController as! UINavigationController
            if indexPath.row == 5 {
                vc.friendsMode = true
            }
            nvc.setViewControllers([vc], animated: false)
        }
        
        curItem = indexPath.row
        self.revealViewController().setFrontViewPosition(FrontViewPosition.LeftSideMost, animated: true)

    }

    func addMenuItem(title: String, image: UIImage) {
        var item = menuItem()
        item.title = title
        item.image = image
        self.menuItems.append(item)
    }
    
    func addMenuItems() {
        addMenuItem("Моя музыка", image: UIImage(named: "Music")!)
        addMenuItem("Загрузки", image: UIImage(named: "Downloads")!)
        addMenuItem("Популярное", image: UIImage(named: "TopRated")!)
        addMenuItem("Рекомендуемое", image: UIImage(named: "Recom")!)
        addMenuItem("Плейлисты", image: UIImage(named: "Playlists")!)
        addMenuItem("Друзья", image: UIImage(named: "Friends")!)
        addMenuItem("Настройки", image: UIImage(named: "Settings")!)
    }
    
}
