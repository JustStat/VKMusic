//
//  SongTableViewCell.swift
//  VKMusic
//
//  Created by Kirill Varlamov on 09.09.15.
//  Copyright (c) 2015 Kirill Varlamov. All rights reserved.
//

import UIKit

protocol SongTableViewCellDelegate {
    func createCellAlertController(cell: SongTableViewCell)
}

class SongTableViewCell: UITableViewCell {
    
    var delegate: SongTableViewCellDelegate?
    
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var MoreButton: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var downloadedMark:
        UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
       
    }
   
    @IBAction func MoreButtonTouchDown(sender: AnyObject) {
        delegate?.createCellAlertController(self)
    }
    

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
