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

protocol AudioProviderDelegate {
    func playerDidFinishPlaying(note: NSNotification)
    //func updatePlayerInfoBar()
}

class AudioProvider: NSObject {
    
    var delegate: AudioProviderDelegate?
    
    enum playerMode {
        case noRepeat
        case songRepeat
        case playListRepeat
    }
    
    var player = AVPlayer()
    var currentIndex  = 0
    var currentSong: Song!
    var coverImage: UIImage!
    var playlist = [Song]();
    static let sharedInstance = AudioProvider()
    var mode = AudioProvider.playerMode.noRepeat
    
    func startPlayer(index: Int) {
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
        try! AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "playerDidFinishPlaying:", name: AVPlayerItemDidPlayToEndTimeNotification, object: csong)
        player.play()
        currentSong = playlist[index]
        currentIndex = index
        currentSong.isPlaying = true
        
    }
    
    func pausePlayer() {
        player.pause()
    }
    
    func playerDidFinishPlaying(note: NSNotification) {
        if self.mode == AudioProvider.playerMode.songRepeat {
            startPlayer(currentIndex)
        } else {
            self.delegate?.playerDidFinishPlaying(note)
        }
    }
    
    func rewind() {
        if currentIndex != 0 {
            currentIndex = currentIndex - 1
            startPlayer(currentIndex)
        } else {
            startPlayer(currentIndex)
        }
    }
    
    func forward() {
        if currentIndex < playlist.count - 1 {
            currentIndex = currentIndex + 1
            startPlayer(currentIndex)
        } else if self.mode == AudioProvider.playerMode.playListRepeat {
            startPlayer(0)
        }
    }
    
    func shuffle() {
        
    }
    
    func setPlayerMode() {
        
    }
    
}

