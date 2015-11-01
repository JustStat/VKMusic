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
    //    static var sharedInstance = DataManager()
    
    func getDataFormVK(method: String, params: [NSObject: AnyObject]) {
        let request = VKRequest(method: method, andParameters: params, andHttpMethod: "Get")
        request.waitUntilDone = true
        request.executeWithResultBlock({(response) -> Void in
            let json = JSON(response.json)
            let count = json["items"].count
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
            }, errorBlock: {(error) -> Void in
                print(error.description)
        })
    }

}
