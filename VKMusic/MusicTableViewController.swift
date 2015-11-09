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
import SwiftyJSON

class MusicTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, SongTableViewCellDelegate, UISearchBarDelegate, UISearchDisplayDelegate, NSURLSessionDelegate, NSURLSessionDownloadDelegate, AudioProviderDelegate
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
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            self.getReqest((self.tabBarController?.selectedIndex)!, filter: "")
            self.downloadManager = DownloadManager(title: "\(counter.sharedInstance.index++)", delegate: self)
            AudioProvider.sharedInstance.delegate = self
            self.tableView.delegate = self
            self.tableView.dataSource = self
            if self.request != nil {
                dispatch_async(dispatch_get_main_queue()) {
                    self.dataManager.getDataFormVK(self.request, refresh: false)
                    self.tableView.reloadData()
                }
            } else {
                self.dataManager.songs = []
            }
        }
        
    }

    
    func playerDidFinishPlaying(note: NSNotification) {
        self.playerInfoBar.updateUI()
        self.tableView.reloadData()
    }
    
    override func viewWillAppear(animated: Bool) {
        AudioProvider.sharedInstance.delegate = self
        if AudioProvider.sharedInstance.currentSong != nil {
            self.playerInfoBar.hidden = false
            self.playerInfoBar.updateUI()
        } else {
            self.playerInfoBar.hidden = true
        }
        self.tableView.reloadData()

    }
    
    override func viewDidAppear(animated: Bool) {
        tableView.addPullToRefreshWithActionHandler({
            () -> Void in
            if !self.dataManager.isBusy  {
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
            self.navigationItem.title = "Загрузки"
            self.tableView.reloadData()
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
        if AudioProvider.sharedInstance.currentSong != nil && AudioProvider.sharedInstance.currentSong.id == song.id {
            cell.backgroundColor = UIColor(red:0.14, green:0.43, blue:0.69, alpha: 0.2)
        } else {
            cell.backgroundColor = UIColor.whiteColor()
        }
        if song.downloadId != -1  {
            if self.downloadManager.downloadSongsList[song.downloadId]!.isDownloading {
                cell.progressBar = UIProgressView(frame: CGRectMake(0, 0, cell.frame.width, 2))
                let cellRect = self.tableView.rectForRowAtIndexPath(indexPath)
                let asr = self.tableView.convertRect(cellRect, fromView: self.view)
                cell.progressBar.center = CGPoint(x: (asr.maxX - asr.minX)/2, y: (asr.maxY - asr.minY))
                cell.progressBar.progressTintColor = UIColor(red: 69/255, green:  102/255, blue:  142/255, alpha: 1)
                cell.addSubview(cell.progressBar!)
                self.downloadManager.downloadSongsList[song.downloadId]?.cell = cell
                self.downloadManager.downloadSongsList[song.downloadId]?.cellIndex = indexPath.row
            }
        } else {
            if cell.progressBar != nil {
                cell.progressBar.removeFromSuperview()
            }
            }
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
        if AudioProvider.sharedInstance.shuffled {
            AudioProvider.sharedInstance.shuffle()
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataManager.songs.count
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
        if deltaOffset <= 300 && self.dataManager.songs.count > 0 {
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
        self.createAlertController(index!, filtered: filtered, fromPlayBar: false)
    }
    
    func createAlertController(index: Int, filtered: Bool, fromPlayBar: Bool) {
        var songList = [Song]()
        if filtered {
            songList = self.dataManager.filteredTableData
        } else if fromPlayBar {
            songList = AudioProvider.sharedInstance.playlist
        } else {
            songList = self.dataManager.songs
        }
        let exist = DataBaseManager.sharedInstance.checkExistance("downloads", id: songList[index].id)
        let alertController = UIAlertController(title: "\n \n \n \n", message: "", preferredStyle: UIAlertControllerStyle.ActionSheet)
        if songList[index].ownerId != Int(VKSdk.getAccessToken().userId) && !exist {
            alertController.addAction(UIAlertAction(title: "Добавить в \"Моя Музыка\"", style: UIAlertActionStyle.Default, handler: {
            (UIAlertAction) -> Void in
                self.dataManager.addSongToVK(index)
            }))
        }
        if !exist {
            alertController.addAction(UIAlertAction(title: "Сделать доступной оффлайн", style: UIAlertActionStyle.Default, handler: {
                (UIAlertAction) -> Void in
                let cell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: index, inSection: 0)) as! SongTableViewCell
                let rowIndex = self.tableView.indexPathForCell(cell)
                let song  = songList[index]
                let fdi = FileDownloadInfo()
                if song.downloadId == -1 {
                        fdi.downloadTask = self.downloadManager.session.downloadTaskWithURL(NSURL(string: songList[index].url)!)
                        fdi.isDownloading = true
                        self.downloadManager.downloadSongsList[fdi.downloadTask.taskIdentifier] = fdi
                        fdi.downloadTask.resume()
                        self.downloadManager.downloadSongsList[fdi.downloadTask.taskIdentifier] = fdi
                        song.downloadId = fdi.downloadTask.taskIdentifier
                }
                self.tableView.reloadRowsAtIndexPaths([rowIndex!], withRowAnimation: UITableViewRowAnimation.None)
            }))
        }
        if songList[index].ownerId == Int(VKSdk.getAccessToken().userId) {
            alertController.addAction(UIAlertAction(title: "Удалить из \"Моя музыка\"", style: UIAlertActionStyle.Default, handler: {
                (alert) -> Void in
                let alertController = UIAlertController(title: "Удаление", message: "Вы действительно хотите удалить \(songList[index].title) \(songList[index].artist)", preferredStyle: UIAlertControllerStyle.Alert)
                alertController.addAction(UIAlertAction(title: "ОК", style: UIAlertActionStyle.Default, handler: {
                    (action) -> Void in
                    self.dataManager.removeSongFromVK(index)
                    self.tableView.reloadData()
                }))
                alertController.addAction(UIAlertAction(title: "Отмена", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(alertController, animated: true, completion: nil)
            }))
        }
        
        if self.tabBarController?.selectedIndex < 2 && exist {
            alertController.addAction(UIAlertAction(title: "Удалить из \"Загрузки\"", style: UIAlertActionStyle.Default, handler: {
                (alert) -> Void in
                let alertController = UIAlertController(title: "Удаление", message: "Вы действительно хотите удалить \(songList[index].title) \(songList[index].artist)", preferredStyle: UIAlertControllerStyle.Alert)
                alertController.addAction(UIAlertAction(title: "ОК", style: UIAlertActionStyle.Default, handler: {
                    (action) -> Void in
                    self.dataManager.removeSongFromDownloads(index)
                    self.tableView.reloadData()
                }))
                alertController.addAction(UIAlertAction(title: "Отмена", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(alertController, animated: true, completion: nil)
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
        let index = downloadTask.taskIdentifier
         let fdi =  self.downloadManager.downloadSongsList[index]
        NSOperationQueue.mainQueue().addOperationWithBlock({
            fdi!.downloadProgress = Double(totalBytesWritten)/Double(totalBytesExpectedToWrite)
            let progress = Float(fdi!.downloadProgress)
//            let cell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: fdi.cellIndex, inSection: 0)) as! SongTableViewCell
            if fdi!.cell != nil {
                fdi!.cell.progressBar.progress = Float(progress)
            }
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
        let index = downloadTask.taskIdentifier
        if  self.downloadManager.downloadSongsList.count != 0 {
            let fdi =  self.downloadManager.downloadSongsList[index]
            fdi?.isDownloading = false
            NSOperationQueue.mainQueue().addOperationWithBlock({
                let cellPath = NSIndexPath(forRow: fdi!.cellIndex, inSection: 0)
                self.dataManager.songs[fdi!.cellIndex].localUrl = destURL.path!
                fdi?.isDownloading = false
                self.dataManager.songs[fdi!.cellIndex].downloadId = -1
            DataBaseManager.sharedInstance.addSongToTable(self.dataManager.songs[fdi!.cellIndex], table: "downloads")
                self.tableView.reloadRowsAtIndexPaths([cellPath], withRowAnimation: UITableViewRowAnimation.None)
                self.downloadManager.downloadSongsList.removeValueForKey(index)
            })
        }
        print("dowload complete")
    }
    
    func URLSession(session: NSURLSession, didBecomeInvalidWithError error: NSError?) {
        print(error?.description)
    }
    
    //AudioProviderDelegate FUNCS
    
    
    // MARK: - Navigation


    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
    }

}
