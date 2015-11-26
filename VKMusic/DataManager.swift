//
//  DataManager.swift
//  VKMusic
//
//  Created by Kirill Varlamov on 01.11.15.
//  Copyright © 2015 Kirill Varlamov. All rights reserved.
//

import UIKit
import VK_ios_sdk
import SwiftyJSON
import FMDB

class DataManager: NSObject {
    
    enum ErrorType {
        case NoConnection
        case NoContent
    }
    
    //MARK: Properties
    var songs = [Song]()
    var localPlaylists = [Playlist]()
    var vkPlylists = [Playlist]()
    var filteredTableData = [Song]()
    var searhReq = ""
    var isBusy = false
    var error: ErrorType!
    
    //MARK: Songs DataManagment
    
    func getDataFormVK(request: VKRequest, refresh: Bool, onlyMine: Bool) {
        if !isBusy {
        self.isBusy = true
        if refresh {
            self.songs.removeAll()
        }
        request.waitUntilDone = true
        request.executeWithResultBlock({(response) -> Void in
            let json = JSON(response.json)
            print(json.description)
            var count = 0
            if json["count"] == nil {
                count = json.count
                for var i = 0; i < count; i++ {
                    let artist = json[i]["artist"].stringValue
                    let title = json[i]["title"].stringValue
                    let url = json[i]["url"].stringValue
                    let duration = json[i]["duration"].intValue
                    let id = json[i]["id"].intValue
                    let local = DataBaseManager.sharedInstance.getLocalPath(id)
                    let ownerId = json[i]["owner_id"].intValue
                    if onlyMine {
                        if VKSdk.getAccessToken() != nil {
                            if ownerId != Int(VKSdk.getAccessToken().userId) {
                                break
                            }
                        }
                    }
                    let song = Song(title: title, artist: artist, duration: duration, url: url, localUrl: local, id: id, ownerId: ownerId)
                    self.songs.append(song)
                }
            } else {
                count = json["items"].count
                for var i = 0; i < count; i++ {
                    let artist = json["items"][i]["artist"].stringValue
                    let title = json["items"][i]["title"].stringValue
                    let url = json["items"][i]["url"].stringValue
                    let duration = json["items"][i]["duration"].intValue
                    let id = json["items"][i]["id"].intValue
                    let local = DataBaseManager.sharedInstance.getLocalPath(id)
                    let ownerId = json["items"][i]["owner_id"].intValue
                    if onlyMine {
                        if VKSdk.getAccessToken() != nil {
                            print(VKSdk.getAccessToken().userId)
                            if ownerId != Int(VKSdk.getAccessToken().userId) {
                                break
                            }
                        }
                    }
                    let song = Song(title: title, artist: artist, duration: duration, url: url, localUrl: local, id: id, ownerId: ownerId)
                    self.songs.append(song)
                }
            }
            if self.songs.count == 0 {
                self.error = .NoContent
            } else {
                self.error = nil
            }
        }, errorBlock: {(error) -> Void in
            self.songs.removeAll()
            self.error = .NoConnection
        })
        self.isBusy = false
        }
    }
    
    func addSongToVK(song: Song) {
        let req = VKRequest(method: "audio.add", andParameters: [VK_API_OWNER_ID: song.ownerId, "audio_id": song.id], andHttpMethod: "GET")
        req.waitUntilDone = true
        req.executeWithResultBlock({
            (response) -> Void in
            let json = JSON(response.json)
            let newId = json.int
            DataBaseManager.sharedInstance.addSongNewId(song.id, newId: newId!, table: "downloads")
            }, errorBlock: {(error) -> Void in
                print(error.description)
        })

    }
    
    func removeSongFromVK(song: Song) {
        let req = VKRequest(method: "audio.delete", andParameters: ["audio_id": song.id, "owner_id": song.ownerId], andHttpMethod: "GET")
        req.waitUntilDone = true
        req.executeWithResultBlock({(response) -> Void in}, errorBlock: {(error) -> Void in})
    }
    
    func removeSongFromDownloads(song: Song) {
        DataBaseManager.sharedInstance.removeSong("downloads", id: song.id)
        do { try NSFileManager.defaultManager().removeItemAtPath(song.localUrl)} catch{print("Error")}
    }
    
    func getReqest(index: Int, params: [String: AnyObject]) -> VKRequest {
        switch index {
        case 0:
            if VKSdk.getAccessToken() != nil {
                return VKRequest(method: "audio.get", andParameters: [VK_API_USER_ID: VKSdk.getAccessToken().userId, VK_API_OFFSET: self.songs.count, "count": 50], andHttpMethod: "GET")
            }
        case 2:
            return VKRequest(method: "audio.getPopular", andParameters:[VK_API_OFFSET: self.songs.count, "count": 50], andHttpMethod: "GET")
        case 3:
            return VKRequest(method: "audio.getRecommendations", andParameters: [VK_API_OFFSET: self.songs.count, "count": 50], andHttpMethod: "GET")
        case 6:
            return VKRequest(method: "audio.get", andParameters: [VK_API_USER_ID: VKSdk.getAccessToken().userId,VK_API_ALBUM_ID: Int(params["albumId"] as! NSNumber), VK_API_OFFSET: self.songs.count, "count": 50], andHttpMethod: "GET")
        default:
            print("Whoops")
        }
        return VKRequest()
    }
    
    func getSearchRequest(index: Int, query: String) -> VKRequest {
        switch index {
        case 0:
            if VKSdk.getAccessToken() != nil {
                return VKRequest(method: "audio.search", andParameters: [VK_API_Q: query, VK_API_OFFSET: self.songs.count, "auto_complete": "1", "search_own": "1", "count": 50], andHttpMethod: "GET")
            }
        case 2:
            return VKRequest(method: "audio.search", andParameters: [VK_API_Q: query, VK_API_OFFSET: self.songs.count, "auto_complete": "1", "count": 50], andHttpMethod: "GET")
        default:
            print("Whoops")
        }
        return VKRequest()
    }
    
    func addSongToVKPlaylist(song: Song, albumId: Int) {
        let req = VKRequest(method: "audio.moveToAlbum", andParameters: [VK_API_ALBUM_ID: "\(albumId)", "audio_ids": [song.id]], andHttpMethod: "GET")
        req.executeWithResultBlock({(response) -> Void in}, errorBlock: {(error) -> Void in})
        
    }
    
    //Songs Managment ENDS
    
    //MARK: Playlists DataManagment
    
    func getPlaylistsFromVK() {
        if VKSdk.getAccessToken() != nil {
            let req = VKRequest(method: "audio.getAlbums", andParameters: [VK_API_OWNER_ID: VKSdk.getAccessToken().userId], andHttpMethod: "GET")
            req.waitUntilDone = true
            req.executeWithResultBlock({(response) -> Void in
                let json = JSON(response.json)
                print(json.description)
                let count = json["items"].count
                for var i = 0; i < count; i++ {
                    let title = json["items"][i]["title"].stringValue
                    let id = json["items"][i]["id"].intValue
                    let owner_id = json["items"][i]["owner_id"].intValue
                    self.vkPlylists.append(Playlist(name: title, owner: owner_id, id: id, isLocal: false))
                }
                if self.vkPlylists.count == 0 {
                    self.error = .NoContent
                } else {
                    self.error = nil
                }
            }, errorBlock: {(error) -> Void in
                self.vkPlylists.removeAll()
                self.error = .NoConnection
            })


        }
    }
    
    func getPlaylistsFromDataBase() {
        DataBaseManager.sharedInstance.GetPlaylistsFormDataBase()
    }
    
    func addPlaylistToVK(name: String) -> Int {
        var album_id: Int!
        if VKSdk.getAccessToken() != nil {
            let req = VKRequest(method: "audio.addAlbum", andParameters: ["title": name], andHttpMethod: "GET")
            req.waitUntilDone = true
            req.executeWithResultBlock({(response) -> Void in
                let json = JSON(response.json)
                print(json.description)
                album_id = Int(json["albumId"].intValue)
            }, errorBlock: {(error) -> Void in
                album_id = -1
            })
        }
        return album_id
    }
    
    func downloadPlaylist(playlist: Playlist) {
        DataBaseManager.sharedInstance.RemovePlaylistFromDataBase(playlist)
        addPlaylistToDataBase(playlist)
        let req = VKRequest(method: "audio.get", andParameters: [VK_API_USER_ID: VKSdk.getAccessToken().userId,VK_API_ALBUM_ID: playlist.id, VK_API_OFFSET: self.songs.count], andHttpMethod: "GET")
        self.getDataFormVK(req, refresh: false, onlyMine: false)
        let playlistSongs = self.songs
        for song in playlistSongs {
            if song.localUrl == "" {
                DownloadManager.sharedInstance.donloadSong(song, playlistId: playlist.id)
            } else {
                DataBaseManager.sharedInstance.addSongToTable(song, table: "playlist\(playlist.id)")
            }
        }
    }
    
    func checkPlaylistDownload(playlist: Playlist) -> Bool {
        let req = VKRequest(method: "audio.get", andParameters: [VK_API_USER_ID: VKSdk.getAccessToken().userId,VK_API_ALBUM_ID: playlist.id, VK_API_OFFSET: self.songs.count], andHttpMethod: "GET")
        req.waitUntilDone = true
        self.getDataFormVK(req, refresh: false, onlyMine: false)
        let playlistSongs = self.songs
        for song in playlistSongs {
            if song.localUrl == "" {
                return false
            }
        }
        return true
    }
    
    func addPlaylistToDataBase(playlist: Playlist) -> Int{
       return DataBaseManager.sharedInstance.AddPlaylistToDataBase(playlist)
    }
    
    func removePlaylist(playlist: Playlist) {
        if playlist.isLocal {
            DataBaseManager.sharedInstance.RemovePlaylistFromDataBase(playlist)
        } else {
            let req = VKRequest(method: "audio.deleteAlbum", andParameters: [VK_API_ALBUM_ID: playlist.id], andHttpMethod: "GET")
            req.executeWithResultBlock(nil, errorBlock: nil)
        }
    }
    
    //Playlists Managment ENDS


}
