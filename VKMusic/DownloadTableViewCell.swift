//
//  DownloadTableViewCell.swift
//  VKMusic
//
//  Created by Kirill Varlamov on 12.11.15.
//  Copyright © 2015 Kirill Varlamov. All rights reserved.
//

import UIKit
import LLACircularProgressView

protocol DownloadTableViewCellDelegate {
    func reloadTable()
    func stopDownloadTask(cell: DownloadTableViewCell)
}

class DownloadTableViewCell: UITableViewCell, DownloadManagerDelegate {

    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var downloadControllerView: UIView!
    
    var delegate: DownloadTableViewCellDelegate!
    var progressView: LLACircularProgressView!
    
    func updateProgress(progress: Float) {
        print(progress)
        progressView.backgroundColor = self.backgroundColor
        progressView.tintColor = UIColor(red:0.14, green:0.43, blue:0.69, alpha:1.0)
        progressView.setProgress(progress, animated: true)
    }
    
    func removeProgress() {
        self.delegate.reloadTable()
    }
    
    func cancelTask() {
        self.delegate.stopDownloadTask(self)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.progressView = LLACircularProgressView(frame: self.downloadControllerView.frame)
        self.progressView.progress = 0
        let FingerTap = UITapGestureRecognizer(target: self, action: Selector("cancelTask"))
        self.progressView.addGestureRecognizer(FingerTap)
        self.addSubview(self.progressView)
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
