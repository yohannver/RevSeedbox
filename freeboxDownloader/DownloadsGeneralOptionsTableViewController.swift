//
//  SimultaneousDownloadsTableViewController.swift
//  freeboxDownloader
//
//  Created by Yohann Verdier on 11/11/2016.
//  Copyright © 2016 Yohann Verdier. All rights reserved.
//

import UIKit

class DownloadsGeneralOptionsTableViewController: UITableViewController {

    @IBOutlet weak var ui_labelNbDownloads: UILabel!
    
    @IBOutlet weak var ui_slider: UISlider!
    
    @IBOutlet weak var ui_downloadDirCell: UITableViewCell!
    
    @IBOutlet weak var ui_downloadDirMonitoredCell: UITableViewCell!
    
    @IBOutlet weak var ui_switch: UISwitch!
    
    var _downloadConfiguration:DownloadConfiguration?
    
    let USER_DEFAULTS = UserDefaults.standard
    
    var _httpRequestFreebox:HttpRequestFreebox = HttpRequestFreebox()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        _httpRequestFreebox.app_token = USER_DEFAULTS.string(forKey: HttpRequestFreebox.APP_TOKEN)
        
        //Récupération de l'IP de la freeboxserver dans les userdefaults
        _httpRequestFreebox.ipServer = USER_DEFAULTS.string(forKey: HttpRequestFreebox.IP_FREEBOXSERVER)
        //Récupération le port de la freeboxserver dans les userdefaults
        _httpRequestFreebox.portServer = USER_DEFAULTS.integer(forKey: HttpRequestFreebox.REMOTE_ACCESS_PORT)
        
        _httpRequestFreebox.getLocalURLOrIP()
        
        self.navigationItem.title = "Réglages généraux"
        
        if let downloadConf = _downloadConfiguration {
            if let maxTasks = downloadConf.max_downloading_tasks {
                ui_slider.value = Float(maxTasks)
            }
            if let downloadDir = downloadConf.download_dir {
                let decodedData = Data(base64Encoded: String(downloadDir), options: NSData.Base64DecodingOptions.init(rawValue: 0))
                let decodedString = String(data: decodedData!, encoding: String.Encoding.utf8)
                ui_downloadDirCell.textLabel!.text = decodedString
            }
            if let useWatchDir = downloadConf.use_watch_dir {
                ui_switch.isOn = useWatchDir
            }
            if let watchDir = downloadConf.watch_dir {
                let decodedData = Data(base64Encoded: String(watchDir), options: NSData.Base64DecodingOptions.init(rawValue: 0))
                let decodedString = String(data: decodedData!, encoding: String.Encoding.utf8)
                ui_downloadDirMonitoredCell.textLabel!.text = decodedString
            }
        }
        ui_labelNbDownloads.text = "\(Int(ui_slider.value))"
        
        let mySelector: Selector = #selector(DownloadsGeneralOptionsTableViewController.clickSave)
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "checkmark"), style: UIBarButtonItemStyle.done, target: self, action: mySelector)
        
        self.navigationItem.rightBarButtonItem!.isEnabled = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(DownloadsGeneralOptionsTableViewController.openParameters),name:NSNotification.Name(rawValue: "updateDownloadConfigurationSuccess"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(DownloadsGeneralOptionsTableViewController.errorAlert),name:NSNotification.Name(rawValue: "updateDownloadConfigurationFail"), object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }
    
    func clickSave() {
        
        if let downConf = _downloadConfiguration {
            
            downConf.max_downloading_tasks = Int(ui_slider.value)
            
            downConf.use_watch_dir = ui_switch.isOn
            
        }
        
        _httpRequestFreebox.updateDownloadConfiguration(downConfig: _downloadConfiguration)
        self.navigationItem.rightBarButtonItem!.isEnabled = false
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func openParameters() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        
        self.navigationController!.popViewController(animated: true)
    }
    
    func errorAlert() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        
        let alert = UIAlertController(title: "Erreur", message: "Erreur de communication avec le freebox server", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func clickSlide(_ sender: UISlider) {
        ui_labelNbDownloads.text = "\(Int(sender.value))"
        self.navigationItem.rightBarButtonItem!.isEnabled = true
    }
    
    @IBAction func clickSwitch(_ sender: UISwitch) {
        self.navigationItem.rightBarButtonItem!.isEnabled = true
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

}
