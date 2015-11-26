//
//  PlayerViewController.swift
//  VKMusic
//
//  Created by Kirill Varlamov on 10.09.15.
//  Copyright (c) 2015 Kirill Varlamov. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import MediaPlayer
import VK_ios_sdk

class PlayerViewController: UIViewController, AudioProviderDelegate, SongAlertControllerDelegate {
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var VolumeControlView: UIView!
    @IBOutlet weak var coverImage: UIImageView!
    @IBOutlet weak var songProgressBar: UIView!
    @IBOutlet weak var playModeButton: UIButton!
    @IBOutlet weak var shuffleButton: UIButton!
    @IBOutlet weak var backToPreviousButton: UIButton!
    @IBOutlet weak var SongProgressSlider: UISlider!
    @IBOutlet weak var skipToNextButton: UIButton!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var SongArtistLabel: UILabel!
    @IBOutlet weak var SongTtitleLabel: UILabel!
    @IBOutlet weak var secondsLeftLabel: UILabel!
    @IBOutlet weak var currentSecondsLabel: UILabel!
    var currentSongIndex = 0
    var isChangingTime = false
    var wasPlaying = false
    var dataManager = DataManager()
    @IBAction func startEditingTime(sender: AnyObject) {
        self.isChangingTime = true
        if AudioProvider.sharedInstance.player.rate == 1.0 {
            AudioProvider.sharedInstance.player.pause()
            self.wasPlaying = true
        }
        
    }
    @IBAction func repeatButtonClick(sender: AnyObject) {
        if AudioProvider.sharedInstance.mode == AudioProvider.playerMode.noRepeat {
            AudioProvider.sharedInstance.mode = AudioProvider.playerMode.playListRepeat
            self.playModeButton.setImage(UIImage(named: "RepeatFilled"), forState: UIControlState.Normal)
        } else if AudioProvider.sharedInstance.mode == AudioProvider.playerMode.playListRepeat {
            AudioProvider.sharedInstance.mode = AudioProvider.playerMode.songRepeat
             self.playModeButton.setImage(UIImage(named: "RepeatOne"), forState: UIControlState.Normal)
        } else {
            AudioProvider.sharedInstance.mode = AudioProvider.playerMode.noRepeat
             self.playModeButton.setImage(UIImage(named: "Repeat"), forState: UIControlState.Normal)
        }
    }
    
    @IBAction func shuffleButtonClick(sender: AnyObject) {
        if AudioProvider.sharedInstance.shuffled {
            self.shuffleButton.setImage(UIImage(named: "Shuffle"), forState: UIControlState.Normal)
        } else {
            self.shuffleButton.setImage(UIImage(named: "shuffleFilled"), forState: UIControlState.Normal)
        }
        AudioProvider.sharedInstance.shuffle()
    }
    
    @IBAction func moreButtonClick(sender: AnyObject) {
        let alertController = SongAlertController()
        alertController.delegate = self
        alertController.index = self.currentSongIndex
        alertController.song = AudioProvider.sharedInstance.currentSong
        self.presentViewController(alertController, animated: true, completion: nil)

    }
    
    @IBAction func rewindButtonClick(sender: AnyObject) {
        AudioProvider.sharedInstance.rewind()
        updateSongInfo()
    }
    
    @IBAction func forwardButtonClick(sender: AnyObject) {
        AudioProvider.sharedInstance.forward()
        updateSongInfo()
    }
    
    @IBAction func changeValue(sender: AnyObject) {
        //AVAudioSession.sharedInstance().s = self.volumeSlider.value
    }
    @IBAction func doneButtonClick(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func EditCurrentTime(sender: AnyObject) {
        AudioProvider.sharedInstance.player.seekToTime(CMTimeMakeWithSeconds(Double(self.SongProgressSlider.value), AudioProvider.sharedInstance.player.currentTime().timescale))
        if self.wasPlaying {
            AudioProvider.sharedInstance.player.play()
            self.wasPlaying = false
        }
        self.isChangingTime = false
        AudioProvider.sharedInstance.last = false
    }
    
    @IBAction func Test(sender: AnyObject) {
        AudioProvider.sharedInstance.player.seekToTime(CMTimeMakeWithSeconds(Double(self.SongProgressSlider.value), AudioProvider.sharedInstance.player.currentTime().timescale))
       updateUI()
    }
    
    func UpadateSliderValue() {
        if !self.isChangingTime {
        self.SongProgressSlider.value = Float(CMTimeGetSeconds(AudioProvider.sharedInstance.player.currentTime()))
        updateUI()
        }
        if AudioProvider.sharedInstance.player.rate == 1.0 {
            self.playPauseButton.setImage(UIImage(named: "Pause"), forState: UIControlState.Normal)
        } else {
            self.playPauseButton.setImage(UIImage(named: "Play"), forState: UIControlState.Normal)
        }
    }
    
    func playerDidFinishPlaying(note: NSNotification) {
        self.updateSongInfo()
    }
    
    func loadMore() {
        //
    }
    
    func updatePlayerInfoBar() {
        //empty
    }

    
    func updateUI() {
        let currentTime = CMTimeGetSeconds(AudioProvider.sharedInstance.player.currentTime())
        var time = String(format: "%02d:%02d", arguments: [Int(currentTime / 60), Int(currentTime % 60)])
        self.currentSecondsLabel.text = time
        let duration = self.SongProgressSlider.maximumValue
        time = String(format: "%02d:%02d", arguments: [(Int(duration) - Int(currentTime)) / 60, (Int(duration) - Int(currentTime)) % 60])
        self.secondsLeftLabel.text = time
    }
    
    func updateSongInfo() {
        NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: Selector("UpadateSliderValue"), userInfo: nil, repeats: true)
        self.coverImage.image = AudioProvider.sharedInstance.coverImage
        self.SongTtitleLabel.text = AudioProvider.sharedInstance.currentSong.title
        self.SongArtistLabel.text = AudioProvider.sharedInstance.currentSong.artist
        self.SongProgressSlider.maximumValue = Float(AudioProvider.sharedInstance.currentSong.duration)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.coverImage.userInteractionEnabled = true
        let downSwipe = UISwipeGestureRecognizer(target: self, action: Selector("doneButtonClick:"))
        downSwipe.direction = UISwipeGestureRecognizerDirection.Down
        self.coverImage.addGestureRecognizer(downSwipe)
        if AudioProvider.sharedInstance.player.rate == 1.0 {
            UpadateSliderValue()
        }

    }
    
    override func viewWillAppear(animated: Bool) {
        self.VolumeControlView.backgroundColor = UIColor.clearColor()
        let volumeControl = MPVolumeView(frame: self.VolumeControlView.bounds)
        volumeControl.showsRouteButton = false
        volumeControl.tintColor = GlobalConstants.colors.VKBlue
        volumeControl.sizeToFit()
        self.VolumeControlView.addSubview(volumeControl)
        if AudioProvider.sharedInstance.playlist.count != 0 {
            if currentSongIndex >= 0 {
                if AudioProvider.sharedInstance.currentSong != nil && AudioProvider.sharedInstance.currentSong.id != AudioProvider.sharedInstance.playlist[currentSongIndex].id {
                        AudioProvider.sharedInstance.currentSong.isPlaying = false
                        AudioProvider.sharedInstance.pausePlayer()
                        AudioProvider.sharedInstance.startPlayer(currentSongIndex)
                } else if AudioProvider.sharedInstance.currentSong == nil {
                        AudioProvider.sharedInstance.pausePlayer()
                        AudioProvider.sharedInstance.startPlayer(currentSongIndex)
                }
            }
            AudioProvider.sharedInstance.delegate = self
            updateSongInfo()
            if AudioProvider.sharedInstance.player.rate == 0.0 {
                self.playPauseButton.setImage(UIImage(named:"Play"), forState:UIControlState.Normal)
            } else {
                self.playPauseButton.setImage(UIImage(named:"Pause"), forState:UIControlState.Normal)
            }

            if AudioProvider.sharedInstance.mode == AudioProvider.playerMode.noRepeat {
                self.playModeButton.setImage(UIImage(named: "Repeat"), forState: UIControlState.Normal)
            } else if AudioProvider.sharedInstance.mode == AudioProvider.playerMode.playListRepeat {
                self.playModeButton.setImage(UIImage(named: "RepeatFilled"), forState: UIControlState.Normal)
            } else {
                self.playModeButton.setImage(UIImage(named: "RepeatOne"), forState: UIControlState.Normal)
            }
                
            if AudioProvider.sharedInstance.shuffled {
                self.shuffleButton.setImage(UIImage(named: "suffleFilled"), forState:UIControlState.Normal)
            } else {
                self.shuffleButton.setImage(UIImage(named: "Shuffle"), forState: UIControlState.Normal)
            }
            
        }
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

    }
    @IBAction func playButtonClick(sender: AnyObject) {
        if AudioProvider.sharedInstance.player.rate == 0.0 {
            if AudioProvider.sharedInstance.last {
                AudioProvider.sharedInstance.startPlayer(AudioProvider.sharedInstance.currentIndex)
                AudioProvider.sharedInstance.last = false
            } else {
            AudioProvider.sharedInstance.player.play()
            self.playPauseButton.setImage(UIImage(named:"Pause"), forState: UIControlState.Normal)
            }
        } else {
            AudioProvider.sharedInstance.player.pause()
            self.playPauseButton.setImage(UIImage(named:"Play"), forState: UIControlState.Normal)
        }
        
    }
    
    //SongAlertControllerDelegate FUNCS
    
    func addSongToVKAlertActonClick(song: Song) {
        self.dataManager.addSongToVK(song)
    }
    
    func removeSongFromVKAlertActionClick(song: Song, index: Int) {
        self.dataManager.removeSongFromVK(song)
    }
    
    func removeSongFromDownloadsAlertActionClick(song: Song, index: Int) {
        self.dataManager.removeSongFromDownloads(song)
    }

    
    func addSongToDownloads(song: Song) {
        DownloadManager.sharedInstance.donloadSong(song, playlistId: -1)
    }
    
    func addSongToPlaylist(song: Song) {
        let vc = storyboard!.instantiateViewControllerWithIdentifier("PlaylistsTableViewController") as! PlaylistsTableViewController
        vc.isSelection = true
        vc.song = song
        self.showDetailViewController(vc, sender: self)
    }
    
    func removeSongFromPlaylistAlertActionClick(song: Song, index: Int) {
        //
    }
    
    //SongAlertControllerDelegate ENDS
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Portrait
    }

    

}
