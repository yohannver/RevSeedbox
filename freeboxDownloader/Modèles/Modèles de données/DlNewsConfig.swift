//
//  DlNewsConfig.swift
//  freeboxDownloader
//
//  Created by Yohann Verdier on 09/11/2016.
//  Copyright © 2016 Yohann Verdier. All rights reserved.
//

import Foundation

class DlNewsConfig {
    var server:String?
    var port:Int?
    var ssl:Bool?
    var user:String?
    var password:String?
    var nthreads:Int?
    var auto_repair:Bool?
    var lazy_par2:Bool?
    var auto_extract:Bool?
    var erase_tmp:Bool?
    
    init(server:String?, port:Int?, ssl:Bool?, user:String?, password:String?, nthreads:Int?, auto_repair:Bool?, lazy_par2:Bool?, auto_extract:Bool?, erase_tmp:Bool?) {
        self.server = server
        self.port = port
        self.ssl = ssl
        self.user = user
        self.password = password
        self.nthreads = nthreads
        self.auto_repair = auto_repair
        self.lazy_par2 = lazy_par2
        self.auto_extract = auto_extract
        self.erase_tmp = erase_tmp
    }
}
