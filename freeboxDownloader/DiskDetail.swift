//
//  DiskDetail.swift
//  freeboxDownloader
//
//  Created by Yohann Verdier on 06/11/2016.
//  Copyright © 2016 Yohann Verdier. All rights reserved.
//

import Foundation

class DiskDetail {
    
    var type:String?
    var state:String?
    var total_bytes:Double?
    var listPartitions:[PartitionDetail]?
    
    init(type:String?, state:String?, total_bytes:Double?, listPartitions:[PartitionDetail]?) {
        self.type = type
        self.state = state
        self.total_bytes = total_bytes
        self.listPartitions = listPartitions
    }
    
    enum DiskState : String {
        case error, disabled, enabled, formatting
    }
    
    enum DiskType : String {
        case intern_al, usb, sata
    }
    
    func convertFrType(type:String) -> String {
        switch type {
        case DiskDetail.DiskType.intern_al.rawValue:
            return "Interne"
        case DiskDetail.DiskType.usb.rawValue:
            return "USB "
        case DiskDetail.DiskType.sata.rawValue:
            return "SATA"
        default:
            return "Type incconu"
        }
    }
    
    func convertFrState(state:String) -> String {
        switch state {
        case DiskDetail.DiskState.error.rawValue:
            return "Erreur"
        case DiskDetail.DiskState.disabled.rawValue:
            return "Désactivé"
        case DiskDetail.DiskState.enabled.rawValue:
            return "Activé"
        case DiskDetail.DiskState.formatting.rawValue:
            return "En cours de formatage"
        default:
            return "Etat incconu"
        }
    }
    
    func getMoOrGo(_ size:Double) -> String {
        if convertInGo(size) < 1.0 {
            return "\(convertInMo(size)) Mo"
        } else {
            return "\(convertInGo(size)) Go"
        }
    }
    
    func convertInGo(_ size:Double) -> Double {
        return arrondir(size / 1000000000)
    }
    
    func convertInMo(_ size:Double) -> Double {
        return arrondir(size / 1000000)
    }
    
    func convertInKo(_ size:Double) -> Double {
        return arrondir(size / 1000)
    }
    
    func arrondir(_ value:Double) -> Double {
        let numberOfPlaces = 1.0
        let multiplier = pow(10.0, numberOfPlaces)
        
        return round(value * multiplier) / multiplier
    }
    
}
