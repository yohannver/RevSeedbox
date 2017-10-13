//
//  DownloadConfiguration.swift
//  freeboxDownloader
//
//  Created by Yohann Verdier on 09/11/2016.
//  Copyright © 2016 Yohann Verdier. All rights reserved.
//

import Foundation

class DownloadConfiguration {
    
    var max_downloading_tasks:Int?
    var download_dir:String?
    var watch_dir:String?
    var use_watch_dir:Bool?
    var throttling:DlThrottlingConfig?
    var news:DlNewsConfig?
    var bt:DlBtConfig?
    var feed:DlFeedConfig?
    var blockList:DlBlockListConfig?
    
    init(max_downloading_tasks:Int?, download_dir:String?, watch_dir:String?, use_watch_dir:Bool?, throttling:DlThrottlingConfig?, news:DlNewsConfig?, bt:DlBtConfig?, feed:DlFeedConfig?, blockList:DlBlockListConfig?) {
        self.max_downloading_tasks = max_downloading_tasks
        self.download_dir = download_dir
        self.watch_dir = watch_dir
        self.use_watch_dir = use_watch_dir
        self.throttling = throttling
        self.news = news
        self.bt = bt
        self.feed = feed
        self.blockList = blockList
    }
}
