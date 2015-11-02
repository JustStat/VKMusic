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

class MusicTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, SongTableViewCellDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    //MARK: Properites
    var dataManager = DataManager()
    var refreshControl: UIRefreshControl!
    var request: VKRequest!
    
    override func viewDidLoad() {
        dataManager.getDataFormVK(self.request, refresh: false)
    }
    
    // MARK: TableDataSource FUNCS
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellIdentifier = "SongTableViewCell"
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! SongTableViewCell
        print(indexPath.row)
        if dataManager.songs.count >= indexPath.row {
        let song = dataManager.songs[indexPath.row]
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
        return dataManager.songs.count
    }
    
    func loadMore() {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                self.dataManager.getDataFormVK(self.request, refresh: false)
            }
            dispatch_async(dispatch_get_main_queue()) {
                self.tableView.reloadData()
            }
    }
    
    
    //TableDataSource ENDS
    
    //MARK: TableIntaration FUNCS
    
    
    func createCellAlertController(cell: SongTableViewCell) {
        let index = tableView.indexPathForCell(cell)?.row
        self.createAlertController(index!)
    }
    
    func createAlertController(index: Int) {
        let alertController = UIAlertController(title: "\n \n \n \n", message: "", preferredStyle: UIAlertControllerStyle.ActionSheet)
        alertController.addAction(UIAlertAction(title: "Добавить в \"Моя Музыка\"", style: UIAlertActionStyle.Default, handler: {
            (UIAlertAction) -> Void in
            
        }))
        alertController.addAction(UIAlertAction(title: "Сделать доступной оффлайн", style: UIAlertActionStyle.Default, handler: nil))
        alertController.addAction(UIAlertAction(title: "Отменить", style: UIAlertActionStyle.Cancel, handler: nil))
        alertController.view.tintColor = UIColor(red:0.27, green:0.40, blue:0.56, alpha:1.0)
        let titleView = UIView(frame: CGRectMake(alertController.view.frame.minX + 10, alertController.view.frame.minY + 10, 300, 50))
        var song: AVPlayerItem!
        var coverImage = UIImage(named: "DefCover")
        let imageView = UIImageView(image: coverImage)
        imageView.frame = CGRectMake(0, 0, 80, 80)
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            if self.dataManager.songs[index].localUrl != "" {
                song = AVPlayerItem(URL: NSURL(string: self.dataManager.songs[index].localUrl)!)
            } else {
                song = AVPlayerItem(URL: NSURL(string: self.dataManager.songs[index].url)!)
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
//                imageView.reloadInputViews()
//                alertController.reloadInputViews()
            }
        }
        titleView.backgroundColor = alertController.view.backgroundColor
        let titleLabel = UILabel(frame: CGRectMake(85, 0, 170, 20))
        titleLabel.text = dataManager.songs[index].title
        titleLabel.font.fontWithSize(13)
        let artistLabel = UILabel(frame: CGRectMake(85, 25, 170, 20))
        artistLabel.textColor = UIColor.lightGrayColor()
        artistLabel.text = dataManager.songs[index].artist
        artistLabel.font.fontWithSize(10)
        titleView.addSubview(titleLabel)
        titleView.addSubview(artistLabel)
        titleView.addSubview(imageView)
        alertController.view.addSubview(titleView)
        self.presentViewController(alertController, animated: true, completion: nil)
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
