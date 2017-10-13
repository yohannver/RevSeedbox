//
//  DlRate.swift
//  freeboxDownloader
//
//  Created by Yohann Verdier on 09/11/2016.
//  Copyright © 2016 Yohann Verdier. All rights reserved.
//

import Foundation

class DlRate {
    var tx_rate:Int?
    var rx_rate:Int?
    
    init(tx_rate:Int?, rx_rate:Int?) {
        self.tx_rate = tx_rate
        self.rx_rate = rx_rate
    }
    
    func getOcSKoSOrMoS(_ size:Double) -> String {
        if size == 0 {
            return "illimité"
        } else {
            if convertInKo(size) < 1 {
                return "\(size) o/s"
            } else if convertInMo(size) < 1 {
                return "\(convertInKo(size))"
            } else {
                return "\(convertInMo(size))"
            }
        }
    }
    
    func convertInGo(_ size:Double) -> Int {
        return Int(size / 1000000000)
    }
    
    func convertInMo(_ size:Double) -> Int {
        return Int(size / 1000000)
    }
    
    func convertInKo(_ size:Double) -> Int {
        return Int(size / 1000)
    }
}
