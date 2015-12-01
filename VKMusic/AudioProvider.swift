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
import VK_ios_sdk

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
    var currentIndex  = -1
    var nextCount = 0
    var currentSong: Song!
    var coverImage: UIImage!
    var initPlaylist: [Song]!
    var playlist = [Song]()
    static let sharedInstance = AudioProvider()
    var mode = AudioProvider.playerMode.noRepeat
    var shuffled = false
    var last = false
    var number = -1
    var viewPlaylist: Playlist!
    var dataManager = DataManager()
    var request: VKRequest!
    var isBroadcasting = false
    
    func startPlayer(index: Int) {
        last = false
        if self.currentSong != nil {
            DataBaseManager.sharedInstance.addSongToTable(currentSong, table: "history")
        }
        if self.nextCount > 0 {
            self.nextCount--
        }
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
        if self.isBroadcasting {
            startBroadcast()
        }
    }
    
    func saveNext() -> [Song]{
        var next = [Song]()
        if self.nextCount != 0 {
            for var i = self.currentIndex + 1; i <= self.nextCount + self.currentIndex + 1; i++ {
                next.append(AudioProvider.sharedInstance.playlist[i])
            }
        }
        return next
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
            self.loadMore()
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
    
    func loadMore() {
        self.dataManager.songs = self.playlist
        if self.number != 1 && self.number != 6 {
            self.request = self.dataManager.getReqest(self.number, params: [String: AnyObject]())
            if (self.request != nil) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                    self.dataManager.getDataFormVK(self.request, refresh: false, onlyMine: false)
                    self.playlist = self.dataManager.songs
                }
            }
        } else if self.number == 6 && !self.viewPlaylist.isLocal{
            self.request = self.dataManager.getReqest(self.number, params: ["albumId":self.viewPlaylist.id])
            self.playlist = self.dataManager.songs
        } else if self.number == 6 && self.viewPlaylist.isLocal {
            self.dataManager.songs += DataBaseManager.sharedInstance.GetSongsFromDataBase("playlist\(self.viewPlaylist.id)", offset: self.dataManager.songs.count)
            self.playlist = self.dataManager.songs
        } else {
            self.dataManager.songs += DataBaseManager.sharedInstance.GetSongsFromDataBase("downloads", offset: self.dataManager.songs.count)
            self.playlist = self.dataManager.songs
        }
    }
    
    func startBroadcast() {
        let req = VKRequest(method: "audio.setBroadcast", andParameters: ["audio": "\(VKSdk.getAccessToken().userId)_\(self.currentSong.id)", "target_ids": VKSdk.getAccessToken().userId], andHttpMethod: "GET")
        req.executeWithResultBlock(nil, errorBlock: {(response) -> Void in print(response.description)})
    }
    
    func stopBroadcast() {
        let req = VKRequest(method: "audio.setBroadcast", andParameters: ["audio": "", "target_ids": ""], andHttpMethod: "GET")
        req.executeWithResultBlock(nil, errorBlock: nil)
    }

    
}

