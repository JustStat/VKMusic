//
//  RevealViewController.swift
//  VKMusic
//
//  Created by Kirill Varlamov on 11.11.15.
//  Copyright © 2015 Kirill Varlamov. All rights reserved.
//

import UIKit

class RevealViewController: SWRevealViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.view.addGestureRecognizer(self.panGestureRecognizer())
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
