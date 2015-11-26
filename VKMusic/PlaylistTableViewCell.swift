//
//  PlaylistTableViewCell.swift
//  VKMusic
//
//  Created by Kirill Varlamov on 19.11.15.
//  Copyright © 2015 Kirill Varlamov. All rights reserved.
//

import UIKit

protocol PlaylistTableViewCellDelegate {
    func createPlaylistAlertController(playlist: Playlist)
}

class PlaylistTableViewCell: UITableViewCell {
    
    @IBOutlet weak var playlistTitleLabel: UILabel!
    @IBOutlet weak var moreButton: UIButton!
    @IBAction func MoreButtonClick(sender: AnyObject) {
        self.delegate.createPlaylistAlertController(self.playlist)
    }
    var playlist: Playlist!
    var delegate: PlaylistTableViewCellDelegate!

}
