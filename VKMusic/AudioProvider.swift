//
//  AudioProvider.swift
//  VKMusic
//
//  Created by Kirill Varlamov on 02.11.15.
//  Copyright © 2015 Kirill Varlamov. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import MediaPlayer

protocol AudioProviderDelegate {
    func playerDidFinishPlaying(note: NSNotification)
    //func updatePlayerInfoBar()
    func loadMore()
}

class AudioProvider: NSObject {
    
    var delegate: AudioProviderDelegate?
    
    enum playerMode {
        case noRepeat
        case songRepeat
        case playListRepeat
    }
    
    var player = AVPlayer()
    var currentIndex  = -1
    var currentSong: Song!
    var coverImage: UIImage!
    var initPlaylist: [Song]!
    var playlist = [Song]()
    static let sharedInstance = AudioProvider()
    var mode = AudioProvider.playerMode.noRepeat
    var shuffled = false
    var last = false
    
    func startPlayer(index: Int) {
        last = false
        var csong = AVPlayerItem!()
        if playlist[index].localUrl != "" {
            csong = AVPlayerItem(URL: NSURL(fileURLWithPath: playlist[index].localUrl))
        } else {
            csong = AVPlayerItem(URL: NSURL(string: playlist[index].url)!)
        }
        coverImage = UIImage(named: "DefCover")
        let metadata = csong.asset.commonMetadata
        for item in metadata {
            if item.commonKey  == "artwork" {
                coverImage = UIImage(data: item.value as! NSData)
            }
            
        }
        player = AVPlayer(playerItem: csong)
        try! AVAudioSession.sharedInstance().setActive(true)
        try! AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "playerDidFinishPlaying:", name: AVPlayerItemDidPlayToEndTimeNotification, object: csong)
        player.play()
        UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
        currentSong = playlist[index]
        let mediaImage = MPMediaItemArtwork(image: coverImage)
        let mediaInfo: [String: AnyObject] = [MPMediaItemPropertyArtist : currentSong.artist, MPMediaItemPropertyTitle : currentSong.title, MPMediaItemPropertyPlaybackDuration: currentSong.duration, MPMediaItemPropertyArtwork: mediaImage]
        MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = mediaInfo
        currentIndex = index
        currentSong.isPlaying = true
        
    }
    
    func pausePlayer() {
        player.pause()
    }
    
    
    func playerDidFinishPlaying(note: NSNotification) {
        if self.mode == AudioProvider.playerMode.songRepeat {
            startPlayer(currentIndex)
        } else if self.mode == AudioProvider.playerMode.noRepeat {
            self.forward()
            self.delegate?.playerDidFinishPlaying(note)
        }
    }
    
    func rewind() {
        if currentIndex != 0 {
            self.playlist[currentIndex].isPlaying = false
            currentIndex = currentIndex - 1
            startPlayer(currentIndex)
        } else {
            startPlayer(currentIndex)
        }
    }
    
    func forward() {
        if currentIndex < playlist.count - 1 {
            self.playlist[currentIndex].isPlaying = false
            currentIndex = currentIndex + 1
            startPlayer(currentIndex)
        } else if self.mode == AudioProvider.playerMode.playListRepeat {
            startPlayer(0)
        } else {
            last = true
        }
        if playlist.count - currentIndex < 2 {
            self.delegate?.loadMore()
        }
    }
    
    func shuffle() {
        if shuffled {
            playlist = initPlaylist
            for var i = 0; i < playlist.count; ++i {
                if playlist[i].isPlaying {
                    currentIndex = i
                }
            }
            shuffled = false
        } else {
            initPlaylist = playlist
            if currentIndex != 0 {
                swap(&playlist[currentIndex], &playlist[0])
                currentIndex = 0
            }
            for i in 1 ..< (playlist.count - 1) {
                let j = Int(arc4random_uniform(UInt32(playlist.count - i))) + i
                if i != j {
                    swap(&playlist[i], &playlist[j])
                }
            }
            shuffled = true
        }
    }
    
    func setPlayerMode() {
        
    }
    
}

