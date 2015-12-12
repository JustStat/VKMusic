//
//  AddSongToPlaylistTableViewCell.swift
//  VKMusic
//
//  Created by Kirill Varlamov on 24.11.15.
//  Copyright © 2015 Kirill Varlamov. All rights reserved.
//

import UIKit

protocol AddSongToPlaylistTableViewCellDelegate {
    func addSongToVKPlaylist(cell: AddSongToPlaylistTableViewCell)
}

class AddSongToPlaylistTableViewCell: UITableViewCell {
    
    var delegate: AddSongToPlaylistTableViewCellDelegate!

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var AddSongToPlaylistButton: UIButton!
    @IBAction func AddSongToPlaylistButtonClick(sender: AnyObject) {
        self.AddSongToPlaylistButton.setImage(UIImage(named: "CheckedFilled"), forState: .Normal)
        self.delegate.addSongToVKPlaylist(self)
    }
    
    var inList = false
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func prepareForReuse() {
        self.AddSongToPlaylistButton.imageView?.image = UIImage(named: "Add")
        self.AddSongToPlaylistButton.userInteractionEnabled = true
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setCheckImage(exists: Bool) {
        if exists {
            self.AddSongToPlaylistButton.imageView?.image = UIImage(named: "CheckedFilled")
            self.AddSongToPlaylistButton.userInteractionEnabled = false
        }

    }

}
