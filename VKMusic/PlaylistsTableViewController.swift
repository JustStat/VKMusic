//
//  PlaylistsTableViewController.swift
//  VKMusic
//
//  Created by Kirill Varlamov on 19.11.15.
//  Copyright © 2015 Kirill Varlamov. All rights reserved.
//

import UIKit
import VK_ios_sdk
import DZNEmptyDataSet
import SWTableViewCell
import KVNProgress

class PlaylistsTableViewController: UITableViewController, UIAlertViewDelegate, PlaylistTableViewCellDelegate, DZNEmptyDataSetSource {
    
    @IBOutlet weak var addPlayList: UIBarButtonItem!
    
    var dataManager = DataManager()
    var playerInfoBar: PlayerInfoBar!
    var sectionTitles = ["Плейлисты ВКонтакте", "Локальные плейлисты"]
    var isSelection = false
    var song: Song!
    var friendsMode = false
    
    @IBOutlet weak var openBackTableButton: UIBarButtonItem!
    @IBAction func addPlaylistButtonClick() {
        let alertController = UIAlertController()
        alertController.view.tintColor = GlobalConstants.colors.VKBlue
        alertController.addAction(UIAlertAction(title: "Локальный плейлист", style: UIAlertActionStyle.Default, handler: {
            (controller) -> Void in
            let alertView = UIAlertView(title: "Новый локальный плейлист", message: "Введите название плейлиста", delegate: self, cancelButtonTitle: "Отмена", otherButtonTitles: "Ок")
            alertView.alertViewStyle = UIAlertViewStyle.PlainTextInput
            alertView.tag = 1
            alertView.show()
        }))
        alertController.addAction(UIAlertAction(title: "Плейлист ВКонтакте", style: UIAlertActionStyle.Default, handler: {
            (controller) -> Void in
            let alertView = UIAlertView(title: "Новый плейлист ВКонтакте", message: "Введите название плейлиста", delegate: self, cancelButtonTitle: "Отмена", otherButtonTitles: "Ок")
            alertView.alertViewStyle = UIAlertViewStyle.PlainTextInput
            alertView.tag = 0
            alertView.show()
        }))
        alertController.addAction(UIAlertAction(title: "Отмена", style: UIAlertActionStyle.Cancel, handler: nil))
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        //super.viewDidLoad()
        KVNProgress.configuration().minimumSuccessDisplayTime = 2
        KVNProgress.configuration().successColor = GlobalConstants.colors.VKBlue
        KVNProgress.configuration().statusColor = GlobalConstants.colors.VKBlue
        KVNProgress.configuration().minimumErrorDisplayTime = 2
        KVNProgress.configuration().errorColor = GlobalConstants.colors.VKBlue
        if self.openBackTableButton != nil {
            openBackTableButton.target = self.revealViewController()
            openBackTableButton.action = Selector("revealToggle:")
        }
        if self.friendsMode {
            self.navigationItem.title = "Друзья"
            self.navigationItem.rightBarButtonItems = []
            KVNProgress.showWithStatus("Загрузка списка друзей")
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                if !self.friendsMode {
                    self.dataManager.localPlaylists = DataBaseManager.sharedInstance.GetPlaylistsFormDataBase()
                }
                self.dataManager.getPlaylistsFromVK(self.friendsMode)
                dispatch_async(dispatch_get_main_queue()) {
                    self.tableView.reloadData()
                    KVNProgress.dismiss()
                }
            }

        }
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.toolbar.hidden = true
        if !self.friendsMode {
            KVNProgress.showWithStatus("Загрузка списка плейлистов")
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                if !self.friendsMode {
                    self.dataManager.localPlaylists = DataBaseManager.sharedInstance.GetPlaylistsFormDataBase()
                }
                self.dataManager.getPlaylistsFromVK(self.friendsMode)
                dispatch_async(dispatch_get_main_queue()) {
                    self.tableView.reloadData()
                    KVNProgress.dismiss()
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if !self.friendsMode {
            return self.sectionTitles[section]
        } else {
            return nil
        }
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        if !friendsMode {
            if self.song != nil && self.song.localUrl == "" {
                return 1
            } else {
                return 2
            }
        } else {
            return 1
        }
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if !friendsMode {
            if section == 1 {
                return self.dataManager.localPlaylists.count
            } else {
                return self.dataManager.vkPlylists.count
            }
        } else {
            return self.dataManager.vkPlylists.count
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if !friendsMode {
            let cell = tableView.dequeueReusableCellWithIdentifier("PlaylistTableViewCell", forIndexPath: indexPath) as! PlaylistTableViewCell
            cell.delegate = self
            if isSelection {
                cell.moreButton.hidden = true
                cell.accessoryType = UITableViewCellAccessoryType.None
            }
            if indexPath.section == 1 {
                cell.playlistTitleLabel.text = self.dataManager.localPlaylists[indexPath.row].name
                cell.playlist = self.dataManager.localPlaylists[indexPath.row]
                cell.playlist.isDownloaded = true
            } else {
                cell.playlistTitleLabel.text = self.dataManager.vkPlylists[indexPath.row].name
                cell.playlist = self.dataManager.vkPlylists[indexPath.row]
                cell.playlist.isDownloaded = self.dataManager.checkPlaylistDownload(cell.playlist)
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier("FriendsTableViewCell", forIndexPath: indexPath)
            cell.textLabel?.text = self.dataManager.vkPlylists[indexPath.row].name
            cell.imageView?.image = self.dataManager.vkPlylists[indexPath.row].image
            return cell
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var error = false
        if !isSelection {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewControllerWithIdentifier("MainMusicViewController")  as! MusicTableViewController
            if !self.friendsMode {
                vc.number = 6
            } else {
                vc.number = 7
            }
            vc.type = .Playlist
            if indexPath.section == 1 {
                vc.playlist = self.dataManager.localPlaylists[indexPath.row]
            } else {
                vc.playlist = self.dataManager.vkPlylists[indexPath.row]
            }
            self.navigationController?.pushViewController(vc, animated: true)
        } else {
            if indexPath.section == 1 {
               DataBaseManager.sharedInstance.addSongToTable(song, table: "playlist\(self.dataManager.localPlaylists[indexPath.row].id)")
            } else {
                error = self.dataManager.addSongToVKPlaylist(self.song.id, albumId: self.dataManager.vkPlylists[indexPath.row].id)
                //error = self.dataManager.removeSongFromVK(self.song)
            }
            self.dismissViewControllerAnimated(true, completion: {
                if !error {
                    KVNProgress.showSuccessWithStatus("Добавлено")
                } else {
                    KVNProgress.showErrorWithStatus("Ошибка")
                }
            })
        }
    }
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        let playlist = Playlist(name: "", owner: 0, id: 0, isLocal: true)
        if buttonIndex == 1 {
            if alertView.tag == 0 {
                playlist.id = self.dataManager.addPlaylistToVK((alertView.textFieldAtIndex(0)?.text)!)
                playlist.isLocal = false
            } else {
                playlist.id = -1
                playlist.name = (alertView.textFieldAtIndex(0)?.text)!
                playlist.id = self.dataManager.addPlaylistToDataBase(playlist)
                playlist.isLocal = true
            }
            playlist.name = (alertView.textFieldAtIndex(0)?.text)!
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewControllerWithIdentifier("MainMusicViewController")  as! MusicTableViewController
            vc.number = 6
            vc.type = .Playlist
            vc.playlist = playlist
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func dismissView() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //MARK: PlaylistTableViewCellDelegate FUNCS
    
    func createPlaylistAlertController(playlist: Playlist, cell: PlaylistTableViewCell) {
        let alertController = UIAlertController(title: playlist.name, message: "", preferredStyle: UIAlertControllerStyle.ActionSheet)
        alertController.view.tintColor = GlobalConstants.colors.VKBlue
        alertController.addAction(UIAlertAction(title: "Воспроизвести далее", style: .Default, handler: {(alert) -> Void in
            var playlistSongs = [Song]()
            if playlist.isLocal {
                var curSize = 0
                var newSize = 0
                repeat {
                    curSize = playlistSongs.count
                    playlistSongs += DataBaseManager.sharedInstance.GetSongsFromDataBase("playlist\(playlist.id)", offset: playlistSongs.count)
                    newSize = playlistSongs.count
                } while curSize != newSize
            } else {
                let req = VKRequest(method: "audio.get", andParameters: [VK_API_USER_ID: VKSdk.getAccessToken().userId,VK_API_ALBUM_ID: playlist.id], andHttpMethod: "GET")
                self.dataManager.getDataFormVK(req, refresh: true, onlyMine: false)
                playlistSongs = self.dataManager.songs
            }
            var count = 0
            for song in playlistSongs {
                count++
                AudioProvider.sharedInstance.playlist.insert(song, atIndex: AudioProvider.sharedInstance.currentIndex + count)
                AudioProvider.sharedInstance.nextCount++
            }
            self.showStatus(false, isAddition: true)
        }))
        alertController.addAction(UIAlertAction(title: "Добавить в \"Далее\"", style: .Default, handler: {(alert) -> Void in
            var playlistSongs = [Song]()
            if playlist.isLocal {
                var curSize = 0
                var newSize = 0
                repeat {
                    curSize = playlistSongs.count
                    playlistSongs += DataBaseManager.sharedInstance.GetSongsFromDataBase("playlist\(playlist.id)", offset: playlistSongs.count)
                    newSize = playlistSongs.count
                } while curSize != newSize
            } else {
                let req = VKRequest(method: "audio.get", andParameters: [VK_API_USER_ID: VKSdk.getAccessToken().userId,VK_API_ALBUM_ID: playlist.id], andHttpMethod: "GET")
                self.dataManager.getDataFormVK(req, refresh: false, onlyMine: false)
                playlistSongs = self.dataManager.songs
            }
            for song in playlistSongs {
                AudioProvider.sharedInstance.playlist.insert(song, atIndex: AudioProvider.sharedInstance.currentIndex + AudioProvider.sharedInstance.nextCount)
                AudioProvider.sharedInstance.nextCount++
            }
            self.showStatus(false, isAddition: true)
        }))

        if !playlist.isDownloaded {
            alertController.addAction(UIAlertAction(title: "Сделать доступным оффлайн", style: UIAlertActionStyle.Default, handler: {
            (alertAction) -> Void in
            self.dataManager.downloadPlaylist(playlist)
            }))
        }
        alertController.addAction(UIAlertAction(title: "Удалить плейлист", style: UIAlertActionStyle.Default, handler: {
            (alertAction) -> Void in
            let error = self.dataManager.removePlaylist(playlist)
            self.dataManager.localPlaylists = DataBaseManager.sharedInstance.GetPlaylistsFormDataBase()
            self.dataManager.getPlaylistsFromVK(self.friendsMode)
            self.tableView.reloadData()
            self.showStatus(error, isAddition: false)
        }))
        alertController.addAction(UIAlertAction(title: "Отменить", style: UIAlertActionStyle.Cancel, handler: nil))
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func showStatus(error: Bool, isAddition: Bool) {
        if !error {
            KVNProgress.configuration().minimumSuccessDisplayTime = 2
            KVNProgress.configuration().successColor = GlobalConstants.colors.VKBlue
            KVNProgress.configuration().statusColor = GlobalConstants.colors.VKBlue
            if isAddition {
                KVNProgress.showSuccessWithStatus("Добавлено")
            } else {
                KVNProgress.showSuccessWithStatus("Удалено")
            }
        } else {
            KVNProgress.configuration().minimumErrorDisplayTime = 2
            KVNProgress.configuration().errorColor = GlobalConstants.colors.VKBlue
            KVNProgress.configuration().statusColor = GlobalConstants.colors.VKBlue
            KVNProgress.showErrorWithStatus("Ошибка")
        }
    }
    
    //MARK: EmptyDataSetDelegate FUNCS
    
    func imageForEmptyDataSet(scrollView: UIScrollView!) -> UIImage! {
        if self.dataManager.error != nil {
            if self.dataManager.error == DataManager.ErrorType.NoConnection {
                return UIImage(named: "NoInternet")
            } else {
                if friendsMode {
                    return UIImage(named: "FriendsEmpty")
                } else {
                    return UIImage(named: "NoContent")
                }
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
                if friendsMode {
                    text = "Список друзей пуст"
                } else {
                    text = "Список плейлистов пуст"
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
                if friendsMode {
                    text = "Добавьте своих друзей и знакомых в список \"Друзья\" в ВКонтакте"
                } else {
                    text = "Создайте плейлисты и группируйте музыку под любое насторение"
                }            }
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
                if !self.friendsMode {
                    text = "Создать плейлист"
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
        self.addPlaylistButtonClick()
    }
    // EmptyDataSetDelegate ENDS
    

    
    

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
