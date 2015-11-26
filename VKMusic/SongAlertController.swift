//
//  SongAlertController.swift
//  VKMusic
//
//  Created by Kirill Varlamov on 12.11.15.
//  Copyright © 2015 Kirill Varlamov. All rights reserved.
//

import UIKit
import VK_ios_sdk
import AVFoundation

protocol SongAlertControllerDelegate {
    func addSongToVKAlertActonClick(song: Song)
    func addSongToDownloads(song: Song)
    func addSongToPlaylist(song: Song)
    func removeSongFromVKAlertActionClick(song: Song, index: Int)
    func removeSongFromDownloadsAlertActionClick(song: Song, index: Int)
    func removeSongFromPlaylistAlertActionClick(song: Song, index: Int)
}

class SongAlertController: UIAlertController {
    
    var delegate: SongAlertControllerDelegate?
    var song: Song!
    var index: Int!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "\n \n \n \n"
        self.message = ""
        let exist = DataBaseManager.sharedInstance.checkExistance("downloads", id: self.song.id)
        if #available(iOS 9.0, *) {
            
        } else {
            self.addAction(UIAlertAction(title: "", style: UIAlertActionStyle.Default, handler: nil))
            self.addAction(UIAlertAction(title: "", style: UIAlertActionStyle.Default, handler: nil))
            for button in self.actions {
                print(button.description)
                (button).enabled = false
            }
        }
        if self.song.ownerId != Int(VKSdk.getAccessToken().userId) {
            self.addAction(UIAlertAction(title: "Добавить в \"Моя Музыка\"", style: UIAlertActionStyle.Default, handler: {
                (UIAlertAction) -> Void in
                self.delegate?.addSongToVKAlertActonClick(self.song)
            }))
        }
        self.addAction(UIAlertAction(title: "Добавить в плейлист...", style: .Default, handler: {(UIAlertAction) -> Void in
            self.delegate?.addSongToPlaylist(self.song)
        }))
        if !exist {
            self.addAction(UIAlertAction(title: "Сделать доступной оффлайн", style: UIAlertActionStyle.Default, handler: {
                (UIAlertAction) -> Void in
                self.delegate?.addSongToDownloads(self.song)
        }))
        }

        if self.song.ownerId == Int(VKSdk.getAccessToken().userId) {
            self.addAction(UIAlertAction(title: "Удалить из \"Моя музыка\"", style: UIAlertActionStyle.Default, handler: {
                (alert) -> Void in
                    self.delegate?.removeSongFromVKAlertActionClick(self.song, index: self.index)
            }))
        }
        
        if  exist {
            self.addAction(UIAlertAction(title: "Удалить из \"Загрузки\"", style: UIAlertActionStyle.Default, handler: {
                (alert) -> Void in
                    self.delegate?.removeSongFromDownloadsAlertActionClick(self.song, index: self.index)
                }))
        }
        
        if self.song.inPlaylst {
            self.addAction(UIAlertAction(title: "Удалить из это плейлиста", style: UIAlertActionStyle.Default, handler: {
                (alert) -> Void in
                    self.delegate?.removeSongFromPlaylistAlertActionClick(self.song, index: self.index)
            }))
        }
        self.addAction(UIAlertAction(title: "Отменить", style: UIAlertActionStyle.Cancel, handler: nil))
        self.view.tintColor = GlobalConstants.colors.VKBlue
        let titleView = UIView(frame: CGRectMake(self.view.frame.minX + 10, self.view.frame.minY + 10, self.view.frame.width - 70, 50))
        titleView.backgroundColor = self.view.backgroundColor
        var song: AVPlayerItem!
        var coverImage = UIImage(named: "DefCover")
        let imageView = UIImageView(image: coverImage)
        imageView.frame = CGRectMake(0, 0, 80, 80)
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            if self.song.localUrl != "" {
                song = AVPlayerItem(URL: NSURL(fileURLWithPath: self.song.localUrl))
            } else {
                song = AVPlayerItem(URL: NSURL(string: self.song.url)!)
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
        let titleLabel = UILabel(frame: CGRectMake(85, 0, titleView.frame.width - 50, 20))
        titleLabel.text = self.song.title
        titleLabel.font.fontWithSize(13)
        let artistLabel = UILabel(frame: CGRectMake(85, 25, titleView.frame.width - 50, 20))
        artistLabel.textColor = UIColor.lightGrayColor()
        artistLabel.text = self.song.artist
        artistLabel.font.fontWithSize(10)
        titleView.addSubview(titleLabel)
        titleView.addSubview(artistLabel)
        titleView.addSubview(imageView)
        self.view.addSubview(titleView)


        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
