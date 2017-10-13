//
//  ConnectionConfiguration.swift
//  freeboxDownloader
//
//  Created by Yohann Verdier on 24/10/2016.
//  Copyright © 2016 Yohann Verdier. All rights reserved.
//

import Foundation

class ConnectionConfiguration {
    var remote_access_port:Int?
    var remote_access:Bool?
    
    init(remote_access_port:Int?, remote_access:Bool?) {
        if remote_access_port != nil {
            self.remote_access_port = remote_access_port
        }
        if remote_access != nil {
            self.remote_access = remote_access
        }
    }
}
