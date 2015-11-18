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
        progressView.backgroundColor = UIColor.clearColor()
        progressView.tintColor = GlobalConstants.colors.VKBlue
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
        self.progressView = LLACircularProgressView(frame: CGRectMake(0, 0, 35, 35))
        self.progressView.progress = 0
        let FingerTap = UITapGestureRecognizer(target: self, action: Selector("cancelTask"))
        self.progressView.addGestureRecognizer(FingerTap)
        self.downloadControllerView.addSubview(self.progressView)
//        self.addSubview(self.progressView)
//        self.progressView.center = CGPoint(x: self.frame.maxX - self.progressView.frame.width / 2 - 10, y: self.center.y)

    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
