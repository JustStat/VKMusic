//
//  Playlist.swift
//  VKMusic
//
//  Created by Kirill Varlamov on 24.11.15.
//  Copyright © 2015 Kirill Varlamov. All rights reserved.
//

import UIKit

class Playlist: NSObject {
    var name: String!
    var owner: Int!
    var id: Int!
    var isLocal = false
    var isDownloaded = false
    var songsCount = 0
    var image: UIImage?
    
    init(name: String, owner: Int, id: Int, isLocal: Bool) {
        self.name = name
        self.owner = owner
        self.id = id
        self.isLocal = isLocal
    }

}
    