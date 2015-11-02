//
//  SQLGenerator.swift
//  VKMusic
//
//  Created by Kirill Varlamov on 01.11.15.
//  Copyright © 2015 Kirill Varlamov. All rights reserved.
//

import UIKit
import FMDB

class DataBaseManager: NSObject {
    
    let db: FMDatabase!
    
    override init() {
        let docFolder = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0]
        db = FMDatabase(path: docFolder + "VKMusicData.sqlite")
    }
    
    func GetSongsFromDataBase(table: String) -> [Song] {
        var songs = [Song]()
        if db.tableExists("downloads") {
            let req = db.executeQuery("SELECT * FROM \(table)", withArgumentsInArray: [])
            if req != nil && req.next() {
                while req.next() {
                    songs.append(Song(title: req.stringForColumn("title"), artist: req.stringForColumn("artist"), duration: Int(req.intForColumn("duration")), url: req.stringForColumn("url"), localUrl: req.stringForColumn("local"), id: Int(req.intForColumn("id")), ownerId: Int(req.intForColumn("ownerId"))))
                }
            }
        } else {
            songs = []
        }
        return songs
    }
    
    func addSongToTable(song: Song, table: String) {
        if !db.tableExists(table) {
            db.executeUpdate("CREATE TABLE \(table)(id NUMBER NOT NULL, ownerId NUMBER NOT NULL, title TEXT, artist TEXT, url TEXT NOT NULL, local TEXT NOT NULL, duration NUMBER NOT NULL)", withArgumentsInArray: [])
        } else {
            db.executeQuery("INSERT INTO \(table) VALUES(?, ?, ?, ?, ?, ?, ?)", withArgumentsInArray: [song.id, song.ownerId, song.title, song.artist, song.url, song.localUrl, song.duration])
        }
    }
    
    

}
