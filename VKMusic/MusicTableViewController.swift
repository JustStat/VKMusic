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

class MusicTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, SongTableViewCellDelegate, UISearchBarDelegate, UISearchDisplayDelegate, NSURLSessionDelegate, NSURLSessionDownloadDelegate
{
    
    @IBOutlet weak var SearchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var playerInfoBar: PlayerInfoBar!
    
    //MARK: Properites
    
    func insertIntoFileDownloadArray() {
        
    }
    
    var dataManager = DataManager()
    var downloadManager: DownloadManager!
    var refreshControl: UIRefreshControl!
    var request: VKRequest!

    
    override func viewDidLoad() {
        getReqest((self.tabBarController?.selectedIndex)!, filter: "")
        self.downloadManager = DownloadManager(title: "\(counter.sharedInstance.index++)", delegate: self)
//        self.tableView.delegate = self
//        self.tableView.dataSource = self
        if self.request != nil {
            dataManager.getDataFormVK(self.request, refresh: false)
            self.tableView.reloadData()
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
                        //sleep(2)
                        self.tableView.reloadData()
                        self.tableView.pullToRefreshView.stopAnimating()
                    }
                }
            }
        })
        self.playerInfoBar.delegate = self
        
        if self.tabBarController?.selectedIndex == 1 {
            dataManager.songs = []
            dataManager.songs = DataBaseManager.sharedInstance.GetSongsFromDataBase("downloads", offset: self.dataManager.songs.count)
            self.tableView.reloadData()
        }
        if AudioProvider.sharedInstance.currentSong != nil {
            self.playerInfoBar.hidden = false
            self.playerInfoBar.updateUI()
        } else {
            self.playerInfoBar.hidden = true
        }

    }
    
    func getReqest(index: Int, var filter: String) {
        self.request = nil
        switch index {
        case 0:
            if VKSdk.getAccessToken() != nil {
            self.request = VKRequest(method: "audio.get", andParameters: [VK_API_USER_ID: VKSdk.getAccessToken().userId, VK_API_OFFSET: self.dataManager.songs.count, "count": 50], andHttpMethod: "GET")
            }
            self.navigationItem.title = "Моя Музыка"
        case 1:
//            dataManager.songs = DataBaseManager.sharedInstance.GetSongsFromDataBase("downloads", offset: self.dataManager.songs.count)
            self.navigationItem.title = "Загрузки"
        case 2:
            self.request = VKRequest(method: "audio.getPopular", andParameters:[VK_API_OFFSET: self.dataManager.songs.count, "count": 50], andHttpMethod: "GET")
            self.navigationItem.title = "Популярное"
        case 3:
            self.request = VKRequest(method: "audio.getRecommendations", andParameters: [VK_API_OFFSET: self.dataManager.songs.count, "count": 50], andHttpMethod: "GET")
            self.navigationItem.title = "Рекомендуемое"
        case 4:
            if filter == "" {
                filter = dataManager.searhReq
            } else {
                dataManager.searhReq = filter
            }
            self.request = VKRequest(method: "audio.search", andParameters: [VK_API_Q:
                filter,"auto_complete": "1","sort": "2", "count": "100"], andHttpMethod: "GET")
            self.navigationItem.title = "Поиск"
        default:
            print("Whoops")
        }
    }
    
    // MARK: TableDataSource FUNCS
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellIdentifier = "SongTableViewCell"
        let cell = self.tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! SongTableViewCell
        print(indexPath.row)
        if dataManager.songs.count > indexPath.row {
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
       }
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
        let exist = DataBaseManager.sharedInstance.checkExistance("downloads", id: self.dataManager.songs[index].id)
        var songList = [Song]()
        if filtered {
            songList = self.dataManager.filteredTableData
        } else {
            songList = self.dataManager.songs
        }
        let alertController = UIAlertController(title: "\n \n \n \n", message: "", preferredStyle: UIAlertControllerStyle.ActionSheet)
        if self.dataManager.songs[index].ownerId != Int(VKSdk.getAccessToken().userId) {
            alertController.addAction(UIAlertAction(title: "Добавить в \"Моя Музыка\"", style: UIAlertActionStyle.Default, handler: {
            (UIAlertAction) -> Void in
            //Add song to libruary
            }))
        }
        if !exist {
            alertController.addAction(UIAlertAction(title: "Сделать доступной оффлайн", style: UIAlertActionStyle.Default, handler: {
                (UIAlertAction) -> Void in
                let cell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: index, inSection: 0)) as! SongTableViewCell
                let rowIndex = self.tableView.indexPathForCell(cell)
                let cellIdentifier = "SongTableViewCell"
                let Acell = self.tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: rowIndex!) as! SongTableViewCell;
                Acell.progressBar = UIProgressView(frame: CGRectMake(0, 0, Acell.frame.width, 2))
                let cellRect = self.tableView.rectForRowAtIndexPath(rowIndex!)
                let asr = self.tableView.convertRect(cellRect, fromView: self.view)
                Acell.progressBar.center = CGPoint(x: (asr.maxX - asr.minX)/2, y: (asr.maxY - asr.minY))
                Acell.progressBar.progressTintColor = UIColor(red: 69/255, green:  102/255, blue:  142/255, alpha: 1)
                Acell.addSubview(Acell.progressBar!)
                self.tableView.reloadRowsAtIndexPaths([rowIndex!], withRowAnimation: UITableViewRowAnimation.None)
                let song  = self.dataManager.songs[index]
                let fdi = song.downloadInfo
                if fdi.taskId == -1 {
                        fdi.downloadTask = self.downloadManager.session.downloadTaskWithURL(NSURL(string: self.dataManager.songs[index].url)!)
                        fdi.taskId = fdi.downloadTask.taskIdentifier
                        fdi.cellIndex = index
                        fdi.isDownloading = true
                        self.downloadManager.downloadSongsList.append(song)
                        fdi.downloadTask.resume()
                }
            }))
        }
        if self.dataManager.songs[index].ownerId == Int(VKSdk.getAccessToken().userId) {
            alertController.addAction(UIAlertAction(title: "Удалить из \"Моя музыка\"", style: UIAlertActionStyle.Default, handler: {
                (alert) -> Void in
                let alertController = UIAlertController(title: "Удаление", message: "Вы действительно хотите удалить \(self.dataManager.songs[index].title) \(self.dataManager.songs[index].artist)", preferredStyle: UIAlertControllerStyle.Alert)
                alertController.addAction(UIAlertAction(title: "ОК", style: UIAlertActionStyle.Default, handler: {
                    (action) -> Void in
                    //
                }))
                alertController.addAction(UIAlertAction(title: "Отмена", style: UIAlertActionStyle.Default, handler: nil))
            }))
        }
        
        if self.tabBarController?.selectedIndex < 2 && exist {
            alertController.addAction(UIAlertAction(title: "Удалить из \"Загрузки\"", style: UIAlertActionStyle.Default, handler: {
                (alert) -> Void in
                let alertController = UIAlertController(title: "Удаление", message: "Вы действительно хотите удалить \(self.dataManager.songs[index].title) \(self.dataManager.songs[index].artist)", preferredStyle: UIAlertControllerStyle.Alert)
                alertController.addAction(UIAlertAction(title: "ОК", style: UIAlertActionStyle.Default, handler: {
                    (action) -> Void in
                    //
                }))
                alertController.addAction(UIAlertAction(title: "Отмена", style: UIAlertActionStyle.Default, handler: nil))
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
    
   // SearchDelegate ENDS
    
   //MARK: URLSessionsDownloadsDelegate FUNCS
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        print("downloaded \(100*totalBytesWritten/totalBytesExpectedToWrite)")
        let index = self.getFileDownloadInfoIndexWithTaskIdentifire(downloadTask.taskIdentifier)
         let fdi =  self.downloadManager.downloadSongsList[index].downloadInfo
        NSOperationQueue.mainQueue().addOperationWithBlock({
            fdi.downloadProgress = Double(totalBytesWritten)/Double(totalBytesExpectedToWrite)
            let progress = Float(fdi.downloadProgress)
            let cell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: fdi.cellIndex, inSection: 0)) as! SongTableViewCell
            cell.progressBar.progress = Float(progress)
        })
//        cell.progressBar.reloadInputViews()
//        cell.reloadInputViews()

    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        let destFileName = downloadTask.originalRequest?.URL?.lastPathComponent
        let destURL = self.downloadManager.docDirectoryURL.URLByAppendingPathComponent(destFileName!)
        
        if NSFileManager.defaultManager().fileExistsAtPath(destURL.path!) {
            do { try NSFileManager.defaultManager().removeItemAtURL(destURL)} catch {}
        }
        do {try NSFileManager.defaultManager().copyItemAtURL(location, toURL: destURL)} catch {}
        let index = self.getFileDownloadInfoIndexWithTaskIdentifire(downloadTask.taskIdentifier)
        if  self.downloadManager.downloadSongsList.count != 0 {
            let fdi =  self.downloadManager.downloadSongsList[index].downloadInfo
             self.downloadManager.downloadSongsList.removeAtIndex(index)
            NSOperationQueue.mainQueue().addOperationWithBlock({
            let cell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: fdi.cellIndex, inSection: 0)) as! SongTableViewCell
            cell.progressBar.removeFromSuperview()
                self.tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: fdi.cellIndex, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Automatic)})
            self.dataManager.songs[fdi.cellIndex].localUrl = destURL.path!
            DataBaseManager.sharedInstance.addSongToTable(self.dataManager.songs[fdi.cellIndex], table: "downloads")
        }
        print("dowload complete")
    }
    
    func URLSession(session: NSURLSession, didBecomeInvalidWithError error: NSError?) {
        print(error?.description)
    }
    
    func getFileDownloadInfoIndexWithTaskIdentifire(taskId: CLong) -> (Int) {
        for var i = 0; i <  self.downloadManager.downloadSongsList.count; ++i {
            if self.downloadManager.downloadSongsList[i].downloadInfo.taskId == taskId {
                return i
            }
        }
        return 0
    }
    
    
    // MARK: - Navigation


    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
    }

}
