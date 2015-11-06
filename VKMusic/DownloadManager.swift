//
//  DownloadManager.swift
//  VKMusic
//
//  Created by Kirill Varlamov on 03.11.15.
//  Copyright © 2015 Kirill Varlamov. All rights reserved.
//

import UIKit

class FileDownloadInfo: NSObject {
//    var fileTitle: String!
//    var downloadSource: String!
    var downloadTask: NSURLSessionDownloadTask!
    var taskResumeData: NSData!
    var downloadProgress = 0.0
    var isDownloading = false
    var downloadComplete = false
    var taskId = -1
    var cellIndex: Int!

}

class DownloadManager: NSObject {
    
    var session: NSURLSession!
    var arrFileDownloadData: NSMutableArray!
    var docDirectoryURL: NSURL!
    var downloadSongsList = [Song]()
    
    var sessionConfiguration: NSURLSessionConfiguration!
    
    init(title: String, delegate: MusicTableViewController) {
        self.docDirectoryURL = NSFileManager.defaultManager().URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains:NSSearchPathDomainMask.UserDomainMask)[0]
        let sessionConfig = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier("com.JInc.VKMusic: \(title)")
        sessionConfig.HTTPMaximumConnectionsPerHost = 10
        self.session = NSURLSession(configuration: sessionConfig, delegate: delegate, delegateQueue: nil)

    }
}
