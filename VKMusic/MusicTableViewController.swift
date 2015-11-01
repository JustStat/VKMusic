//
//  MusicTableViewController.swift
//  VKMusic
//
//  Created by Kirill Varlamov on 01.11.15.
//  Copyright © 2015 Kirill Varlamov. All rights reserved.
//

import UIKit

class MusicTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, SongTableViewCellDelegate {
    
    //MARK: Properites
    var dataManager = DataManager()
    
    // MARK: TableDataSource FUNCS
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellIdentifier = "SongTableViewCell"
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! SongTableViewCell
        let song = dataManager.songs[indexPath.row]
        //cell.delegate = self
        cell.nameLabel.text = song.title
        cell.authorLabel.text = song.artist
        cell.durationLabel.text = song.durationToString()
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //Show Player
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataManager.songs.count
    }
    
    //TableDataSource ENDS
    
    //MARK: SongTableViewCellDelegate FUNCS
    
    func createAlertController(cell: SongTableViewCell) {
        
    }
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
