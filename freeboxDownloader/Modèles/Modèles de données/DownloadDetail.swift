//
//  DownloadOnFreebox.swift
//  cocoapods
//
//  Created by Yohann Verdier on 23/10/2016.
//  Copyright © 2016 Yohann Verdier. All rights reserved.
//

import Foundation

class DownloadDetail {
    
    var rx_bytes:Double?
    var tx_bytes:Double?
    var download_dir:String?
    var archive_password:String?
    var eta:Int?
    var status:String?
    var io_priority:String?
    var size:Double?
    var type:String?
    var error:String?
    var queue_pos:Int?
    var id:Int?
    var created_ts:Int?
    var tx_rate:Double?
    var name:String?
    var stop_ratio:Double?
    var rx_pct:Double?
    var rx_rate:Double?
    var tx_pct:Double?
    var notificationActivated:Bool = false
    
    init(name:String?, downDir:String?, size:Double?, status:String?, id:Int?, rx_bytes:Double?, tx_bytes:Double?, archive_password:String?, eta:Int?, io_priority:String?, type:String?, error:String?, queue_pos:Int?, created_ts:Int?, tx_rate:Double?, rx_pct:Double?, rx_rate:Double?, tx_pct:Double?, ratio:Double?) {
        self.name = name
        self.download_dir = downDir
        self.size = size
        self.status = status
        self.id = id
        self.rx_bytes = rx_bytes
        self.tx_bytes = tx_bytes
        self.archive_password = archive_password
        self.eta = eta
        self.io_priority = io_priority
        self.type = type
        self.error = error
        self.queue_pos = queue_pos
        self.created_ts = created_ts
        self.tx_rate = tx_rate
        self.rx_pct = rx_pct
        self.rx_rate = rx_rate
        self.tx_pct = tx_pct
        self.stop_ratio = ratio
    }
    
    enum DownloadStatus : String {
        case stopped, queued, starting, downloading, stopping, error, done, checking, repairing, extracting, seeding, retry
    }
    
    enum DownloadType : String {
        case bt, nzb, http, ftp
    }
    
    enum DownloadPriority : String {
        case low, normal, high
    }
    
    func convertFrType(type:String) -> String {
        switch type {
        case DownloadDetail.DownloadType.bt.rawValue:
            return "Bittorrent"
        case DownloadDetail.DownloadType.nzb.rawValue:
            return "Newsgroup "
        case DownloadDetail.DownloadType.http.rawValue:
            return "Http"
        case DownloadDetail.DownloadType.ftp.rawValue:
            return "Ftp"
        default:
            return "Type incconu"
        }
    }
    
    func convertFrStatus(status:String) -> String {
        switch status {
        case DownloadDetail.DownloadStatus.stopped.rawValue:
            return "En pause"
        case DownloadDetail.DownloadStatus.queued.rawValue:
            return "Queued"
        case DownloadDetail.DownloadStatus.starting.rawValue:
            return "En préparation"
        case DownloadDetail.DownloadStatus.downloading.rawValue:
            return "En cours de téléchargement"
        case DownloadDetail.DownloadStatus.stopping.rawValue:
            return "En cours d'arrêt"
        case DownloadDetail.DownloadStatus.error.rawValue:
            return "Erreur"
        case DownloadDetail.DownloadStatus.done.rawValue:
            return "Terminé"
        case DownloadDetail.DownloadStatus.checking.rawValue:
            return "En cours de vérification"
        case DownloadDetail.DownloadStatus.repairing.rawValue:
            return "En cours de réparation"
        case DownloadDetail.DownloadStatus.extracting.rawValue:
            return "En cours d'extraction"
        case DownloadDetail.DownloadStatus.seeding.rawValue:
            return "Partage en cours"
        case DownloadDetail.DownloadStatus.retry.rawValue:
            return "Retry"
        default:
            return "Statut incconu"
        }
    }
    
    func convertFrPriority(priority:String) -> String {
        switch priority {
        case DownloadDetail.DownloadPriority.low.rawValue:
            return "Basse"
        case DownloadDetail.DownloadPriority.normal.rawValue:
            return "Normale"
        case DownloadDetail.DownloadPriority.high.rawValue:
            return "Haute"
        default:
            return "Priorité incconu"
        }
    }
    
    func secondsToHoursMinutesSeconds (seconds : Int) -> (Int, Int, Int) {
        return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }
    
    func getMoOrGo(_ size:Double) -> String {
        if convertInGo(size) < 1.0 {
            return "\(convertInMo(size)) Mo"
        } else {
            return "\(convertInGo(size)) Go"
        }
    }
    
    func getOcSKoSOrMoS(_ size:Double) -> String {
        if convertInKo(size) < 1.0 {
            return "\(size) o/s"
        } else if convertInMo(size) < 1.0 {
            return "\(convertInKo(size)) Ko/s"
        } else {
            return "\(convertInMo(size)) Mo/s"
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
