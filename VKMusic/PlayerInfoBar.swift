//
//  PlayerInfoBar.swift
//  VKMusic
//
//  Created by Kirill Varlamov on 03.11.15.
//  Copyright © 2015 Kirill Varlamov. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import MediaPlayer

class PlayerInfoBar: UIView {

    @IBOutlet weak var coverImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var songProgress: UIProgressView!
    @IBOutlet weak var playerButton: UIButton!
    
    static var sharedInstance = PlayerInfoBar()
    
    var delegate: MusicTableViewController!
    
    func updateUI() {
        NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: Selector("UpadateSliderValue"), userInfo: nil, repeats: true)
        self.titleLabel.text = AudioProvider.sharedInstance.currentSong.title
        self.artistLabel.text = AudioProvider.sharedInstance.currentSong.artist
        //self.coverImage.image = AudioProvider.sharedInstance.coverImage
    }
    
    func UpadateSliderValue() {
        if self.songProgress != nil {
            self.songProgress.progress = Float(CMTimeGetSeconds(AudioProvider.sharedInstance.player.currentTime()))/Float(AudioProvider.sharedInstance.currentSong.duration)
            self.songProgress.reloadInputViews()
        }
    }
    
    @IBAction func moreButtonClick(sender: AnyObject) {
        self.delegate.createAlertController(AudioProvider.sharedInstance.currentIndex,song: AudioProvider.sharedInstance.currentSong, filtered: false, fromPlayBar: true)
    }
    
    @IBAction func playerButtonClick(sender: AnyObject) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewControllerWithIdentifier("MainPlayer") as! PlayerViewController
        vc.currentSongIndex = AudioProvider.sharedInstance.currentIndex
        self.delegate.showDetailViewController(vc, sender: self)
    }
    
    @IBAction func playButtonClick(sender: AnyObject) {
        if AudioProvider.sharedInstance.player.rate == 0.0 {
            if AudioProvider.sharedInstance.last {
                AudioProvider.sharedInstance.startPlayer(AudioProvider.sharedInstance.currentIndex)
                AudioProvider.sharedInstance.last = false
            } else {
                AudioProvider.sharedInstance.player.play()
                (sender as! UIBarButtonItem).image = UIImage(named:"Pause")            }
        } else {
            AudioProvider.sharedInstance.player.pause()
            (sender as! UIBarButtonItem).image = UIImage(named:"Play")
        }
        
    }


}
