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
    func finishLoadingSong()
    func loadMore()
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
    var searchText: String!
    var scopeIndex: Int!
    
    func startPlayer(index: Int) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            self.last = false
            self.coverImage = UIImage(named: "DefCover")
            if self.currentSong != nil {
                DataBaseManager.sharedInstance.addSongToTable(self.currentSong, table: "history")
            }
            var csong = AVPlayerItem!()
            if self.playlist[index].localUrl != "" {
                csong = AVPlayerItem(URL: NSURL(fileURLWithPath: self.playlist[index].localUrl))
            } else {
                csong = AVPlayerItem(URL: NSURL(string: self.playlist[index].url)!)
            }
            let metadata = csong.asset.commonMetadata
            for item in metadata {
                if item.commonKey  == "artwork" {
                    self.coverImage = UIImage(data: item.value as! NSData)
                }
            
            }
            self.player = AVPlayer(playerItem: csong)
            try! AVAudioSession.sharedInstance().setActive(true)
            try! AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "playerDidFinishPlaying:", name: AVPlayerItemDidPlayToEndTimeNotification, object: csong)
            self.player.play()
            UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
            self.currentSong = self.playlist[index]
            self.currentIndex = index
            self.currentSong.isPlaying = true
            if self.isBroadcasting {
                self.startBroadcast()
            }
            dispatch_async(dispatch_get_main_queue()) {
                if self.coverImage == nil {
                    self.coverImage = UIImage(named: "DefCover")
                }
                let mediaImage = MPMediaItemArtwork(image: self.coverImage)
                let mediaInfo: [String: AnyObject] = [MPMediaItemPropertyArtist : self.currentSong.artist, MPMediaItemPropertyTitle : self.currentSong.title, MPMediaItemPropertyPlaybackDuration: self.currentSong.duration, MPMediaItemPropertyArtwork: mediaImage]
                MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = mediaInfo
                self.delegate?.finishLoadingSong()
            }
        }
    }
    
    func saveNext() -> [Song]{
        var next = [Song]()
        if self.nextCount != 0 {
            for var i = self.currentIndex + 1; i <= self.nextCount + self.currentIndex; i++ {
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
        } else {
            self.forward()
            self.delegate?.playerDidFinishPlaying(note)
        }
        if self.nextCount > 0 {
            self.nextCount--
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
            self.delegate?.finishLoadingSong()
        }
        if playlist.count >= 50 && playlist.count - currentIndex == 2 {
            self.loadMore()
        }
        if self.nextCount > 0 {
            self.nextCount--
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
    
    func loadMore() {
        self.dataManager.songs = self.playlist
        if self.number != 1 && self.number != 6 && self.number != 8 && self.number != 7{
            self.request = self.dataManager.getReqest(self.number, params: [String: AnyObject]())
            if (self.request != nil) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                    self.dataManager.getDataFormVK(self.request, refresh: false, onlyMine: false)
                    self.playlist = self.dataManager.songs
                }
            }
        } else if self.number == 6 && !self.viewPlaylist.isLocal{
            self.request = self.dataManager.getReqest(self.number, params: ["albumId":self.viewPlaylist.id])
            if (self.request != nil) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                    self.dataManager.getDataFormVK(self.request, refresh: false, onlyMine: false)
                    self.playlist = self.dataManager.songs
                }
            }
        } else if self.number == 6 && self.viewPlaylist.isLocal {
            self.dataManager.songs += DataBaseManager.sharedInstance.GetSongsFromDataBase("playlist\(self.viewPlaylist.id)", offset: self.dataManager.songs.count)
            self.playlist = self.dataManager.songs
        } else if self.number == 8 {
            self.request = self.dataManager.getSearchRequest(scopeIndex, query: searchText)
            if (self.request != nil) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                    var onlyMine = false
                    switch self.scopeIndex {
                    case 0:
                        onlyMine = true
                    default:
                        onlyMine = false
                    }
                    self.dataManager.getDataFormVK(self.request, refresh: false, onlyMine: onlyMine)
                    self.playlist = self.dataManager.songs
                }
            }
        } else if self.number == 1{
            self.dataManager.songs += DataBaseManager.sharedInstance.GetSongsFromDataBase("downloads", offset: self.dataManager.songs.count)
            self.playlist = self.dataManager.songs
        } else if self.number == 7 {
            self.request = self.dataManager.getReqest(self.number, params: ["friendId":self.viewPlaylist.id])
            if (self.request != nil) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                    self.dataManager.getDataFormVK(self.request, refresh: false, onlyMine: false)
                    self.playlist = self.dataManager.songs
                }
            }
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

