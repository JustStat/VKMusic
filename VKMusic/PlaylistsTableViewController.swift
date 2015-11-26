//
//  PlaylistsTableViewController.swift
//  VKMusic
//
//  Created by Kirill Varlamov on 19.11.15.
//  Copyright © 2015 Kirill Varlamov. All rights reserved.
//

import UIKit
import VK_ios_sdk

class PlaylistsTableViewController: UITableViewController, UIAlertViewDelegate, PlaylistTableViewCellDelegate {
    
    @IBOutlet weak var addPlayList: UIBarButtonItem!
    
    var dataManager = DataManager()
    var sectionTitles = ["Плейлисты ВКонтакте", "Локальные плейлисты"]
    var isSelection = false
    var song: Song!
    
    @IBAction func addPlaylistButtonClick() {
        let alertController = UIAlertController()
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
        super.viewDidLoad()
        self.dataManager.localPlaylists = DataBaseManager.sharedInstance.GetPlaylistsFormDataBase()
        self.dataManager.getPlaylistsFromVK()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.sectionTitles[section]
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        if self.song != nil && self.song.localUrl == "" {
            return 1
        } else {
            return 2
        }
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if section == 1 {
            return self.dataManager.localPlaylists.count
        } else {
            return self.dataManager.vkPlylists.count
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
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
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if !isSelection {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewControllerWithIdentifier("MainMusicViewController")  as! MusicTableViewController
            vc.number = 6
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
                self.dataManager.addSongToVKPlaylist(self.song, albumId: self.dataManager.vkPlylists[indexPath.row].id)
            }
            self.dismissViewControllerAnimated(true, completion: nil)
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
    
    func createPlaylistAlertController(playlist: Playlist) {
        let alertController = UIAlertController(title: playlist.name, message: "", preferredStyle: UIAlertControllerStyle.ActionSheet)
        if !playlist.isDownloaded {
            alertController.addAction(UIAlertAction(title: "Сделать доступным оффлайн", style: UIAlertActionStyle.Default, handler: {
            (alertAction) -> Void in
            self.dataManager.downloadPlaylist(playlist)
            }))
        }
        alertController.addAction(UIAlertAction(title: "Удалить плейлист", style: UIAlertActionStyle.Default, handler: {
            (alertAction) -> Void in
            self.dataManager.removePlaylist(playlist)
        }))
        alertController.addAction(UIAlertAction(title: "Отменить", style: UIAlertActionStyle.Cancel, handler: nil))
        self.presentViewController(alertController, animated: true, completion: nil)
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
