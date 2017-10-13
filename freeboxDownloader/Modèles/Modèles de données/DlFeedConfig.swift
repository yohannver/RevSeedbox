//
//  DlFeedConfig.swift
//  freeboxDownloader
//
//  Created by Yohann Verdier on 09/11/2016.
//  Copyright © 2016 Yohann Verdier. All rights reserved.
//

import Foundation

class DlFeedConfig {
    var fetch_interval:Int?
    var max_items:Int?
    
    init(fetch_interval:Int?, max_items:Int?) {
        self.fetch_interval = fetch_interval
        self.max_items = max_items
    }
}
