//
//  MainMenuTableViewController.swift
//  VKMusic
//
//  Created by Kirill Varlamov on 11.11.15.
//  Copyright © 2015 Kirill Varlamov. All rights reserved.
//

import UIKit

class MainMenuTableViewController: UITableViewController, UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
    
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
        cell.textLabel?.textColor = UIColor(red:0.14, green:0.43, blue:0.69, alpha:1.0)
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

        if indexPath.row == 4 {
            let vc = storyboard!.instantiateViewControllerWithIdentifier("SettingsVC") as! SettingsViewController
            let nvc = self.revealViewController().frontViewController as! UINavigationController
            nvc.setViewControllers([vc], animated: false)
        }
        
        curItem = indexPath.row
        self.revealViewController().setFrontViewPosition(FrontViewPosition.LeftSideMost, animated: true)

    }
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.showsCancelButton = true
        self.revealViewController().setFrontViewPosition(FrontViewPosition.Right, animated: true)
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        self.revealViewController().setFrontViewPosition(FrontViewPosition.RightMostRemoved, animated: true)
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
        addMenuItem("Настройки", image: UIImage(named: "Settings")!)
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
