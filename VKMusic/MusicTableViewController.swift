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

class MusicTableViewController: UITableViewController, SongTableViewCellDelegate,  AudioProviderDelegate, PKRevealing, UISearchControllerDelegate, SongAlertControllerDelegate, DownloadTableViewCellDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, AddSongToPlaylistTableViewCellDelegate {
    
    enum MusicVCType {
        case Playlist
        case AddToPlaylist
        case Normal
        case Next
    }
    
    @IBOutlet weak var openBackTableButton: UIBarButtonItem!
    var dataManager = DataManager()
    var type: MusicVCType = .Normal
    var playerInfoBar: PlayerInfoBar!
    var request: VKRequest!
    var number = 0
    var playlist: Playlist!

    override func viewDidLoad() {
        super.viewDidLoad()
        if self.type == .AddToPlaylist {
            self.navigationItem.rightBarButtonItem = nil
            self.navigationItem.leftBarButtonItem = nil
        }
        if self.type == .Playlist {
            self.navigationItem.rightBarButtonItems?.append(UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Add, target: self, action: Selector("showAddViewController")))
            self.navigationItem.leftBarButtonItem = nil
 
        }
        MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        self.refreshControl?.addTarget(self, action: Selector("refreshData"), forControlEvents: UIControlEvents.ValueChanged)
        if self.openBackTableButton != nil {
            openBackTableButton.target = self.revealViewController()
            openBackTableButton.action = Selector("revealToggle:")
        }
        self.tableView.emptyDataSetDelegate = self
        self.tableView.emptyDataSetSource = self
        if self.number != 1 && self.number != 5{
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                if self.number != 6 {
                self.request = self.dataManager.getReqest(self.number, params: [String: AnyObject]())
                } else if !self.playlist.isLocal{
                    self.request = self.dataManager.getReqest(self.number, params: ["albumId":self.playlist.id])
                }
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
                    MBProgressHUD.hideHUDForView(self.view, animated: true)
                }
            }
        }
        
        switch self.number {
        case 0:
            if self.type == .Normal {
            self.navigationItem.title = "Моя музыка"
            } else {
                self.navigationItem.title = "Добавление в плейлист ВК"
            }
        case 1:
            if self.type == .Normal {
                self.navigationItem.title = "Загрузки"
            } else {
                self.navigationItem.title = "Добавление в локальный плейлист"
            }
        case 2:
            self.navigationItem.title = "Популярное"
        case 3:
            self.navigationItem.title = "Рекомендуемое"
        case 6:
            self.navigationItem.title = self.playlist.name
        default:
            print("error")
        }   

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func viewWillAppear(animated: Bool) {
        if self.number == 1 || self.number == 6 {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                if self.number == 6 && self.playlist.isLocal {
                    self.dataManager.songs = DataBaseManager.sharedInstance.GetSongsFromDataBase("playlist\(self.playlist.id)", offset: 0)
                    
                } else if self.number == 1 {
                    self.dataManager.songs = DataBaseManager.sharedInstance.GetSongsFromDataBase("downloads", offset: 0)
                }
                dispatch_async(dispatch_get_main_queue()) {
                    if self.dataManager.songs.count == 0 {
                     self.dataManager.error = DataManager.ErrorType.NoContent
                    } else {
                        self.dataManager.error = nil
                    }
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
        titleLabel.font = UIFont.systemFontOfSize(15)
        titleLabel.backgroundColor = UIColor.clearColor()
        playerButton.addSubview(titleLabel)
        titleLabel.center = CGPoint(x: playerButton.center.x, y: playerButton.center.y
            - 10)
        let artistLabel = UILabel(frame: titleLabel.frame)
        artistLabel.text = AudioProvider.sharedInstance.currentSong.artist
        artistLabel.textAlignment = NSTextAlignment.Center
        artistLabel.font = UIFont.systemFontOfSize(13)
        artistLabel.backgroundColor = UIColor.clearColor()
        playerButton.addSubview(artistLabel)
        artistLabel.center = CGPoint(x: playerButton.center.x, y: playerButton.center.y
            + 10)
        var stateImage: UIImage!
        if AudioProvider.sharedInstance.player.rate == 0.0 {
            stateImage = UIImage(named:"Play")
        } else {
            stateImage = UIImage(named:"Pause")
        }

        let playPauseButton = UIBarButtonItem(image: stateImage, style: UIBarButtonItemStyle.Plain, target: self, action: nil)
        playPauseButton.target = self.playerInfoBar
        playPauseButton.action = Selector("playButtonClick:")
        let moreButton = UIBarButtonItem(image: UIImage(named: "More"), style: UIBarButtonItemStyle.Plain, target: self, action: nil)
        moreButton.target = self.playerInfoBar
        moreButton.action = Selector("moreButtonClick:")
        self.playerInfoBar.playerButton = playerButton
        self.playerInfoBar.titleLabel = titleLabel
        self.playerInfoBar.artistLabel = artistLabel
        self.playerInfoBar.addSubview(playerButton)
        let barButton = UIBarButtonItem(customView: self.playerInfoBar)
        self.setToolbarItems([playPauseButton, barButton, moreButton], animated: true)
        self.navigationController?.toolbar.tintColor = GlobalConstants.colors.VKBlue
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
            cell.preservesSuperviewLayoutMargins = false
            cell.separatorInset = UIEdgeInsetsZero
            cell.layoutMargins = UIEdgeInsetsZero
            if AudioProvider.sharedInstance.currentSong != nil && AudioProvider.sharedInstance.currentSong.id == song.id {
                cell.backgroundColor = GlobalConstants.colors.VKBlueAlpha
            } else {
                cell.backgroundColor = UIColor.whiteColor()
            }
            return cell
        } else if self.type == .AddToPlaylist {
            let cellIdentifier = "AddSongToPlaylistTableViewCell"
            let cell = self.tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! AddSongToPlaylistTableViewCell
            cell.titleLabel.text = song.title
            cell.artistLabel.text = song.title
            cell.delegate = self
            if DataBaseManager.sharedInstance.checkExistance("playlist\(self.playlist.id)", id: song.id) {
            cell.AddSongToPlaylistButton.imageView?.image = UIImage(named: "CheckedFilled")
            cell.AddSongToPlaylistButton.userInteractionEnabled = false
            }
            //cell.delegate = self
            return cell
        } else {
            let cellIdentifier = "SongTableViewCell"
            let cell = self.tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! SongTableViewCell
            cell.nameLabel.text = song.title
            cell.authorLabel.text = song.artist
            cell.durationLabel.text = song.durationToString()
            cell.delegate = self
            cell.preservesSuperviewLayoutMargins = false
            cell.separatorInset = UIEdgeInsetsZero
            cell.layoutMargins = UIEdgeInsetsZero
            if song.localUrl != "" {
                cell.downloadedMark.hidden = false
            } else {
                cell.downloadedMark.hidden = true
            }
            if AudioProvider.sharedInstance.currentSong != nil && AudioProvider.sharedInstance.currentSong.id == song.id {
                cell.backgroundColor = GlobalConstants.colors.VKBlueAlpha
            } else {
                cell.backgroundColor = UIColor.whiteColor()
            }
            return cell
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var next = [Song]()
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewControllerWithIdentifier("MainPlayer") as! PlayerViewController
        if AudioProvider.sharedInstance.nextCount > 0 {
            let alertController = UIAlertController(title: "Вернуться к песням, добавленным в список \"Далее\", по окончании воспроизведения", message: "", preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: "Сохранить \"Далее\"", style: UIAlertActionStyle.Default, handler: {
                (action) -> Void in
                next = AudioProvider.sharedInstance.saveNext()
                AudioProvider.sharedInstance.playlist = self.dataManager.songs
                AudioProvider.sharedInstance.playlist.insertContentsOf(next, at: vc.currentSongIndex + 1)
                AudioProvider.sharedInstance.number = self.number
                AudioProvider.sharedInstance.viewPlaylist = self.playlist
                vc.currentSongIndex = indexPath.row
                if next.count > 0 {
                    AudioProvider.sharedInstance.playlist.insertContentsOf(next, at: vc.currentSongIndex + 1)
                }
                self.showDetailViewController(vc, sender: self)
                if AudioProvider.sharedInstance.shuffled {
                    AudioProvider.sharedInstance.shuffle()
                }

            }))
            alertController.addAction(UIAlertAction(title: "Отчистить \"Далее\"", style: .Default, handler: {
                (action) -> Void in
                AudioProvider.sharedInstance.nextCount = 0
                AudioProvider.sharedInstance.playlist = self.dataManager.songs
                AudioProvider.sharedInstance.number = self.number
                AudioProvider.sharedInstance.viewPlaylist = self.playlist
                vc.currentSongIndex = indexPath.row
                self.showDetailViewController(vc, sender: self)
                if AudioProvider.sharedInstance.shuffled {
                    AudioProvider.sharedInstance.shuffle()
                }

            }))
            alertController.addAction(UIAlertAction(title: "Отмена", style: .Cancel, handler: nil))
            self.presentViewController(alertController, animated: true, completion: nil)
        } else {
            AudioProvider.sharedInstance.nextCount = 0
            AudioProvider.sharedInstance.playlist = self.dataManager.songs
            AudioProvider.sharedInstance.number = self.number
            AudioProvider.sharedInstance.viewPlaylist = self.playlist
            vc.currentSongIndex = indexPath.row
            self.showDetailViewController(vc, sender: self)
            if AudioProvider.sharedInstance.shuffled {
                AudioProvider.sharedInstance.shuffle()
            }
//            AudioProvider.sharedInstance.playlist = self.dataManager.songs
//            var index = 0
//            for var i = 0; i < indexPath.section; ++i {
//                index += tableView.numberOfRowsInSection(i) - 1
//                if index < 0 {
//                    index = 0
//                }
//            }
//            index += indexPath.row
//            vc.currentSongIndex = index
//            self.showDetailViewController(vc, sender: self)
//            if AudioProvider.sharedInstance.shuffled {
//                AudioProvider.sharedInstance.shuffle()
//            }

        }
    }
    
    func loadMore() {
        if self.number != 1 && self.number != 6 {
            self.request = self.dataManager.getReqest(self.number, params: [String: AnyObject]())
            if (self.request != nil) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                    self.dataManager.getDataFormVK(self.request, refresh: false, onlyMine: false)
                    dispatch_async(dispatch_get_main_queue()) {
                        self.tableView.reloadData()
                    }
                }
            }
        } else if self.number == 6 && !self.playlist.isLocal{
            self.request = self.dataManager.getReqest(self.number, params: ["albumId":self.playlist.id])
        } else if self.number == 6 && self.playlist.isLocal {
            self.dataManager.songs += DataBaseManager.sharedInstance.GetSongsFromDataBase("playlist\(self.playlist.id)", offset: self.dataManager.songs.count)
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
            if self.playlist != nil && self.playlist.isLocal {
                alertController.song.inPlaylst = true
            }
        } else {
            alertController.song = AudioProvider.sharedInstance.currentSong
        }
        self.presentViewController(alertController, animated: true, completion: nil)

    }
    
    //SongAlertControllerDelegate FUNCS
    
    func addSongToVKAlertActonClick(song: Song) {
        self.dataManager.addSongToVK(song)
        let HUD = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        HUD.customView = UIImageView(image: UIImage(named: "Checked"))
        HUD.mode = MBProgressHUDMode.CustomView
        HUD.labelText = "Добавлено"
        HUD.hide(true, afterDelay: 2)
    }
    
    func addSongToDownloads(song: Song) {
        DownloadManager.sharedInstance.donloadSong(song, playlistId: -1)
        self.tableView.reloadData()
    }
    
    func removeSongFromVKAlertActionClick(song: Song, index: Int) {
        self.dataManager.removeSongFromVK(song)
        if self.number == 0 {
            self.dataManager.songs.removeAtIndex(index)
        }
        self.tableView.reloadData()
    }
    
    func removeSongFromDownloadsAlertActionClick(song: Song, index: Int) {
        self.dataManager.removeSongFromDownloads(song)
        if self.number == 1 {
            self.dataManager.songs.removeAtIndex(index)
        }
        reloadTable()
        self.tableView.reloadData()
    }
    
    func removeSongFromPlaylistAlertActionClick(song: Song, index: Int) {
        DataBaseManager.sharedInstance.removeSong("playlist\(self.playlist.id)", id: song.id)
        if self.number == 6 {
            self.dataManager.songs.removeAtIndex(index)
        }
        reloadTable()
        self.tableView.reloadData()
    }
    
    func addSongToPlaylist(song: Song) {
        let nvc = storyboard!.instantiateViewControllerWithIdentifier("PlaylistNC") as! UINavigationController
        let vc = nvc.viewControllers[0] as! PlaylistsTableViewController
        vc.isSelection = true
        vc.song = song
        vc.navigationItem.title = "Добавление в плейлист"
        vc.navigationItem.rightBarButtonItem = nil
        vc.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: vc, action: Selector("dismissView"))
        self.showDetailViewController(nvc, sender: self)

    }
    
    func playNextAlertActionClick(song: Song) {
        AudioProvider.sharedInstance.playlist.insert(song, atIndex: AudioProvider.sharedInstance.currentIndex + 1)
        AudioProvider.sharedInstance.nextCount++
        if AudioProvider.sharedInstance.playlist.count == 1 {
            AudioProvider.sharedInstance.startPlayer(0)
            AudioProvider.sharedInstance.pausePlayer()
            self.navigationController?.toolbar.hidden = false
            self.preparePalayerInfoBar()
            reloadTable()

        }
    }
    
    func addToNext(song: Song) {
        AudioProvider.sharedInstance.playlist.insert(song, atIndex: AudioProvider.sharedInstance.currentIndex + AudioProvider.sharedInstance.nextCount + 1)
        AudioProvider.sharedInstance.nextCount++
        if AudioProvider.sharedInstance.playlist.count == 1 {
            AudioProvider.sharedInstance.startPlayer(0)
            AudioProvider.sharedInstance.pausePlayer()
            self.navigationController?.toolbar.hidden = false
            self.preparePalayerInfoBar()
            reloadTable()

        }
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
                self.request = self.dataManager.getReqest(self.number, params: [String: AnyObject]())
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
            if self.dataManager.songs.count == 0 {
                self.dataManager.error = DataManager.ErrorType.NoContent
            } else {
                self.dataManager.error = nil
            }
        }
        self.tableView.reloadData()
        if self.refreshControl != nil {
            self.refreshControl?.endRefreshing()
        }
    }
    
    //MARK: EmptyDataSetDelegate FUNCS
    
    func imageForEmptyDataSet(scrollView: UIScrollView!) -> UIImage! {
        if self.dataManager.error != nil {
            if self.dataManager.error == DataManager.ErrorType.NoConnection {
                return UIImage(named: "NoInternet")
            } else {
                return UIImage(named: "NoContent")
            }
        }
        return UIImage()
    }
    
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        if self.dataManager.error != nil {
            let text:String!
            if self.dataManager.error == DataManager.ErrorType.NoConnection {
                text = "Ошибка подлючения к серверам Вконтакте"
            } else {
                switch self.number {
                case 0:
                    text = "Список музыки ВКонтаке пуст"
                case 1:
                    text = "Вы пока ничего не загрузили"
                case 3:
                    text = "Нет рекомендаций"
                case 6:
                    text = "Плейлист пуст"
                default:
                    text = ""
                }
            }
            let attrs = [NSFontAttributeName: UIFont.boldSystemFontOfSize(18), NSForegroundColorAttributeName: UIColor.grayColor()]
            return NSAttributedString(string: text, attributes: attrs)
        }
        return NSAttributedString()
    }
    
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        if self.dataManager.error != nil {
            let text:String!
            if self.dataManager.error == DataManager.ErrorType.NoConnection {
                text = "Проверьте интернет подключение и перезагрузите таблицу"
            } else {
                switch self.number {
                case 0:
                    text = "Самое время добавить свои любимые песни в медатеку"
                case 1:
                    text = "Самое время подумать, какие песни взять с собой в дорогу"
                case 3:
                    text = "К сожалению, на данный момент мы ничего не можем вам порекомендовать"
                default:
                    text = ""
                }
            }
            let paragraph = NSMutableParagraphStyle()
            paragraph.lineBreakMode = NSLineBreakMode.ByWordWrapping
            paragraph.alignment = NSTextAlignment.Center
            let attrs = [NSFontAttributeName: UIFont.boldSystemFontOfSize(14), NSForegroundColorAttributeName: UIColor.lightGrayColor(), NSParagraphStyleAttributeName: paragraph]
            return NSAttributedString(string: text, attributes: attrs)
        }
        return NSAttributedString()
    }
    
    func buttonTitleForEmptyDataSet(scrollView: UIScrollView!, forState state: UIControlState) -> NSAttributedString! {
        if self.dataManager.error != nil {
            if self.dataManager.error == DataManager.ErrorType.NoContent {
                var text: String!
                if self.number != 6 {
                    text = "Поиск"
                } else {
                    text = "Добавить песни"
                }
                let attrs = [NSFontAttributeName: UIFont.boldSystemFontOfSize(20), NSForegroundColorAttributeName:  GlobalConstants.colors.VKBlue]
                return NSAttributedString(string: text, attributes: attrs)
            }
        }
        return nil
    }
    
    func backgroundColorForEmptyDataSet(scrollView: UIScrollView!) -> UIColor! {
        return UIColor.whiteColor()
    }
    
    func verticalOffsetForEmptyDataSet(scrollView: UIScrollView!) -> CGFloat {
        return self.tableView.frame.size.height/16
    }
    
    func emptyDataSetShouldDisplay(scrollView: UIScrollView!) -> Bool {
        if self.dataManager.error != nil {
            self.tableView.separatorStyle = UITableViewCellSeparatorStyle.None
            return true
        } else {
            self.tableView.separatorStyle = UITableViewCellSeparatorStyle.SingleLine
            return false
        }
    }
    
    func emptyDataSetShouldAllowTouch(scrollView: UIScrollView!) -> Bool {
        return true
    }
    
    func emptyDataSetShouldAllowScroll(scrollView: UIScrollView!) -> Bool {
        return true
    }
    
    func emptyDataSetDidTapButton(scrollView: UIScrollView!) {
        if self.number != 6 {
        performSegueWithIdentifier("SearchSegue", sender: self)
        } else {
            self.showAddViewController()
        }
    }
    // EmptyDataSetDelegate ENDS
    
    //MARK: AddSongToPlaylistTableViewCellDelegate FUNCS
    
    func addSongToVKPlaylist(cell: AddSongToPlaylistTableViewCell) {
        let song = self.dataManager.songs[(tableView.indexPathForCell(cell)?.row)!]
        if self.playlist.isLocal {
            DataBaseManager.sharedInstance.addSongToTable(song, table: "playlist\(self.playlist.id)")
        } else {
            self.dataManager.addSongToVKPlaylist(song, albumId: self.playlist.id)
        }
        self.tableView.reloadRowsAtIndexPaths([self.tableView.indexPathForCell(cell)!], withRowAnimation: .None)
    }
    
     //MARK: AddSongToPlaylistTableViewCellDelegate ENDS
    
    func playerDidFinishPlaying(note: NSNotification) {
        self.tableView.reloadData()
        self.updatePlayerInfoBar()
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "SearchSegue" {
            ((segue.destinationViewController as! UINavigationController).viewControllers.first as! SearchTableViewController).startIndex = self.number
        }
    }
    
    func dismissView() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func showAddViewController() {
        if self.playlist != nil {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewControllerWithIdentifier("MainMusicViewController")  as! MusicTableViewController
            vc.type = .AddToPlaylist
            vc.playlist = playlist
            if self.playlist.isLocal {
                vc.number = 1
            } else {
                vc.number = 0
            }
            self.navigationController?.pushViewController(vc, animated: true)

        }
    }
}
