//
//  PartitionDetail.swift
//  freeboxDownloader
//
//  Created by Yohann Verdier on 06/11/2016.
//  Copyright © 2016 Yohann Verdier. All rights reserved.
//

import Foundation

class PartitionDetail {
    
    var total_bytes:Double?
    var label:String?
    var statePart:String?
    var free_bytes:Double?
    var used_bytes:Double?
    var path:String?
    
    init(total_bytes:Double?, label:String?, statePart:String?, free_bytes:Double?, used_bytes:Double?, path:String?) {
        self.total_bytes = total_bytes
        self.label = label
        self.statePart = statePart
        self.free_bytes = free_bytes
        self.used_bytes = used_bytes
        self.path = path
    }
    
    enum PartitionState : String {
        case error, disabled, enabled, formatting
    }
    
    func convertFrState(state:String) -> String {
        switch state {
        case PartitionDetail.PartitionState.error.rawValue:
            return "Erreur"
        case PartitionDetail.PartitionState.disabled.rawValue:
            return "Désactivé"
        case PartitionDetail.PartitionState.enabled.rawValue:
            return "Activé"
        case PartitionDetail.PartitionState.formatting.rawValue:
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
