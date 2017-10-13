//
//  ConnectionStatus.swift
//  freeboxDownloader
//
//  Created by Yohann Verdier on 24/10/2016.
//  Copyright © 2016 Yohann Verdier. All rights reserved.
//

import Foundation

class ConnectionStatus {
    var ipv4:String?
    var ipv6:String?
    var state:String?
    
    init(ip4:String?, ip6:String?, state:String?) {
        if ip4 != nil {
            self.ipv4 = ip4
        }
        if ip6 != nil {
            self.ipv6 = ip6
        }
        if state != nil {
            self.state = state
        }
    }
}
