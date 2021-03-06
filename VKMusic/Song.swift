//
//  Song.swift
//  VKMusic
//
//  Created by Kirill Varlamov on 01.11.15.
//  Copyright © 2015 Kirill Varlamov. All rights reserved.
//

import UIKit

class Song: NSObject {
    var title: String!
    var artist: String!
    var duration: Int!
    var url: String!
    var localUrl: String!
    var id: Int!
    var ownerId: Int!
    var lyricsId: Int!
    var isPlaying = false
    var inPlaylst = false
    var downloadId: Int
    var canPlay = true
    
    init(title: String, artist: String, duration: Int, url: String, localUrl: String, id: Int, ownerId: Int, lyricsId: Int) {
        self.title = title
        self.artist = artist
        self.duration = duration
        self.url = url
        self.localUrl = localUrl
        self.id = id
        self.ownerId = ownerId
        self.lyricsId = lyricsId
        self.isPlaying = false
        self.downloadId = -1
    }
    
    func durationToString() -> String {
        return String(format: "%02d:%02d", arguments: [duration / 60, duration % 60])
    }
    
}
