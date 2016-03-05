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
import KVNProgress
import MarqueeLabel

class PlayerViewController: UIViewController, AudioProviderDelegate, SongAlertControllerDelegate {
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var broadCastButton: UIButton!
    @IBOutlet weak var controlsView: UIView!
    @IBOutlet weak var VolumeControlView: UIView!
    @IBOutlet weak var coverImage: UIImageView!
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var songProgressBar: UIView!
    @IBOutlet weak var playModeButton: UIButton!
    @IBOutlet weak var shuffleButton: UIButton!
    @IBOutlet weak var backToPreviousButton: UIButton!
    @IBOutlet weak var SongProgressSlider: UISlider!
    @IBOutlet weak var skipToNextButton: UIButton!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var songArtistLabelView: UIView!
    @IBOutlet weak var songTitleLabelView: UIView!
    @IBOutlet weak var secondsLeftLabel: UILabel!
    @IBOutlet weak var currentSecondsLabel: UILabel!
    var volumeControl: MPVolumeView!
    var songArtistLabel: MarqueeLabel!
    var songTitleLabel: MarqueeLabel!
    var currentSongIndex = 0
    var isChangingTime = false
    var wasPlaying = false
    var dataManager = DataManager()
    var songIsLoaded = false
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
        KVNProgress.showWithStatus("Загрузка трека")
        KVNProgress.configuration().fullScreen = true
        AudioProvider.sharedInstance.rewind()
    }
    
    @IBAction func forwardButtonClick(sender: AnyObject) {
        KVNProgress.showWithStatus("Загрузка трека")
        KVNProgress.configuration().fullScreen = true
        AudioProvider.sharedInstance.forward()
    }
    
    @IBAction func changeValue(sender: AnyObject) {
        //AVAudioSession.sharedInstance().s = self.volumeSlider.value
    }
    @IBAction func doneButtonClick(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func EditCurrentTime(sender: AnyObject) {
        AudioProvider.sharedInstance.player.seekToTime(CMTimeMakeWithSeconds(Double(self.SongProgressSlider.value), AudioProvider.sharedInstance.player.currentTime().timescale))
        MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo![MPNowPlayingInfoPropertyElapsedPlaybackTime] = Double(self.SongProgressSlider.value)
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
    
    func UpdateSliderValue() {
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
    
    func finishLoadingSong() {
        self.updateSongInfo()
        KVNProgress.dismiss()
        songIsLoaded = true
    }
    
    func loadMore() {
        //
    }
    
    func updatePlayerInfoBar() {
        //empty
    }

    
    func updateUI() {
        let currentTime = CMTimeGetSeconds(AudioProvider.sharedInstance.player.currentTime())
        if !currentTime.isNaN {
            var time = String(format: "%02d:%02d", arguments: [Int(currentTime / 60), Int(currentTime % 60)])
            self.currentSecondsLabel.text = time
            let duration = self.SongProgressSlider.maximumValue
            time = String(format: "%02d:%02d", arguments: [(Int(duration) - Int(currentTime)) / 60, (Int(duration) - Int(currentTime)) % 60])
            self.secondsLeftLabel.text = time
        }
    }
    
    func updateSongInfo() {
        NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: Selector("UpdateSliderValue"), userInfo: nil, repeats: true)
        self.coverImage.image = AudioProvider.sharedInstance.coverImage
        self.songTitleLabel.text = AudioProvider.sharedInstance.currentSong.title
        self.songArtistLabel.text = AudioProvider.sharedInstance.currentSong.artist
        self.SongProgressSlider.maximumValue = Float(AudioProvider.sharedInstance.currentSong.duration)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        songIsLoaded = false
        KVNProgress.configuration().fullScreen = true
        KVNProgress.configuration().statusColor = GlobalConstants.colors.VKBlue
        KVNProgress.configuration().minimumDisplayTime = 2
        self.coverImage.userInteractionEnabled = true
        let downSwipe = UISwipeGestureRecognizer(target: self, action: Selector("doneButtonClick:"))
        downSwipe.direction = UISwipeGestureRecognizerDirection.Down
        self.coverImage.addGestureRecognizer(downSwipe)
        if AudioProvider.sharedInstance.player.rate == 1.0 {
            UpdateSliderValue()
        }
        songArtistLabelView.backgroundColor = UIColor.clearColor()
        songArtistLabel = MarqueeLabel(frame: self.songArtistLabelView.bounds, duration: 8, andFadeLength: 10)
        songArtistLabel.textAlignment = .Center
        songArtistLabel.sizeToFit()
        songArtistLabelView.addSubview(songArtistLabel)
        songTitleLabelView.backgroundColor = UIColor.clearColor()
        songTitleLabel = MarqueeLabel(frame: self.songTitleLabelView.bounds, duration: 8, andFadeLength: 10)
        songTitleLabel.textAlignment = .Center
        songTitleLabel.sizeToFit()
        songTitleLabelView.addSubview(songTitleLabel)
        self.VolumeControlView.backgroundColor = UIColor.clearColor()
        volumeControl = MPVolumeView(frame: self.VolumeControlView.bounds)
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
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        volumeControl.frame = self.VolumeControlView.bounds
        songArtistLabel.frame = self.songArtistLabelView.bounds
        songTitleLabel.frame = self.songTitleLabelView.bounds
    }
    
    
    override func viewWillAppear(animated: Bool) {
        if !songIsLoaded {
            KVNProgress.showWithStatus("Загрузка трека")
        }
        AudioProvider.sharedInstance.delegate = self
        if AudioProvider.sharedInstance.currentSong != nil {
            updateSongInfo()
        }
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
        
        if !AudioProvider.sharedInstance.isBroadcasting {
            self.broadCastButton.setImage(UIImage(named: "Megaphone"), forState: .Normal)
        } else {
            self.broadCastButton.setImage(UIImage(named: "MegaphoneFilled"), forState: .Normal)
        }
        if AudioProvider.sharedInstance.currentSong != nil && AudioProvider.sharedInstance.currentSong.id == AudioProvider.sharedInstance.playlist[currentSongIndex].id {
            KVNProgress.dismiss()
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        if AudioProvider.sharedInstance.currentSong != nil && AudioProvider.sharedInstance.currentSong.id == AudioProvider.sharedInstance.playlist[currentSongIndex].id {
            KVNProgress.dismiss()
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

    
    func addSongToVKAlertActonClick(song: Song) {
        var error = false
        (error, _) = self.dataManager.addSongToVK(song)
        showStatus(error, isAddition: true)
    }
    
    func addSongToDownloads(song: Song) {
        DownloadManager.sharedInstance.donloadSong(song, playlistId: -1)
        showStatus(false, isAddition: true)
    }
    
    func removeSongFromVKAlertActionClick(song: Song, index: Int) {
        let error = self.dataManager.removeSongFromVK(song)
        showStatus(error, isAddition: false)
    }
    
    func removeSongFromDownloadsAlertActionClick(song: Song, index: Int) {
        let error = self.dataManager.removeSongFromDownloads(song)
        showStatus(error, isAddition: false)
    }
    
    func removeSongFromPlaylistAlertActionClick(song: Song, index: Int) {
        //
            }
    
    func addSongToPlaylist(song: Song) {
        if song.ownerId != Int(VKSdk.getAccessToken().userId) {
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
        showStatus(false, isAddition: true)
    }
    
    func addToNext(song: Song) {
        AudioProvider.sharedInstance.playlist.insert(song, atIndex: AudioProvider.sharedInstance.currentIndex + AudioProvider.sharedInstance.nextCount + 1)
        AudioProvider.sharedInstance.nextCount++
        showStatus(false, isAddition: true)
    }
    
    func getSongRecomendations(song: Song) {
        let nvc = self.storyboard!.instantiateViewControllerWithIdentifier("mainNavController") as! UINavigationController
        let vc = nvc.viewControllers[0] as! MusicTableViewController
        vc.number = 8
        vc.song = song
        vc.canUpdateInterface = false
        vc.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: vc, action: Selector("dismissView"))
        vc.navigationItem.leftBarButtonItem = nil
        self.showDetailViewController(nvc, sender: self)

    }
    
    //SongAlertControllerDelegate ENDS
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Portrait
    }

    @IBAction func broadcastButtonClick(sender: AnyObject) {
        if !AudioProvider.sharedInstance.isBroadcasting {
            AudioProvider.sharedInstance.isBroadcasting = true
            self.broadCastButton.setImage(UIImage(named: "MegaphoneFilled"), forState: .Normal)
            AudioProvider.sharedInstance.startBroadcast()
        } else {
            AudioProvider.sharedInstance.isBroadcasting = false
            self.broadCastButton.setImage(UIImage(named: "Megaphone"), forState: .Normal)
            AudioProvider.sharedInstance.stopBroadcast()

        }
    }
    

}
