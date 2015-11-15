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
    
    static let sharedInstance = DataBaseManager()
    
    let db: FMDatabase!
    let docFolder = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0]
    
    override init() {
        db = FMDatabase(path: docFolder + "/VKMusicData.sqlite")
    }
    
    func GetSongsFromDataBase(table: String, offset: Int) -> [Song] {
        var songs = [Song]()
        if db != nil {
            db.open()
            print(self.docFolder)
            if db.tableExists(table) {
                let req = db.executeQuery("SELECT * FROM \(table) WHERE id >= \(offset) ORDER BY id LIMIT 50", withArgumentsInArray: [])
                if req != nil {
                    while req.next() {
                        songs.append(Song(title: req.stringForColumn("title"), artist: req.stringForColumn("artist"), duration: Int(req.intForColumn("duration")), url: req.stringForColumn("url"), localUrl: req.stringForColumn("local"), id: Int(req.intForColumn("ovkid")), ownerId: Int(req.intForColumn("ownerId"))))
                    }
                }
            } else {
            songs = []
            }
        }
        db.close()
        return songs
    }
    
    func addSongToTable(song: Song, table: String) {
        if db != nil {
            db.open()
            print(self.docFolder)
            if !db.tableExists(table) {
                db.executeUpdate("CREATE TABLE \(table)(id NUMBER NOT NULL, ovkid NUMBER NOT NULL, vkid NUMBER NOT NULL, ownerId NUMBER NOT NULL, title TEXT, artist TEXT, url TEXT NOT NULL, local TEXT NOT NULL, duration NUMBER NOT NULL, upTitle TEXT, upArtist TEXT)", withArgumentsInArray: [])
            }
            db.executeUpdate("UPDATE \(table) SET id = id + 1", withArgumentsInArray: [])
            db.executeUpdate("INSERT INTO \(table) VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", withArgumentsInArray: [0, song.id, -1, song.ownerId, song.title, song.artist, song.url, song.localUrl, song.duration, song.title.uppercaseString, song.artist.uppercaseString])
            
        }
        db.close()
    }
    
    func checkExistance(table: String, id: Int) -> Bool {
        if db != nil {
            db.open()
            if db.tableExists("downloads") {
                let rs = db.executeQuery("SELECT * FROM \(table) WHERE vkid = ? OR ovkid = ?", withArgumentsInArray: [id, id])
                if rs.next() {
                    return true
                }
            }
        }
        return false
    }
    
    func addSongNewId(id: Int, newId: Int, table: String) {
        if db != nil {
            db.open()
            if db.tableExists("downloads") {
                _ = db.executeUpdate("UPDATE \(table) SET vkid = ? WHERE ovkid = ?", withArgumentsInArray: [newId, id])
            }
        }

    }
    
    func removeSong(table: String, id: Int) {
        if db != nil {
            db.open()
            if db.tableExists(table) {
                    _ = db.executeUpdate("UPDATE \(table) SET id = id - 1 WHERE id > (SELECT id FROM \(table) WHERE vkid = ? OR ovkid = ?)", withArgumentsInArray: [id, id])
                    _ = db.executeUpdate("DELETE FROM \(table) WHERE vkid = ? OR ovkid = ?", withArgumentsInArray: [id, id])
            }
        }

    }
    
    func getLocalPath(id: Int) -> String {
        if db != nil {
            db.open()
            if db.tableExists("downloads") {
                let rs = db.executeQuery("SELECT local FROM downloads WHERE vkid = ? OR ovkid = ?", withArgumentsInArray: [id, id])
                if rs != nil && rs.next() {
                    return rs.stringForColumn("local")
                }
            }
        }
        return ""
    }
    
    func setLocalPath(id: Int, local: String) {
        if db != nil {
            db.open()
            if db.tableExists("downloads") {
                db.executeUpdate("UPDATE downloads SET local = ? WHERE vkid = ? OR ovkid = ?", withArgumentsInArray: [local, id, id])
            }
        }

    }
    
    func downloadsSearchReqest(req :String) -> [Song] {
        var songs: [Song] = []
        if req != "" {
            let divReq = req.characters.split{$0 == " "}.map(String.init)
            var request = "SELECT * FROM downloads WHERE"
            request += " ((upTitle LIKE '%\(divReq[0].uppercaseString)%') or (upArtist LIKE '%\(divReq[0].uppercaseString)%'))"
            for var i = 1; i < divReq.count; ++i {
                request += " and ((upTitle LIKE '%\(divReq[i].uppercaseString)%') or (upArtist LIKE '%\(divReq[i].uppercaseString)%'))"
            }
            if db != nil {
                db.open()
                if db.tableExists("downloads") {
                    let req = db.executeQuery(request, withArgumentsInArray: [])
                    if req != nil {
                        while req.next() {
                            songs.append(Song(title: req.stringForColumn("title"), artist: req.stringForColumn("artist"), duration: Int(req.intForColumn("duration")), url: req.stringForColumn("url"), localUrl: req.stringForColumn("local"), id: Int(req.intForColumn("ovkid")), ownerId: Int(req.intForColumn("ownerId"))))
                        }
                    }
                }
            }
        }
        return songs
    }
    

}
