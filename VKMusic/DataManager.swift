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
    var filteredTableData = [Song]()
    var searhReq = ""
    var isBusy = false
    var error: ErrorType!
    
    
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
                if count == 0 {
                    self.error == .NoContent
                }
                for var i = 0; i < count; i++ {
                    let artist = json[i]["artist"].stringValue
                    let title = json[i]["title"].stringValue
                    let url = json[i]["url"].stringValue
                    let duration = json[i]["duration"].intValue
                    let id = json[i]["id"].intValue
                    let local = DataBaseManager.sharedInstance.getLocalPath(id)
                    let ownerId = json["items"][i]["owner_id"].intValue
                    if onlyMine {
                        if VKSdk.getAccessToken() != nil {
                            if ownerId != Int(VKSdk.getAccessToken().userId) {
                                break
                            }
                        }
                    }
                    let song = Song(title: title, artist: artist, duration: duration, url: url, localUrl: local, id: id, ownerId: ownerId)
                    self.songs.append(song)
                    self.error = nil
                }
            } else {
                count = json["items"].count
                if count == 0 {
                    self.error == .NoContent
                }
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
                    self.error = nil
                }
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
            }, errorBlock: {(error) -> Void in})

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
    
    func getReqest(index: Int) -> VKRequest {
        switch index {
        case 0:
            if VKSdk.getAccessToken() != nil {
                return VKRequest(method: "audio.get", andParameters: [VK_API_USER_ID: VKSdk.getAccessToken().userId, VK_API_OFFSET: self.songs.count, "count": 50], andHttpMethod: "GET")
            }
        case 2:
            return VKRequest(method: "audio.getPopular", andParameters:[VK_API_OFFSET: self.songs.count, "count": 50], andHttpMethod: "GET")
        case 3:
            return VKRequest(method: "audio.getRecommendations", andParameters: [VK_API_OFFSET: self.songs.count, "count": 50], andHttpMethod: "GET")
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


}
