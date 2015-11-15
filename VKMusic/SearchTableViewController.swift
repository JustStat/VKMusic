//
//  SearchViewControllerTableViewController.swift
//  VKMusic
//
//  Created by Kirill Varlamov on 10.11.15.
//  Copyright © 2015 Kirill Varlamov. All rights reserved.
//

import UIKit

class SearchTableViewController: MusicTableViewController, UISearchBarDelegate, UISearchResultsUpdating {
    
    var searchBar: UISearchBar!

    override func viewDidLoad() {
        self.searchBar = UISearchBar(frame: CGRectMake(0, 0, UIScreen.mainScreen().bounds.width, 88))
        self.searchBar.delegate = self
        self.searchBar.scopeButtonTitles = ["Моя музыка", "Загрузки", "ВКонтакте"]
        self.searchBar.showsScopeBar = true
        self.searchBar.showsCancelButton = true
    }
    
    override func viewWillAppear(animated: Bool){
        super.viewWillAppear(animated)
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.mainScreen().bounds.width, height: 88))
        self.searchBar.sizeToFit()
        headerView.addSubview(searchBar)
        self.navigationController!.view.addSubview(headerView)
        self.tableView.contentInset = UIEdgeInsetsMake(88,0,0,0);
        self.searchBar.becomeFirstResponder()
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {

    }
    
    func searchBar(searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        getFilteredData()
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        self.dismissViewControllerAnimated(true, completion: {})
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        self.searchBar.resignFirstResponder()
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        if self.searchBar.text != "" {
            NSObject.cancelPreviousPerformRequestsWithTarget(self, selector: Selector("getFilteredData"), object: nil)
            self.performSelector(Selector("getFilteredData"), withObject: nil, afterDelay: 1.5)
        }
    }
    
    func getFilteredData() {
        if self.searchBar.text != "" {
            self.dataManager.songs = []
            self.request = self.dataManager.getSearchRequest(self.searchBar.selectedScopeButtonIndex, query: searchBar.text!)
            if self.request != nil {
                switch self.searchBar.selectedScopeButtonIndex {
                case 0:
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                        self.dataManager.getDataFormVK(self.request, refresh: false, onlyMine: true)
                        dispatch_async(dispatch_get_main_queue()) {
                            self.tableView.reloadData()
                        }
                    }
                case 1:
                    self.dataManager.songs = DataBaseManager.sharedInstance.downloadsSearchReqest(self.searchBar.text!)
                    self.tableView.reloadData()
                case 2:
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                        self.dataManager.getDataFormVK(self.request, refresh: false, onlyMine: false)
                        dispatch_async(dispatch_get_main_queue()) {
                            self.tableView.reloadData()
                        }
                    }
                default:
                    print("Whoops")
                }
            } else {
                self.dataManager.songs = []
            }
        } else {
            self.dataManager.songs.removeAll()
            self.tableView.reloadData()
        }
    }
    
    override func loadMore() {
        self.request = self.dataManager.getSearchRequest(self.searchBar.selectedScopeButtonIndex, query: searchBar.text!)
        if self.request != nil {
            switch self.searchBar.selectedScopeButtonIndex {
            case 0:
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                    self.dataManager.getDataFormVK(self.request, refresh: false, onlyMine: true)
                    dispatch_async(dispatch_get_main_queue()) {
                        self.tableView.reloadData()
                    }
                }
            case 1:
                print("case 1")
            case 2:
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                    self.dataManager.getDataFormVK(self.request, refresh: false, onlyMine: false)
                    dispatch_async(dispatch_get_main_queue()) {
                        self.tableView.reloadData()
                    }
                }
            default:
                print("Whoops")
            }
        } else {
            self.dataManager.songs = []
            self.dataManager.songs += DataBaseManager.sharedInstance.GetSongsFromDataBase("downloads", offset: self.dataManager.songs.count)
        }
    }

    
    // MARK: UITableViewDataSource
    
//    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return 0
//    }
//    
//    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
//    }
    
    // MARK: UIStateRestoration
    
    override func encodeRestorableStateWithCoder(coder: NSCoder) {
        super.encodeRestorableStateWithCoder(coder)
        
    }
    
    override func decodeRestorableStateWithCoder(coder: NSCoder) {
        super.decodeRestorableStateWithCoder(coder)
        
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
    
    /*
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath)

        // Configure the cell...

        return cell
    }
    */

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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
