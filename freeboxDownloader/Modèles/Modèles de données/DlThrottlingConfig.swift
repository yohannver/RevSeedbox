//
//  DlThrottlingConfig.swift
//  freeboxDownloader
//
//  Created by Yohann Verdier on 09/11/2016.
//  Copyright © 2016 Yohann Verdier. All rights reserved.
//

import Foundation

class DlThrottlingConfig {
    var normal:DlRate?
    var slow:DlRate?
    var schedule:[String]?
    var mode:String?
    
    init(normal:DlRate?, slow:DlRate?, schedule:[String]?, mode:String?) {
        self.normal = normal
        self.slow = slow
        self.schedule = schedule
        self.mode = mode
    }
    
    enum scheduleEnum : String {
        case normal, slow, hibernate
    }
    enum modeEnum : String {
        case normal, slow, hibernate, schedule
    }
    
    func convertFrMode(mode:String) -> String {
        switch mode {
        case DlThrottlingConfig.modeEnum.normal.rawValue:
            return "Normal"
        case DlThrottlingConfig.modeEnum.slow.rawValue:
            return "Réduit"
        case DlThrottlingConfig.modeEnum.hibernate.rawValue:
            return "Arrêter"
        case DlThrottlingConfig.modeEnum.schedule.rawValue:
            return "Planification"
        default:
            return "Type incconu"
        }
    }
    
    func convertEnumLanguageMode(mode:String) -> String {
        switch mode {
        case "Normal":
            return DlThrottlingConfig.modeEnum.normal.rawValue
        case "Réduit":
            return DlThrottlingConfig.modeEnum.slow.rawValue
        case "Arrêter":
            return DlThrottlingConfig.modeEnum.hibernate.rawValue
        case "Planification":
            return DlThrottlingConfig.modeEnum.schedule.rawValue
        default:
            return "Type incconu"
        }
    }
}
