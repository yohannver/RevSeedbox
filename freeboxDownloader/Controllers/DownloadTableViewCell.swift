//
//  DownloadTableViewCell.swift
//  freeboxDownloader
//
//  Created by Yohann Verdier on 28/10/2016.
//  Copyright © 2016 Yohann Verdier. All rights reserved.
//

import UIKit

class DownloadTableViewCell: UITableViewCell {
    
    @IBOutlet weak var ui_name: UILabel!
    
    @IBOutlet weak var ui_state: UILabel!
    
    @IBOutlet weak var ui_pourcent: UILabel!
    
    @IBOutlet weak var ui_size: UILabel!
    
    @IBOutlet weak var ui_uploadSpeed: UILabel!
    
    @IBOutlet weak var ui_downloadSpeed: UILabel!
    
    @IBOutlet weak var ui_progressBar: UIProgressView!
    
    var _downloadDetail:DownloadDetail?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    func display(download:DownloadDetail) {
        self._downloadDetail = download
        
        if let name = download.name {
            ui_name.text = name
        }
        
        if let status = download.status {
            ui_state.text = download.convertFrStatus(status: status)
            if status == DownloadDetail.DownloadStatus.downloading.rawValue {
                
                ui_progressBar.progressTintColor = UIColor.blue
                
                if let pourcReceived = download.rx_pct {
                    let numberFloat = Float(pourcReceived / 10000)
                    ui_progressBar.progress = numberFloat
                    ui_pourcent.text = "\(String(pourcReceived / 100)) %"
                }
            } else if status == DownloadDetail.DownloadStatus.seeding.rawValue {
                
                ui_progressBar.progressTintColor = UIColor.orange
                
                let numberFloat = Float(pourcentagePartage())
                ui_progressBar.progress = numberFloat / 100
                ui_pourcent.text = "\(String(round((numberFloat)*100)/100)) %"
            } else {
                
                //Dark green
                ui_progressBar.progressTintColor = UIColor(red:0.23, green:0.68, blue:0.16, alpha:1.0)
                
                if let pourcReceived = download.rx_pct {
                    let numberFloat = Float(pourcReceived / 10000)
                    ui_progressBar.progress = numberFloat
                    ui_pourcent.text = "\(String(pourcReceived / 100)) %"
                }
            }
        }
        
        if let size = download.size,
            let rx_bytes = download.rx_bytes {
            if rx_bytes == size {
                ui_size.text = "\(download.getMoOrGo(size))"
            } else {
                ui_size.text = "\(download.getMoOrGo(rx_bytes)) / \(download.getMoOrGo(size))"
            }
        }
        
        
        
        if let speedDownload = download.rx_rate {
            if speedDownload != 0 {
                ui_downloadSpeed.text = "DL : \(download.getOcSKoSOrMoS(speedDownload))"
            } else {
                ui_downloadSpeed.text = ""
            }
        }
        
        if let speedUpload = download.tx_rate {
            if speedUpload != 0 {
                ui_uploadSpeed.text = "UL : \(download.getOcSKoSOrMoS(speedUpload))"
            } else {
                ui_uploadSpeed.text = ""
            }
        }
    }
    
    
    
    func pourcentagePartage() -> Double {
        if let download = _downloadDetail {
            let recuOpt = download.rx_bytes
            let emisOpt = download.tx_bytes
            let ratioOpt = download.stop_ratio
            
            if let recu = recuOpt,
                let emis = emisOpt,
                let ratio = ratioOpt{
                
                let avancementRatio:Double = (emis/recu)
                
                let pourcentagePartage:Double = (avancementRatio/(ratio/100))*100
                
                return pourcentagePartage
            }
        }
        return 0
    }
    
}
