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
    
    //MARK: Properties
    var songs = [Song]()
    var filteredTableData = [Song]()
    var searhReq = ""
    var isBusy = false
    
    
    func getDataFormVK(request: VKRequest, refresh: Bool) {
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
                    let ownerId = json["items"][i]["owner_id"].intValue
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
                    let song = Song(title: title, artist: artist, duration: duration, url: url, localUrl: local, id: id, ownerId: ownerId)
                    self.songs.append(song)
                }
            }
        }, errorBlock: {(error) -> Void in
            self.songs.removeAll()
        })
        self.isBusy = false
        }
    }
    
    func addSongToVK(index: Int) {
        let req = VKRequest(method: "audio.add", andParameters: [VK_API_OWNER_ID: self.songs[index].ownerId, "audio_id": self.songs[index].id], andHttpMethod: "GET")
        req.executeWithResultBlock({
            (response) -> Void in
            let json = JSON(response.json)
            let newId = json.int
            DataBaseManager.sharedInstance.addSongNewId(self.songs[index].id, newId: newId!, table: "downloads")
            }, errorBlock: {(error) -> Void in})

    }
    
    func removeSongFromVK(index: Int) {
        let req = VKRequest(method: "audio.delete", andParameters: ["audio_id": self.songs[index].id, "owner_id": self.songs[index].ownerId], andHttpMethod: "GET")
        req.executeWithResultBlock({(response) -> Void in}, errorBlock: {(error) -> Void in})
    }
    
    func removeSongFromDownloads(index: Int) {
        DataBaseManager.sharedInstance.removeSong("downloads", id: self.songs[index].id)
        do { try NSFileManager.defaultManager().removeItemAtPath(self.songs[index].localUrl)} catch{print("Error")}
    }

}
