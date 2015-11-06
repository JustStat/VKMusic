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
                    let ownerId = json["items"][i]["owner_id"].intValue
                    let song = Song(title: title, artist: artist, duration: duration, url: url, localUrl: "", id: id, ownerId: ownerId)
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
                    let ownerId = json["items"][i]["owner_id"].intValue
                    let song = Song(title: title, artist: artist, duration: duration, url: url, localUrl: "", id: id, ownerId: ownerId)
                    self.songs.append(song)
                }
            }
        self.isBusy = false
        }, errorBlock: {(error) -> Void in
            self.songs.removeAll()
            self.isBusy = false
        })
        }
    }

}
