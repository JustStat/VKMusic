//
//  DownloadManager.swift
//  VKMusic
//
//  Created by Kirill Varlamov on 03.11.15.
//  Copyright © 2015 Kirill Varlamov. All rights reserved.
//

import UIKit
import Alamofire

protocol DownloadManagerDelegate {
    func updateProgress(progress: Float)
    func removeProgress()
}

class FileDownloadInfo: NSObject {
//    var fileTitle: String!
//    var downloadSource: String!
    var delegate: DownloadManagerDelegate?
    
    var downloadTask: Alamofire.Request?
    var downloadProgress: Float = 0.0{
        didSet {
            self.delegate?.updateProgress(self.downloadProgress)
        }
    }
    var isDownloading = false
    var downloadComplete = false

}

class DownloadManager: NSObject {
    let destination = Alamofire.Request.suggestedDownloadDestination(directory: .DocumentDirectory, domain: .UserDomainMask)
    var downloadSongsList = [Int: FileDownloadInfo]()
    var sessionConfiguration: NSURLSessionConfiguration!
    
    static var sharedInstance = DownloadManager()
    
    func donloadSong(song: Song) {
        self.downloadSongsList[song.id] = FileDownloadInfo()
        DataBaseManager.sharedInstance.addSongToTable(song, table: "downloads")
        self.downloadSongsList[song.id]?.downloadTask = Alamofire.download(.GET, song.url, destination: destination)
            .progress { bytesRead, totalBytesRead, totalBytesExpectedToRead in
                dispatch_async(dispatch_get_main_queue()) {
                    print("Total bytes read on main queue: \(totalBytesRead)")
                    self.downloadSongsList[song.id]?.downloadProgress = Float(totalBytesRead)/Float(totalBytesExpectedToRead)
                }
            }
            .response { request, response, _, error in
                if let error = error {
                    print("Failed with error: \(error)")
                    DataBaseManager.sharedInstance.removeSong("downloads", id: song.id)
                    if self.downloadSongsList[song.id]?.delegate != nil {
                        self.downloadSongsList[song.id]?.delegate!.removeProgress()
                    }
                    self.downloadSongsList.removeValueForKey(song.id)
                } else {
                    print("Downloaded file successfully")
                    if self.downloadSongsList[song.id]?.delegate != nil {
                        self.downloadSongsList[song.id]?.delegate!.removeProgress()
                    }
                    self.downloadSongsList.removeValueForKey(song.id)
                    let URL = self.destination(NSURL(string: "")!, response!)
                    song.localUrl = URL.path
                    DataBaseManager.sharedInstance.setLocalPath(song.id, local: song.localUrl)
                }
        }
        
        
    }
}
