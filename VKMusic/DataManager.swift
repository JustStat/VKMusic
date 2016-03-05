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
                    let lyricsId = json[i]["lyrics_id"].intValue
                    if onlyMine {
                        if VKSdk.getAccessToken() != nil {
                            if ownerId != Int(VKSdk.getAccessToken().userId) {
                                break
                            }
                        }
                    }
                    let song = Song(title: title, artist: artist, duration: duration, url: url, localUrl: local, id: id, ownerId: ownerId, lyricsId: lyricsId)
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
                    let lyricsId = json["items"][i]["lyrics_id"].intValue
                    if onlyMine {
                        if VKSdk.getAccessToken() != nil {
                            print(VKSdk.getAccessToken().userId)
                            if ownerId != Int(VKSdk.getAccessToken().userId) {
                                break
                            }
                        }
                    }
                    let song = Song(title: title, artist: artist, duration: duration, url: url, localUrl: local, id: id, ownerId: ownerId, lyricsId: lyricsId)
                    self.songs.append(song)
                }
            }
            if self.songs.count == 0 {
                self.error = .NoContent
            } else {
                self.error = nil
            }
        }, errorBlock: {(error) -> Void in
            print(error.description)
            self.songs.removeAll()
            self.error = .NoConnection
        })
        self.isBusy = false
        }
    }
    
    func addSongToVK(song: Song) -> (Bool, Int) {
        var error = false
        var newId = -1
        let req = VKRequest(method: "audio.add", andParameters: [VK_API_OWNER_ID: song.ownerId, "audio_id": song.id], andHttpMethod: "GET")
        req.waitUntilDone = true
        req.executeWithResultBlock({
            (response) -> Void in
            let json = JSON(response.json)
            newId = json.int!
            DataBaseManager.sharedInstance.addSongNewId(song.id, newId: newId, table: "downloads")
            DataBaseManager.sharedInstance.addSongNewOwner(song.id, owner: Int(VKSdk.getAccessToken().userId)!, table: "downloads")
            }, errorBlock: {(e) -> Void in
                print(e.description)
                error = true
        })
        return (error, newId)
    }
    
    func removeSongFromVK(song: Song) -> Bool {
        var error = false
        let req = VKRequest(method: "audio.delete", andParameters: ["audio_id": song.id, "owner_id": song.ownerId], andHttpMethod: "GET")
        req.waitUntilDone = true
        req.executeWithResultBlock({(response) -> Void in
            DataBaseManager.sharedInstance.addSongNewOwner(song.id, owner: -1, table: "downloads")
            }, errorBlock: {(e) -> Void in
            print(e.description)
            error = true})
        return error
    }
    
    func removeSongFromDownloads(song: Song) -> Bool{
        var errorCheck = false
        DataBaseManager.sharedInstance.removeSong("downloads", id: song.id)
        do { try NSFileManager.defaultManager().removeItemAtPath(song.localUrl)}
        catch{
            print("Error")
            errorCheck = true
        }
        return errorCheck
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
            if params["albumId"] != nil {
                print(params["albumId"])
                return VKRequest(method: "audio.get", andParameters: [VK_API_USER_ID: VKSdk.getAccessToken().userId,VK_API_ALBUM_ID: Int(params["albumId"] as! NSNumber), VK_API_OFFSET: self.songs.count, "count": 50], andHttpMethod: "GET")
            }
        case 7:
            if params["friendId"] != nil {
                return VKRequest(method: "audio.get", andParameters: [VK_API_USER_ID: Int(params["friendId"] as! NSNumber), VK_API_OFFSET: self.songs.count, "count": 50], andHttpMethod: "GET")
            }
        case 8:
            if params["song"] != nil {
                let song = params["song"] as! Song
                return VKRequest(method: "audio.getRecommendations", andParameters: ["target_audio": "\(song.ownerId)_\(song.id)",VK_API_OFFSET: self.songs.count, "count": 50], andHttpMethod: "GET")
            }

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
    
    func addSongToVKPlaylist(songId: Int, albumId: Int) -> Bool {
        var error = false
        let req = VKRequest(method: "audio.moveToAlbum", andParameters: [VK_API_ALBUM_ID: "\(albumId)", "audio_ids": [songId]], andHttpMethod: "GET")
        req.waitUntilDone = true
        req.executeWithResultBlock({(response) -> Void in print("Succes")}, errorBlock: {(e) -> Void in
            print(error.description)
            error = true
        })
        return error
    }
    
    func checkSongExistanceInPlaylist(playlist: Playlist) -> [Int: Bool] {
        var checkList = [Int: Bool]()
        if VKSdk.getAccessToken() != nil {
            var songIds = [Int]()
            for song in self.songs {
                songIds.append(song.id)
            }
            let req = VKRequest(method: "audio.get", andParameters: ["owner_id": VKSdk.getAccessToken().userId, "album_id": playlist.id, "audio_ids": songIds], andHttpMethod: "GET")
            req.waitUntilDone = true
            req.executeWithResultBlock({(response) -> Void in
                let json = JSON(response.json)
                print(json.description)
                for var i = 0; i < json["items"].count; i++ {
                    let id = json["items"][i]["id"].intValue
                    checkList[id] = true
                }
            }, errorBlock: nil)
        }
       return checkList
    }
    
    func removeSongFromVKPlaylist(song: Song, playlist: Playlist) -> Bool {
        var error = false
        var songIds = [Int]()
        let deleteReq = VKRequest(method: "audio.deleteAlbum", andParameters: ["album_id": playlist.id], andHttpMethod: "GET")
        deleteReq.waitUntilDone = true
        deleteReq.executeWithResultBlock(nil, errorBlock: {(response) -> Void in error = true})
        if !error {
            playlist.id = self.addPlaylistToVK(playlist.name)
            for asong in self.songs {
                if asong.id != song.id {
                    songIds.append(asong.id)
                }
            }
        }
        if !error {
            let moveReq = VKRequest(method: "audio.moveToAlbum", andParameters: ["album_id": playlist.id, "audio_ids": songIds.reverse()], andHttpMethod: "GET")
            moveReq.executeWithResultBlock(nil, errorBlock: {(response) -> Void in error = true})
        }
        return error
    }
    
    //Songs Managment ENDS
    
    //MARK: Playlists DataManagment
    
    func getPlaylistsFromVK(isFriends: Bool) {
        if VKSdk.getAccessToken() != nil {
            self.vkPlylists.removeAll()
            let req: VKRequest!
            if !isFriends {
                req = VKRequest(method: "audio.getAlbums", andParameters: [VK_API_OWNER_ID: VKSdk.getAccessToken().userId], andHttpMethod: "GET")
            } else {
                req = VKRequest(method: "friends.get", andParameters: ["order": "hints", "count": 50, "offset": self.vkPlylists.count, "fields": ["nickname", "photo_100"]], andHttpMethod: "GET")
            }
            req.waitUntilDone = true
            req.executeWithResultBlock({(response) -> Void in
                let json = JSON(response.json)
                print(json.description)
                let count = json["items"].count
                for var i = 0; i < count; i++ {
                    var title = ""
                    var owner_id = -1
                    var id = -1
                    var imageURL: String?
                    if !isFriends {
                        title = json["items"][i]["title"].stringValue
                        id = json["items"][i]["id"].intValue
                        owner_id = json["items"][i]["owner_id"].intValue
                    } else {
                        title = json["items"][i]["first_name"].stringValue
                        title += " \(json["items"][i]["last_name"].stringValue)"
                        id = json["items"][i]["id"].intValue
                        owner_id = Int(VKSdk.getAccessToken().userId)!
                        imageURL = json["items"][i]["photo_100"].stringValue
                    }
                    if !isFriends {
                        self.vkPlylists.append(Playlist(name: title, owner: owner_id, id: id, isLocal: false))
                    } else {
                        self.vkPlylists.append(Playlist(name: title, owner: owner_id, id: id, isLocal: false))
                        self.vkPlylists[self.vkPlylists.count - 1].imageURL = imageURL
                    }
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
                album_id = Int(json["album_id"].intValue)
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
    
    func removePlaylist(playlist: Playlist) -> Bool{
        var error = false
        if playlist.isLocal {
            DataBaseManager.sharedInstance.RemovePlaylistFromDataBase(playlist)
        } else {
            let req = VKRequest(method: "audio.deleteAlbum", andParameters: [VK_API_ALBUM_ID: playlist.id], andHttpMethod: "GET")
            req.waitUntilDone = true
            req.executeWithResultBlock({(response) -> Void in}, errorBlock: {(e) -> Void in error = true})
        }
        return error
    }
    
    //Playlists Managment ENDS


}
