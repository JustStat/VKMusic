//
//  counter.swift
//  VKMusic
//
//  Created by Kirill Varlamov on 06.11.15.
//  Copyright © 2015 Kirill Varlamov. All rights reserved.
//

import UIKit

class counter: NSObject {
    var index: Int = 0
    static let sharedInstance = counter()
}
