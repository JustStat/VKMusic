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


class PlayerViewController: UIViewController, AudioProviderDelegate {
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
        //shuffling
    }
    
    @IBAction func moreButtonClick(sender: AnyObject) {
        let alertController = UIAlertController(title: "\n \n \n \n", message: "", preferredStyle: UIAlertControllerStyle.ActionSheet)
        alertController.addAction(UIAlertAction(title: "Добавить в \"Моя Музыка\"", style: UIAlertActionStyle.Default, handler: {
            (UIAlertAction) -> Void in
            
        }))
        alertController.addAction(UIAlertAction(title: "Сделать доступной оффлайн", style: UIAlertActionStyle.Default, handler: nil))
        alertController.addAction(UIAlertAction(title: "Отменить", style: UIAlertActionStyle.Cancel, handler: nil))
        alertController.view.tintColor = UIColor(red:0.27, green:0.40, blue:0.56, alpha:1.0)
        let titleView = UIView(frame: CGRectMake(alertController.view.frame.minX + 10, alertController.view.frame.minY + 10, 300, 50))
        let imageView = UIImageView(image: AudioProvider.sharedInstance.coverImage)
        imageView.frame = CGRectMake(0, 0, 80, 80)
        titleView.backgroundColor = alertController.view.backgroundColor
        let titleLabel = UILabel(frame: CGRectMake(85, 0, 170, 20))
        titleLabel.text = AudioProvider.sharedInstance.currentSong.title
        titleLabel.font.fontWithSize(13)
        let artistLabel = UILabel(frame: CGRectMake(85, 25, 170, 20))
        artistLabel.textColor = UIColor.lightGrayColor()
        artistLabel.text = AudioProvider.sharedInstance.currentSong.artist
        artistLabel.font.fontWithSize(10)
        titleView.addSubview(titleLabel)
        titleView.addSubview(artistLabel)
        titleView.addSubview(imageView)
        alertController.view.addSubview(titleView)
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
        self.forwardButtonClick(self)
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
        //let VolumeView = MPVolumeView

        if AudioProvider.sharedInstance.player.rate == 1.0 {
            UpadateSliderValue()
        }

    }
    
    override func viewWillAppear(animated: Bool) {
        self.VolumeControlView.backgroundColor = UIColor.clearColor()
        let volumeControl = MPVolumeView(frame: self.VolumeControlView.bounds)
        volumeControl.showsRouteButton = false
        self.VolumeControlView.addSubview(volumeControl)
        //self.view addSubview: myVolumeView];
        //self.volumeSlider.value = AVAudioSession.sharedInstance().outputVolume
        if AudioProvider.sharedInstance.playlist.count != 0 {
            if currentSongIndex >= 0 {
                if AudioProvider.sharedInstance.playlist[currentSongIndex].url != "" && !AudioProvider.sharedInstance.playlist[currentSongIndex].isPlaying  {
                    if AudioProvider.sharedInstance.currentSong != nil {
                        AudioProvider.sharedInstance.currentSong.isPlaying = false
                    }
                    AudioProvider.sharedInstance.pausePlayer()
                    AudioProvider.sharedInstance.startPlayer(currentSongIndex)
                }
                AudioProvider.sharedInstance.delegate = self
                updateSongInfo()
                if AudioProvider.sharedInstance.player.rate == 0.0 {
                    self.playPauseButton.setImage(UIImage(named:"Play"), forState: UIControlState.Normal)
                } else {
                    self.playPauseButton.setImage(UIImage(named:"Pause"), forState: UIControlState.Normal)
                }

                if AudioProvider.sharedInstance.mode == AudioProvider.playerMode.noRepeat {
                    self.playModeButton.setImage(UIImage(named: "Repeat"), forState: UIControlState.Normal)
                } else if AudioProvider.sharedInstance.mode == AudioProvider.playerMode.playListRepeat {
                    self.playModeButton.setImage(UIImage(named: "RepeatFilled"), forState: UIControlState.Normal)
                } else {
                    self.playModeButton.setImage(UIImage(named: "RepeatOne"), forState: UIControlState.Normal)
                }
                
            }
            
        }
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

    }
    @IBAction func playButtonClick(sender: AnyObject) {
        if AudioProvider.sharedInstance.player.rate == 0.0 {
            AudioProvider.sharedInstance.player.play()
            self.playPauseButton.setImage(UIImage(named:"Pause"), forState: UIControlState.Normal)
        } else {
            AudioProvider.sharedInstance.player.pause()
            self.playPauseButton.setImage(UIImage(named:"Play"), forState: UIControlState.Normal)
        }
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Portrait
    }

    

}
