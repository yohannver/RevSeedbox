//
//  DlBtConfig.swift
//  freeboxDownloader
//
//  Created by Yohann Verdier on 09/11/2016.
//  Copyright © 2016 Yohann Verdier. All rights reserved.
//

import Foundation

class DlBtConfig {
    var max_peers:Int?
    var stop_ratio:Int?
    var crypto_support:String?
    var enable_dht:Bool?
    var enable_pex:Bool?
    var announce_timeout:Int?
    var main_port:Int?
    var dht_port:Int?
    
    init(max_peers:Int?, stop_ratio:Int?, crypto_support:String?, enable_dht:Bool?, enable_pex:Bool?, announce_timeout:Int?, main_port:Int?, dht_port:Int?) {
        self.max_peers = max_peers
        self.stop_ratio = stop_ratio
        self.crypto_support = crypto_support
        self.enable_dht = enable_dht
        self.enable_pex = enable_pex
        self.announce_timeout = announce_timeout
        self.main_port = main_port
        self.dht_port = dht_port
    }
    
    enum crypto_support_enum : String {
        case unsupported, allowed, preferred, required
    }
    
    func convertFrCrypto(mode:String) -> String {
        switch mode {
        case DlBtConfig.crypto_support_enum.unsupported.rawValue:
            return "Désactivé"
        case DlBtConfig.crypto_support_enum.allowed.rawValue:
            return "Autorisé"
        case DlBtConfig.crypto_support_enum.preferred.rawValue:
            return "Préféré"
        case DlBtConfig.crypto_support_enum.required.rawValue:
            return "Obligatoire"
        default:
            return "Type incconu"
        }
    }
    
    func convertEnumLanguageCrypto(mode:String) -> String {
        switch mode {
        case "Désactivé":
            return DlBtConfig.crypto_support_enum.unsupported.rawValue
        case "Autorisé":
            return DlBtConfig.crypto_support_enum.allowed.rawValue
        case "Préféré":
            return DlBtConfig.crypto_support_enum.preferred.rawValue
        case "Obligatoire":
            return DlBtConfig.crypto_support_enum.required.rawValue
        default:
            return "Type incconu"
        }
    }
}
