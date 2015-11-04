//
//  MusicTableViewController.swift
//  VKMusic
//
//  Created by Kirill Varlamov on 01.11.15.
//  Copyright © 2015 Kirill Varlamov. All rights reserved.
//

import UIKit
import VK_ios_sdk
import SVPullToRefresh
import AVFoundation

class MusicTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, SongTableViewCellDelegate, UISearchBarDelegate, UISearchDisplayDelegate {
    
    @IBOutlet weak var SearchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var playerInfoBar: PlayerInfoBar!
    
    //MARK: Properites
    var dataManager = DataManager()
    var refreshControl: UIRefreshControl!
    var request: VKRequest!
    
    override func viewDidLoad() {
        getReqest((self.tabBarController?.selectedIndex)!, filter: "")
        if self.request != nil {
            dataManager.getDataFormVK(self.request, refresh: false)
            self.tableView.reloadData()
            self.playerInfoBar.hidden = true
        } else {
            self.dataManager.songs = []
        }
        
    }
    
    override func viewDidAppear(animated: Bool) {
        tableView.addPullToRefreshWithActionHandler({
            () -> Void in
            if !self.dataManager.isBusy {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                    self.dataManager.songs.removeAll()
                    self.getReqest((self.tabBarController?.selectedIndex)!, filter: "")
                    if self.request != nil {
                        self.dataManager.getDataFormVK(self.request, refresh: true)
                        self.tableView.reloadData()
                    } else if self.tabBarController?.selectedIndex == 1 {
                        self.dataManager.songs = DataBaseManager.sharedInstance.GetSongsFromDataBase("downloads", offset: self.dataManager.songs.count)
                    }
                    print("xcxzxc")
                    dispatch_async(dispatch_get_main_queue()) {
                        sleep(2)
                        self.tableView.pullToRefreshView.stopAnimating()
                    }
                }
            }
        })
        if self.tabBarController?.selectedIndex == 1 {
            dataManager.songs = []
            dataManager.songs = DataBaseManager.sharedInstance.GetSongsFromDataBase("downloads", offset: self.dataManager.songs.count)
            self.tableView.reloadData()
        }

    }
    
    func getReqest(index: Int, filter: String) {
        switch index {
        case 0:
            self.request = VKRequest(method: "audio.get", andParameters: [VK_API_USER_ID: VKSdk.accessToken().userId, VK_API_OFFSET: self.dataManager.songs.count, "count": 51])
            self.navigationItem.title = "Моя Музыка"
        case 1:
//            dataManager.songs = DataBaseManager.sharedInstance.GetSongsFromDataBase("downloads", offset: self.dataManager.songs.count)
            self.navigationItem.title = "Загрузки"
        case 2:
            self.request = VKRequest(method: "audio.getPopular", andParameters:[VK_API_OFFSET: self.dataManager.songs.count, "count": 51])
            self.navigationItem.title = "Популярное"
        case 3:
            self.request = VKRequest(method: "audio.getRecommendations", andParameters: [VK_API_OFFSET: self.dataManager.songs.count, "count": 51])
            self.navigationItem.title = "Рекомендуемое"
        case 4:
            if filter != "" {
            self.request = VKRequest(method: "audio.search", andParameters: [VK_API_Q:
                filter,"auto_complete": "1","sort": "2", "count": "100"])
            }
        default:
            print("Whoops")
        }
    }
    
    // MARK: TableDataSource FUNCS
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellIdentifier = "SongTableViewCell"
        let cell = self.tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! SongTableViewCell
        print(indexPath.row)
        //if dataManager.songs.count > indexPath.row {
        var song: Song
        if tableView == self.searchDisplayController!.searchResultsTableView {
            song = self.dataManager.filteredTableData[indexPath.row]
        } else {
            song = dataManager.songs[indexPath.row]
        }
        cell.delegate = self
        cell.nameLabel.text = song.title
        cell.authorLabel.text = song.artist
        cell.durationLabel.text = song.durationToString()
       // }
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewControllerWithIdentifier("MainPlayer") as! PlayerViewController
        AudioProvider.sharedInstance.playlist = dataManager.songs
        vc.currentSongIndex = indexPath.row
        self.showDetailViewController(vc, sender: self)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.searchDisplayController!.searchResultsTableView {
            return self.dataManager.filteredTableData.count
        } else {
            return dataManager.songs.count
        }
    }
    
    func loadMore() {
        getReqest((self.tabBarController?.selectedIndex)!,filter: "")
        if (self.request != nil) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                self.dataManager.getDataFormVK(self.request, refresh: false)
                dispatch_async(dispatch_get_main_queue()) {
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    
    //TableDataSource ENDS
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        let currentOffset = scrollView.contentOffset.y
        let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height
        let deltaOffset = maximumOffset - currentOffset
        if deltaOffset <= 300 {
            loadMore()
        }
    }
    
    
    //MARK: TableIntaration FUNCS
    
    
    func createCellAlertController(cell: SongTableViewCell) {
        var filtered = false
        var index = tableView.indexPathForCell(cell)?.row
        if index == nil {
            index = searchDisplayController?.searchResultsTableView.indexPathForCell(cell)?.row
            filtered = true
        }
        self.createAlertController(index!, filtered: filtered)
    }
    
    func createAlertController(index: Int, filtered: Bool) {
        var songList = [Song]()
        if filtered {
            songList = self.dataManager.filteredTableData
        } else {
            songList = self.dataManager.songs
        }
        let alertController = UIAlertController(title: "\n \n \n \n", message: "", preferredStyle: UIAlertControllerStyle.ActionSheet)
        alertController.addAction(UIAlertAction(title: "Добавить в \"Моя Музыка\"", style: UIAlertActionStyle.Default, handler: {
            (UIAlertAction) -> Void in
            //Add song to libruary
        }))
        if dataManager.songs[index].localUrl == "" {
            alertController.addAction(UIAlertAction(title: "Сделать доступной оффлайн", style: UIAlertActionStyle.Default, handler: {
                (UIAlertAction) -> Void in
                    DataBaseManager.sharedInstance.addSongToTable(songList[index], table: "downloads")
            }))
        }
        alertController.addAction(UIAlertAction(title: "Отменить", style: UIAlertActionStyle.Cancel, handler: nil))
        alertController.view.tintColor = UIColor(red:0.27, green:0.40, blue:0.56, alpha:1.0)
        let titleView = UIView(frame: CGRectMake(alertController.view.frame.minX + 10, alertController.view.frame.minY + 10, 300, 50))
        var song: AVPlayerItem!
        var coverImage = UIImage(named: "DefCover")
        let imageView = UIImageView(image: coverImage)
        imageView.frame = CGRectMake(0, 0, 80, 80)
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            if songList[index].localUrl != "" {
                song = AVPlayerItem(URL: NSURL(string: songList[index].localUrl)!)
            } else {
                song = AVPlayerItem(URL: NSURL(string: songList[index].url)!)
            }
            coverImage = UIImage(named: "DefCover")
            let metadata = song.asset.commonMetadata
            for item in metadata {
                if item.commonKey  == "artwork" {
                    coverImage = UIImage(data: item.value as! NSData)
                }
            }
            dispatch_async(dispatch_get_main_queue()) {
                imageView.image = coverImage
            }
        }
        titleView.backgroundColor = alertController.view.backgroundColor
        let titleLabel = UILabel(frame: CGRectMake(85, 0, titleView.frame.width - 110, 20))
        titleLabel.text = songList[index].title
        titleLabel.font.fontWithSize(13)
        let artistLabel = UILabel(frame: CGRectMake(85, 25, titleView.frame.width - 110, 20))
        artistLabel.textColor = UIColor.lightGrayColor()
        artistLabel.text = songList[index].artist
        artistLabel.font.fontWithSize(10)
        titleView.addSubview(titleLabel)
        titleView.addSubview(artistLabel)
        titleView.addSubview(imageView)
        alertController.view.addSubview(titleView)
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    //MARK: SearchDelegate FUNCS
    
    func searchDisplayController(controller: UISearchDisplayController, shouldReloadTableForSearchString searchString: String?) -> Bool {
        self.filterContentForSearchText(searchString!)
        if self.tabBarController?.selectedIndex == 4 {
            self.searchDisplayController?.searchResultsTableView.alpha = 0
            return false
        }
        return true
    }
    
    func searchDisplayController(controller: UISearchDisplayController, shouldReloadTableForSearchScope searchOption: Int) -> Bool {
        self.filterContentForSearchText(self.searchDisplayController!.searchBar.text!)
        if self.tabBarController?.selectedIndex == 4 {
            return false
        }
        return true
    }
    
    func filterContentForSearchText(searchText: String) {
        // Filter the array using the filter method
        self.searchDisplayController?.searchResultsTableView.hidden = true
                self.dataManager.filteredTableData = self.dataManager.songs.filter({( song: Song) -> Bool in
                var stringMatch = song.title.rangeOfString(searchText)
                if stringMatch == nil {
                    stringMatch = song.artist.rangeOfString(searchText)
                }
                return (stringMatch != nil)
            })

    }

    
    
    func searchDisplayController(controller: UISearchDisplayController, didHideSearchResultsTableView tableView: UITableView) {
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        if self.tabBarController?.selectedIndex == 4 {
            self.getReqest(4, filter: searchBar.text!)
            self.dataManager.getDataFormVK(self.request, refresh: true)
            self.tableView.reloadData()
            //self.filteredTableData = self.dataManager.songs
//            self.dataManager.songs = []
//            self.tableView.reloadData()
        }
        filterContentForSearchText(SearchBar.text!)
        self.searchDisplayController?.active = false
        
    }
    
    
    
    // MARK: - Navigation


    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
    }

}
