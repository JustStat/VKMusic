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
        db = FMDatabase(path: docFolder + "VKMusicData.db")
    }
    
    func writeDataToDataBase(table: String) {
        if !db.tableExists(table) {
            db.executeUpdate("CREATE TABLE \(table) (id NUMBER NOT NULL, ownerId NUMBER NOT NULL, idvk NUMBER NOT NULL", withArgumentsInArray: <#T##[AnyObject]!#>)
        }
    }

}
