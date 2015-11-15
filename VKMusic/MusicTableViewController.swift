//
//  MusicTableViewController.swift
//  VKMusic
//
//  Created by Kirill Varlamov on 10.11.15.
//  Copyright © 2015 Kirill Varlamov. All rights reserved.
//

import UIKit
import VK_ios_sdk
import AVFoundation
import SwiftyJSON
import Alamofire
import BTNavigationDropdownMenu
import DZNEmptyDataSet
import PKRevealController
import MBProgressHUD

class MusicTableViewController: UITableViewController, SongTableViewCellDelegate,  AudioProviderDelegate, PKRevealing, UISearchControllerDelegate, SongAlertControllerDelegate, DownloadTableViewCellDelegate  {
    
    @IBOutlet weak var openBackTableButton: UIBarButtonItem!
    var dataManager = DataManager()
    var downloadManager: DownloadManager!
    var playerInfoBar: PlayerInfoBar!
    var request: VKRequest!
    var number = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        self.refreshControl?.addTarget(self, action: Selector("refreshData"), forControlEvents: UIControlEvents.ValueChanged)
        openBackTableButton.target = self.revealViewController()
        openBackTableButton.action = Selector("revealToggle:")
        if self.number != 1 {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                self.request = self.dataManager.getReqest(self.number)
                AudioProvider.sharedInstance.delegate = self
                self.tableView.delegate = self
                self.tableView.dataSource = self
                if self.request != nil {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.dataManager.getDataFormVK(self.request, refresh: false, onlyMine: false)
                        MBProgressHUD.hideHUDForView(self.view, animated: true)
                        self.tableView.reloadData()
                    }
                } else {
                    self.dataManager.songs = []
                }
            }
        } else if self.number == 1 {
            self.dataManager.songs = DataBaseManager.sharedInstance.GetSongsFromDataBase("downloads", offset: 0)
        }
        switch self.number {
        case 0:
            self.navigationItem.title = "Моя музыка"
        case 1:
            self.navigationItem.title = "Загрузки"
        case 2:
            self.navigationItem.title = "Популярное"
        case 3:
            self.navigationItem.title = "Рекомендуемое"
        default:
            print("error")
        }   

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func viewWillAppear(animated: Bool) {
        if self.number == 1 {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                self.dataManager.songs = DataBaseManager.sharedInstance.GetSongsFromDataBase("downloads", offset: 0)
                dispatch_async(dispatch_get_main_queue()) {
                    self.tableView.reloadData()
                    MBProgressHUD.hideHUDForView(self.view, animated: true)
                }
            }
        }
        AudioProvider.sharedInstance.delegate = self
        if AudioProvider.sharedInstance.currentSong != nil {
            self.navigationController?.toolbar.hidden = false
            self.preparePalayerInfoBar()
        } else {
            self.navigationController?.toolbar.hidden = true
        }
        if self.number != 1 {
            self.tableView.reloadData()
        }
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
        return self.dataManager.songs.count
    }
    
    func updatePlayerInfoBar() {
        self.playerInfoBar.titleLabel.text = AudioProvider.sharedInstance.currentSong.title
        self.playerInfoBar.artistLabel.text = AudioProvider.sharedInstance.currentSong.artist
    }
    
    func preparePalayerInfoBar() {
        self.playerInfoBar = PlayerInfoBar(frame: CGRectMake(0, 0, (self.navigationController?.toolbar.frame.width)! - 100, (self.navigationController?.toolbar.frame.height)! - 10))
        self.playerInfoBar.delegate = self
        self.playerInfoBar.backgroundColor = UIColor.clearColor()
        let playerButton = UIButton(frame: self.playerInfoBar.frame)
        playerButton.addTarget(self.playerInfoBar, action: Selector("playerButtonClick:"), forControlEvents: UIControlEvents.TouchUpInside)
        let titleLabel = UILabel(frame: CGRectMake(0, 0, playerButton.frame.width - 60, 19))
        titleLabel.text = AudioProvider.sharedInstance.currentSong.title
        titleLabel.textAlignment = NSTextAlignment.Center
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.backgroundColor = UIColor.clearColor()
        playerButton.addSubview(titleLabel)
        titleLabel.center = CGPoint(x: playerButton.center.x, y: playerButton.center.y
            - 10)
        let artistLabel = UILabel(frame: titleLabel.frame)
        artistLabel.text = AudioProvider.sharedInstance.currentSong.artist
        artistLabel.textAlignment = NSTextAlignment.Center
        artistLabel.backgroundColor = UIColor.clearColor()
        artistLabel.adjustsFontSizeToFitWidth = true
        playerButton.addSubview(artistLabel)
        artistLabel.center = CGPoint(x: playerButton.center.x, y: playerButton.center.y
            + 10)
        var stateImage: UIImage!
        if AudioProvider.sharedInstance.player.rate == 0.0 {
            stateImage = UIImage(named:"Play")
        } else {
            stateImage = UIImage(named:"Pause")
        }

        let playPauseButton = UIBarButtonItem(image: stateImage, style: UIBarButtonItemStyle.Bordered, target: self, action: nil)
        playPauseButton.target = self.playerInfoBar
        playPauseButton.action = Selector("playButtonClick:")
        let moreButton = UIBarButtonItem(image: UIImage(named: "More"), style: UIBarButtonItemStyle.Bordered, target: self, action: nil)
        moreButton.target = self.playerInfoBar
        moreButton.action = Selector("moreButtonClick:")
        self.playerInfoBar.playerButton = playerButton
        self.playerInfoBar.titleLabel = titleLabel
        self.playerInfoBar.artistLabel = artistLabel
        //        self.playerInfoBar.moreButton = moreButton
        self.playerInfoBar.addSubview(playerButton)
        let barButton = UIBarButtonItem(customView: self.playerInfoBar)
        self.setToolbarItems([playPauseButton, barButton, moreButton], animated: true)
        self.navigationController?.toolbar.tintColor = UIColor(red:0.14, green:0.43, blue:0.69, alpha:1.0)
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let song = self.dataManager.songs[indexPath.row]
        if let _ = DownloadManager.sharedInstance.downloadSongsList[song.id] {
            let cellIdentifier = "DownloadTableViewCell"
            let cell = self.tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! DownloadTableViewCell
            DownloadManager.sharedInstance.downloadSongsList[song.id]?.delegate = cell
            cell.titleLabel.text = song.title
            cell.artistLabel.text = song.artist
            cell.delegate = self 
            if AudioProvider.sharedInstance.currentSong != nil && AudioProvider.sharedInstance.currentSong.id == song.id {
                cell.backgroundColor = UIColor(red:0.14, green:0.43, blue:0.69, alpha: 0.2)
            } else {
                cell.backgroundColor = UIColor.whiteColor()
            }
            return cell
        } else {
            let cellIdentifier = "SongTableViewCell"
            let cell = self.tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! SongTableViewCell
            cell.nameLabel.text = song.title
            cell.authorLabel.text = song.artist
            cell.durationLabel.text = song.durationToString()
            cell.delegate = self
            if AudioProvider.sharedInstance.currentSong != nil && AudioProvider.sharedInstance.currentSong.id == song.id {
                cell.backgroundColor = UIColor(red:0.14, green:0.43, blue:0.69, alpha: 0.2)
            } else {
                cell.backgroundColor = UIColor.whiteColor()
            }
            return cell
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewControllerWithIdentifier("MainPlayer") as! PlayerViewController
        AudioProvider.sharedInstance.playlist = dataManager.songs
        vc.currentSongIndex = indexPath.row
        self.showDetailViewController(vc, sender: self)
        if AudioProvider.sharedInstance.shuffled {
            AudioProvider.sharedInstance.shuffle()
        }
    }
    
    func loadMore() {
        if self.number != 1 {
            self.request = self.dataManager.getReqest(self.number)
            if (self.request != nil) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                    self.dataManager.getDataFormVK(self.request, refresh: false, onlyMine: false)
                    dispatch_async(dispatch_get_main_queue()) {
                        self.tableView.reloadData()
                    }
                }
            }
        } else {
            self.dataManager.songs += DataBaseManager.sharedInstance.GetSongsFromDataBase("downloads", offset: self.dataManager.songs.count)
        }
    }
    
    override func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        let currentOffset = scrollView.contentOffset.y
        let maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height
        let deltaOffset = maximumOffset - currentOffset
        if deltaOffset <= 1500 && self.dataManager.songs.count > 0 {
            loadMore()
        }
    }
    
    func createCellAlertController(cell: SongTableViewCell) {
        let filtered = false
        let index = tableView.indexPathForCell(cell)?.row
        self.createAlertController(index!, filtered: filtered, fromPlayBar: false)
    }
    
    
    
    func createAlertController(index: Int, filtered: Bool, fromPlayBar: Bool) {
        let alertController = SongAlertController()
        alertController.delegate = self
        alertController.index = index
        if !fromPlayBar {
            alertController.song = self.dataManager.songs[index]
        } else {
            alertController.song = AudioProvider.sharedInstance.currentSong
        }
        self.presentViewController(alertController, animated: true, completion: nil)

    }
    
    //SongAlertControllerDelegate FUNCS
    
    func addSongToVKAlertActonClick(song: Song) {
        self.dataManager.addSongToVK(song)
    }
    
    func addSongToDownloads(song: Song) {
        DownloadManager.sharedInstance.donloadSong(song)
        self.tableView.reloadData()
    }
    
    func removeSongFromVKAlertActionClick(song: Song, index: Int) {
        self.dataManager.removeSongFromVK(song)
        self.dataManager.songs.removeAtIndex(index)
        self.tableView.reloadData()
    }
    
    func removeSongFromDownloadsAlertActionClick(song: Song, index: Int) {
        self.dataManager.removeSongFromDownloads(song)
        self.dataManager.songs.removeAtIndex(index)
        self.tableView.reloadData()
    }
    
    //SongAlertControllerDelegate ENDS
    
    //DownloadTableViewCellDelegate FUNCS
    
    func reloadTable() {
        if self.number  == 1{
            self.dataManager.songs = DataBaseManager.sharedInstance.GetSongsFromDataBase("downloads", offset: 0)
        }
        self.tableView.reloadData()
    }
    
    func stopDownloadTask(cell: DownloadTableViewCell) {
        let index = self.tableView.indexPathForCell(cell)?.row
        let id = self.dataManager.songs[index!].id
        DownloadManager.sharedInstance.downloadSongsList[id]?.downloadTask?.cancel()
    }
    
    //DownloadTableViewCellDelegate ENDS
    
    func refreshData() {
        self.dataManager.songs.removeAll()
        if self.number != 1 {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                self.request = self.dataManager.getReqest(self.number)
                AudioProvider.sharedInstance.delegate = self
                self.tableView.delegate = self
                self.tableView.dataSource = self
                if self.request != nil {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.dataManager.getDataFormVK(self.request, refresh: true, onlyMine: false)
                        self.tableView.reloadData()
                    }
                } else {
                    self.dataManager.songs = []
                }
            }
        } else if self.number == 1 {
            self.dataManager.songs = DataBaseManager.sharedInstance.GetSongsFromDataBase("downloads", offset: 0)
        }
        self.tableView.reloadData()
        if self.refreshControl != nil {
            self.refreshControl?.endRefreshing()
        }
    }
    
    //MARK: SearchDelegate FUNCS
    
    // SearchDelegate ENDS
    
    //MARK: URLSessionsDownloadsDelegate FUNCS
    
//    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
//        print("downloaded \(100*totalBytesWritten/totalBytesExpectedToWrite)")
//        let index = downloadTask.taskIdentifier
//        let fdi =  self.downloadManager.downloadSongsList[index]
//        NSOperationQueue.mainQueue().addOperationWithBlock({
////            fdi!.downloadProgress = Double(totalBytesWritten)/Double(totalBytesExpectedToWrite)
////            let progress = Float(fdi!.downloadProgress)
////            //            let cell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: fdi.cellIndex, inSection: 0)) as! SongTableViewCell
////            if fdi!.cell != nil {
//////                fdi!.cell.progressBar.progress = Float(progress)
////            }
//        })
//        //        cell.progressBar.reloadInputViews()
//        //        cell.reloadInputViews()
//        
//    }
//    
//    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
//        let destFileName = downloadTask.originalRequest?.URL?.lastPathComponent
////        let destURL = self.downloadManager.docDirectoryURL.URLByAppendingPathComponent(destFileName!)
//        
////        if NSFileManager.defaultManager().fileExistsAtPath(destURL.path!) {
////            do { try NSFileManager.defaultManager().removeItemAtURL(destURL)} catch {}
////        }
////        do {try NSFileManager.defaultManager().copyItemAtURL(location, toURL: destURL)} catch {}
////        let index = downloadTask.taskIdentifier
////        if  self.downloadManager.downloadSongsList.count != 0 {
////            let fdi =  self.downloadManager.downloadSongsList[index]
////            fdi?.isDownloading = false
////            NSOperationQueue.mainQueue().addOperationWithBlock({
////                let cellPath = NSIndexPath(forRow: fdi!.cellIndex, inSection: 0)
////                self.dataManager.songs[fdi!.cellIndex].localUrl = destURL.path!
////                fdi?.isDownloading = false
////                self.dataManager.songs[fdi!.cellIndex].downloadId = -1
////                DataBaseManager.sharedInstance.addSongToTable(self.dataManager.songs[fdi!.cellIndex], table: "downloads")
////                self.tableView.reloadRowsAtIndexPaths([cellPath], withRowAnimation: UITableViewRowAnimation.None)
////                self.downloadManager.downloadSongsList.removeValueForKey(index)
////            })
////        }
//        print("dowload complete")
//    }
    
    func playerDidFinishPlaying(note: NSNotification) {
        self.tableView.reloadData()
        self.updatePlayerInfoBar()
    }
    
    func URLSession(session: NSURLSession, didBecomeInvalidWithError error: NSError?) {
        print(error?.description)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
}
