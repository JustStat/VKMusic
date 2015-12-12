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
import KVNProgress

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
    var existanceList: [Int: Bool]!
    var canUpdateInterface = true

    override func viewDidLoad() {
        super.viewDidLoad()
        let StatusConfig = KVNProgressConfiguration.defaultConfiguration()
        StatusConfig.minimumDisplayTime = 2
        StatusConfig.circleStrokeForegroundColor = GlobalConstants.colors.VKBlue
        StatusConfig.statusColor = GlobalConstants.colors.VKBlue
        StatusConfig.fullScreen = true
        KVNProgress.setConfiguration(StatusConfig)
        if self.canUpdateInterface && self.type == .AddToPlaylist {
            self.navigationItem.rightBarButtonItem = nil
            self.navigationItem.leftBarButtonItem = nil
        }
        if self.canUpdateInterface && self.type == .Playlist && !(self.number == 7) {
            self.navigationItem.rightBarButtonItems?.append(UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Add, target: self, action: Selector("showAddViewController")))
            self.navigationItem.leftBarButtonItem = nil
 
        }
        if self.canUpdateInterface && self.type == .Playlist && self.number == 7 {
            self.navigationItem.rightBarButtonItem = nil
            self.navigationItem.leftBarButtonItem = nil
        }
        if self.canUpdateInterface {
            KVNProgress.showWithStatus("Загрузка плейлиста")
        }
        self.refreshControl?.addTarget(self, action: Selector("refreshData"), forControlEvents: UIControlEvents.ValueChanged)
        if self.openBackTableButton != nil {
            openBackTableButton.target = self.revealViewController()
            openBackTableButton.action = Selector("revealToggle:")
        }
        self.tableView.emptyDataSetDelegate = self
        self.tableView.emptyDataSetSource = self
        
        //
        
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
        case 7:
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
        if self.number != 1 && self.number != 5{
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                if self.number != 6 && self.number != 7 {
                    self.request = self.dataManager.getReqest(self.number, params: [String: AnyObject]())
                } else if self.number == 7 {
                    self.request = self.dataManager.getReqest(self.number, params: ["friendId":self.playlist.id])
                } else if !self.playlist.isLocal{
                    self.request = self.dataManager.getReqest(self.number, params: ["albumId":self.playlist.id])
                }
                AudioProvider.sharedInstance.delegate = self
                self.tableView.delegate = self
                self.tableView.dataSource = self
                if self.request != nil {
                    self.dataManager.getDataFormVK(self.request, refresh: false, onlyMine: false)
                    if self.type == .AddToPlaylist {
                        self.existanceList = self.dataManager.checkSongExistanceInPlaylist(self.playlist)
                    }
                    dispatch_async(dispatch_get_main_queue()) {
                        self.tableView.reloadData()
                        if self.type == .Playlist {
                            for song in self.dataManager.songs {
                                song.inPlaylst = true
                            }
                        }
                        KVNProgress.dismiss()
                    }
                } else {
                    self.dataManager.songs = []
                    KVNProgress.dismiss()
                }
            }
        }

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
                    KVNProgress.dismiss()
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
        if self.type == .Playlist {
            for song in self.dataManager.songs {
                song.inPlaylst = true
            }
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
        let songProgressBar = UIProgressView(frame: CGRectMake(0,0,UIScreen.mainScreen().bounds.width, 4))
        songProgressBar.tintColor = GlobalConstants.colors.VKBlue
        self.navigationController?.toolbar.addSubview(songProgressBar)
        songProgressBar.center = CGPoint(x: (self.navigationController?.toolbar.center.x)!, y: self.playerInfoBar.frame.maxY + 9)
        self.playerInfoBar.playerButton = playerButton
        self.playerInfoBar.titleLabel = titleLabel
        self.playerInfoBar.artistLabel = artistLabel
        self.playerInfoBar.addSubview(playerButton)
        self.playerInfoBar.songProgress = songProgressBar
        self.playerInfoBar.updateUI()
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
            var exist = false
            if self.playlist != nil {
                if self.playlist.isLocal {
                    exist = DataBaseManager.sharedInstance.checkExistance("playlist\(self.playlist.id)", id: song.id)
                    cell.setCheckImage(exist)
                } else {
                    if let _ = self.existanceList[song.id] {
                        song.inPlaylst = self.existanceList[song.id]!
                    }
                    cell.setCheckImage(song.inPlaylst)
                }
            }
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
        let cell = self.tableView.cellForRowAtIndexPath(indexPath)
        print(cell?.reuseIdentifier)
        if cell?.reuseIdentifier != "AddSongToPlaylistTableViewCell" {
            var next = [Song]()
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewControllerWithIdentifier("MainPlayer") as! PlayerViewController
            if AudioProvider.sharedInstance.nextCount > 0 {
                let alertController = UIAlertController(title: "Вернуться к песням, добавленным в список \"Далее\", по окончании воспроизведения", message: "", preferredStyle: UIAlertControllerStyle.Alert)
                alertController.addAction(UIAlertAction(title: "Сохранить \"Далее\"", style: UIAlertActionStyle.Default, handler: {
                    (action) -> Void in
                    next = AudioProvider.sharedInstance.saveNext()
                    AudioProvider.sharedInstance.playlist = self.dataManager.songs
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

            }
        }
    }
    
    func loadMore() {
        if self.number != 1 && self.number != 6  && self.number != 7 {
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
            if (self.request != nil) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                    self.dataManager.getDataFormVK(self.request, refresh: false, onlyMine: false)
                    dispatch_async(dispatch_get_main_queue()) {
                        self.tableView.reloadData()
                    }
                }
            }
        } else if self.number == 6 && self.playlist.isLocal {
            self.dataManager.songs += DataBaseManager.sharedInstance.GetSongsFromDataBase("playlist\(self.playlist.id)", offset: self.dataManager.songs.count)
        } else if self.number == 7 {
            self.request = self.dataManager.getReqest(self.number, params: ["friendId":self.playlist.id])
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
        self.createAlertController(index!, song: self.dataManager.songs[index!], filtered: filtered, fromPlayBar: false)
    }
    
    
    
    func createAlertController(index: Int, song: Song, filtered: Bool, fromPlayBar: Bool) {
        let alertController = SongAlertController()
        alertController.delegate = self
        if self.number == 0 {
            alertController.isMyMusic = true
        } else {
            alertController.isMyMusic = false
        }
        alertController.index = index
        if !fromPlayBar {
            alertController.song = song
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
        var error = false
        (error, _) = self.dataManager.addSongToVK(song)
        showStatus(error, isAddition: true)
    }
    
    func addSongToDownloads(song: Song) {
        DownloadManager.sharedInstance.donloadSong(song, playlistId: -1)
        self.tableView.reloadData()
        showStatus(false, isAddition: true)
    }
    
    func removeSongFromVKAlertActionClick(song: Song, index: Int) {
        let error = self.dataManager.removeSongFromVK(song)
        if self.number == 0 {
            self.dataManager.songs.removeAtIndex(index)
        }
        self.tableView.reloadData()
        showStatus(error, isAddition: false)
    }
    
    func removeSongFromDownloadsAlertActionClick(song: Song, index: Int) {
        let error = self.dataManager.removeSongFromDownloads(song)
        if self.number == 1 {
            self.dataManager.songs.removeAtIndex(index)
        }
        reloadTable()
        self.tableView.reloadData()
        showStatus(error, isAddition: false)
    }
    
    func removeSongFromPlaylistAlertActionClick(song: Song, index: Int) {
        if self.playlist.isLocal {
            DataBaseManager.sharedInstance.removeSong("playlist\(self.playlist.id)", id: song.id)
        } else {
            self.dataManager.removeSongFromVKPlaylist(song, playlist: self.playlist)
        }
        if self.number == 6 {
            self.dataManager.songs.removeAtIndex(index)
        }
        reloadTable()
        self.tableView.reloadData()
        showStatus(false, isAddition: false)
    }
    
    func addSongToPlaylist(song: Song) {
        if self.number != 0 {
            let alertController = UIAlertController(title: "Трек \(song.title) - \(song.artist) также будет добавлен в \"Моя музыка\"", message: "Продолжить?", preferredStyle: .Alert)
            alertController.addAction(UIAlertAction(title: "Ок", style: .Default, handler: {(alert) -> Void in
                let nvc = self.storyboard!.instantiateViewControllerWithIdentifier("PlaylistNC") as! UINavigationController
                let vc = nvc.viewControllers[0] as! PlaylistsTableViewController
                vc.isSelection = true
                vc.song = song
                let (_, newId) = self.dataManager.addSongToVK(song)
                vc.song.id = newId
                vc.song.ownerId = Int(VKSdk.getAccessToken().userId)
                vc.navigationItem.title = "Добавление в плейлист"
                vc.navigationItem.rightBarButtonItem = nil
                vc.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: vc, action: Selector("dismissView"))
                self.showDetailViewController(nvc, sender: self)
            }))
            alertController.addAction(UIAlertAction(title: "Отмена", style: .Cancel, handler: nil))
            self.presentViewController(alertController, animated: true, completion: nil)
        } else {
            let nvc = self.storyboard!.instantiateViewControllerWithIdentifier("PlaylistNC") as! UINavigationController
            let vc = nvc.viewControllers[0] as! PlaylistsTableViewController
            vc.isSelection = true
            vc.song = song
            vc.navigationItem.title = "Добавление в плейлист"
            vc.navigationItem.rightBarButtonItem = nil
            vc.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: vc, action: Selector("dismissView"))
            self.showDetailViewController(nvc, sender: self)
        }
    }
    
    func playNextAlertActionClick(song: Song) {
        AudioProvider.sharedInstance.playlist.insert(song, atIndex: AudioProvider.sharedInstance.currentIndex + 1)
        AudioProvider.sharedInstance.nextCount++
        if AudioProvider.sharedInstance.playlist.count == 1 {
            AudioProvider.sharedInstance.startPlayer(0)
            AudioProvider.sharedInstance.pausePlayer()
            self.navigationController?.toolbar.hidden = false
            self.preparePalayerInfoBar()
        }
        reloadTable()
        showStatus(false, isAddition: true)
    }
    
    func addToNext(song: Song) {
        AudioProvider.sharedInstance.playlist.insert(song, atIndex: AudioProvider.sharedInstance.currentIndex + AudioProvider.sharedInstance.nextCount + 1)
        AudioProvider.sharedInstance.nextCount++
        if AudioProvider.sharedInstance.playlist.count == 1 {
            AudioProvider.sharedInstance.startPlayer(0)
            AudioProvider.sharedInstance.pausePlayer()
            self.navigationController?.toolbar.hidden = false
            self.preparePalayerInfoBar()
        }
        reloadTable()
        showStatus(false, isAddition: true)
    }
    
    //SongAlertControllerDelegate ENDS
    
    func showStatus(error: Bool, isAddition: Bool) {
        if !error {
            KVNProgress.configuration().minimumSuccessDisplayTime = 2
            KVNProgress.configuration().successColor = GlobalConstants.colors.VKBlue
            KVNProgress.configuration().statusColor = GlobalConstants.colors.VKBlue
            KVNProgress.configuration().fullScreen = true
            if isAddition {
                KVNProgress.showSuccessWithStatus("Добавлено")
            } else {
                KVNProgress.showSuccessWithStatus("Удалено")
            }
        } else {
            KVNProgress.configuration().minimumErrorDisplayTime = 2
            KVNProgress.configuration().errorColor = GlobalConstants.colors.VKBlue
            KVNProgress.configuration().statusColor = GlobalConstants.colors.VKBlue
            KVNProgress.configuration().fullScreen = true
            KVNProgress.showErrorWithStatus("Ошибка")
        }
    }
    
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
        self.canUpdateInterface = false
        self.viewDidLoad()
        self.viewWillAppear(false)
        self.canUpdateInterface = true
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
                case 7:
                    text = "Список музыки " + self.navigationItem.title! + " пуст"
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
                case 7:
                    text = "Поделитесь с друзьями любимыми песнями"
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
                } else if self.number == 6 {
                    text = "Добавить песни"
                } else {
                    return nil
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
            self.tableView.reloadRowsAtIndexPaths([self.tableView.indexPathForCell(cell)!], withRowAnimation: .None)
        } else {
             dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                self.dataManager.addSongToVKPlaylist(song.id, albumId: self.playlist.id)
                let ip = self.tableView.indexPathForCell(cell)!
            }
        }
    }
    
     //MARK: AddSongToPlaylistTableViewCellDelegate ENDS
    
    func playerDidFinishPlaying(note: NSNotification) {
        self.tableView.reloadData()
        self.updatePlayerInfoBar()
    }
    
    func finishLoadingSong() {
        //
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
