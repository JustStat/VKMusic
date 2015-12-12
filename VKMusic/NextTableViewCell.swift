//
//  NextTableViewCell.swift
//  VKMusic
//
//  Created by Kirill Varlamov on 02.12.15.
//  Copyright © 2015 Kirill Varlamov. All rights reserved.
//

import UIKit
import AVFoundation
import SWTableViewCell

//protocol NextTableViewCellDelegate {
//    func deleButtonClick(cell: NextTableViewCell)
//}

class NextTableViewCell: SWTableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    
    @IBOutlet weak var songProgress: UIProgressView!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
//    var delegate: NextTableViewCellDelegate!
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    func UpdateSliderValue() {
        self.songProgress.progress = Float(CMTimeGetSeconds(AudioProvider.sharedInstance.player.currentTime()))/Float(AudioProvider.sharedInstance.currentSong.duration)
        self.songProgress.reloadInputViews()
    }
    
//    @IBAction func deleteButtonClick(Sender: AnyObject) {
//        self.delegate.deleButtonClick()
//    }

}
