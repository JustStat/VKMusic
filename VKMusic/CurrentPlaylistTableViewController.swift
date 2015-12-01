//
//  CurrentPlaylistTableViewController.swift
//  VKMusic
//
//  Created by Kirill Varlamov on 27.11.15.
//  Copyright © 2015 Kirill Varlamov. All rights reserved.
//

import UIKit

class CurrentPlaylistTableViewController: MusicTableViewController {
    
    var sectionTitles = ["ИСТОРИЯ", "ИСПОЛНЯЕТСЯ", "ДАЛЕЕ"]
    var history: [Song]!
    var nextSongs = [Song]()
    var start = true

    override func viewDidLoad() {
        //super.viewDidLoad()
        self.navigationItem.title = "Далее"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: Selector("dismissView"))
        reloadPlaylist()
        let indexPath = NSIndexPath(forRow: 0, inSection: 1)
        self.tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Top, animated: false)
        self.tableView.allowsSelectionDuringEditing = true
        self.tableView.setEditing(true, animated: true)
        self.tableView.tableFooterView = UIView(frame: CGRectZero)
        self.number = AudioProvider.sharedInstance.number
        if AudioProvider.sharedInstance.viewPlaylist != nil {
            self.playlist = AudioProvider.sharedInstance.viewPlaylist
        }
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func reloadPlaylist() {
        history = DataBaseManager.sharedInstance.GetSongsFromDataBase("history", offset: 0)
        history = history.reverse()
        self.dataManager.songs = AudioProvider.sharedInstance.playlist
//        for var i = AudioProvider.sharedInstance.currentIndex + 1; i < AudioProvider.sharedInstance.playlist.count; ++i {
//            nextSongs.append(AudioProvider.sharedInstance.playlist[i])
//        }
        //self.tableView.setEditing(true, animated: false)
        //let nowPlaying: [Song] = [AudioProvider.sharedInstance.currentSong]
        //self.dataManager.songs = self.history + nowPlaying + nextSongs
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 3
    }
    
//    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//        if section == 2 {
//            let headerView = UIView(frame: <#T##CGRect#>)
//        }
//    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        switch section {
        case 0:
            if self.start {
                return 0
            } else {
                return self.history.count
            }
        case 1:
            return 1
        case 2:
            print(AudioProvider.sharedInstance.playlist.count - AudioProvider.sharedInstance.currentIndex - 1)
            return AudioProvider.sharedInstance.playlist.count - AudioProvider.sharedInstance.currentIndex - 1
        default:
            return 0
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.sectionTitles[section]
    }
    
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if indexPath.section == 2 {
            return true
        } else {
            return false
        }
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if indexPath.section == 2 {
            return true
        } else {
            return false
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if self.start && indexPath.section == 0 {
            return 0
        } else {
            return 48
        }
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if self.start && section == 0 {
            return 0
        } else {
            return 28
        }
    }
    
//    override func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
//        return UITableViewCellEditingStyle.None
//    }
    
    override func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        let index = AudioProvider.sharedInstance.currentIndex + sourceIndexPath.row + 1
        let song = AudioProvider.sharedInstance.playlist[index]
           AudioProvider.sharedInstance.playlist.removeAtIndex(index)
            AudioProvider.sharedInstance.playlist.insert(song, atIndex:AudioProvider.sharedInstance.currentIndex + destinationIndexPath.row + 1)
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        print(indexPath.section)
        if indexPath.section == 0 {
            let cellIdentifier = "SongTableViewCell"
            let song = self.history[indexPath.row]
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
            return cell
        } else if indexPath.section == 1 {
            let cellIdentifier = "NextSongCell"
            let song = AudioProvider.sharedInstance.currentSong
            let cell = self.tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath)
            cell.textLabel?.text = song.title
            (cell.subviews[0].subviews[1] as! UILabel).text = song.artist
            return cell
        } else {
            let cellIdentifier = "NextSongCell"
            let index = AudioProvider.sharedInstance.currentIndex + 1 + indexPath.row
            print(AudioProvider.sharedInstance.playlist.count)
            print(indexPath.row)
            print(tableView.numberOfRowsInSection(2))
            let song = AudioProvider.sharedInstance.playlist[index]
            let cell = self.tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath)
            cell.textLabel?.text = song.title
            (cell.subviews[0].subviews[1] as! UILabel).text = song.artist
            cell.showsReorderControl = true
            return cell
        }

    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 {
            let index = AudioProvider.sharedInstance.currentIndex
            let song = self.history[indexPath.row]
            AudioProvider.sharedInstance.playlist.insert(song, atIndex: index)
            AudioProvider.sharedInstance.startPlayer(index)
        } else if indexPath.section == 1 {
            dismissViewControllerAnimated(true, completion: nil)
        } else {
            let index = AudioProvider.sharedInstance.currentIndex + indexPath.row + 1
            AudioProvider.sharedInstance.startPlayer(index)
        }
        reloadPlaylist()
        self.tableView.reloadData()
    }
    
    override func tableView(tableView: UITableView, targetIndexPathForMoveFromRowAtIndexPath sourceIndexPath: NSIndexPath, toProposedIndexPath proposedDestinationIndexPath: NSIndexPath) -> NSIndexPath {
        if sourceIndexPath.section != proposedDestinationIndexPath.section {
            var row = 0
            if sourceIndexPath.section < proposedDestinationIndexPath.section {
                row = self.tableView(tableView, numberOfRowsInSection: sourceIndexPath.section) - 1
            }
            return NSIndexPath(forRow: row, inSection: sourceIndexPath.section)
        }
        return proposedDestinationIndexPath
    }
    
    override func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        if self.start {
        self.start = false
        self.tableView.reloadData()
        let indexPath = NSIndexPath(forRow: 0, inSection: 1)
        self.tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Top, animated: false)

        }
        super.scrollViewWillBeginDragging(scrollView)
    }
    
    override func loadMore() {
        AudioProvider.sharedInstance.loadMore()
        self.tableView.reloadData()
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
