//
//  SongTableViewCell.swift
//  VKMusic
//
//  Created by Kirill Varlamov on 09.09.15.
//  Copyright (c) 2015 Kirill Varlamov. All rights reserved.
//

import UIKit

protocol SongTableViewCellDelegate {
    func createAlertController(cell: SongTableViewCell)
}

class SongTableViewCell: UITableViewCell {
    
    var delegate: SongTableViewCellDelegate?
    
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var MoreButton: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    var progressBar: UIProgressView!
    override func awakeFromNib() {
        super.awakeFromNib()
       // downloadProgress.hidden = true
    }
   
    @IBAction func MoreButtonTouchDown(sender: AnyObject) {
        delegate?.createAlertController(self)
    }
    

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
