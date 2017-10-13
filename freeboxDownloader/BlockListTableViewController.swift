//
//  BlockListTableViewController.swift
//  freeboxDownloader
//
//  Created by Yohann Verdier on 12/11/2016.
//  Copyright © 2016 Yohann Verdier. All rights reserved.
//

import UIKit

class BlockListTableViewController: UITableViewController, UITextViewDelegate {
    
    @IBOutlet weak var ui_textView: UITextView!
    
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
        
        ui_textView.delegate = self
        
        if let down = _downloadConfiguration {
            if let blockList = down.blockList {
                if let sources = blockList.sources {
                    for source in sources {
                        if source != "" {
                            ui_textView.text.append(source)
                            ui_textView.text.append("\n")
                        }
                    }
                    
                    if sources.count == 1 {
                        if sources.first == "" {
                            ui_textView.text = "Listes d'URL de fichiers de blocage d'IP, séparées par un saut de ligne"
                            ui_textView.textColor = UIColor.lightGray
                        }
                    }
                    
                } else {
                    ui_textView.text = "Listes d'URL de fichiers de blocage d'IP, séparées par un saut de ligne"
                    ui_textView.textColor = UIColor.lightGray
                }
            }
        }
        
        let mySelector: Selector = #selector(BlockListTableViewController.clickSave)
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "checkmark"), style: UIBarButtonItemStyle.done, target: self, action: mySelector)
        
        self.navigationItem.title = "Listes de blocages"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(BlockListTableViewController.openParameters),name:NSNotification.Name(rawValue: "updateDownloadConfigurationSuccess"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(BlockListTableViewController.errorAlert),name:NSNotification.Name(rawValue: "updateDownloadConfigurationFail"), object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
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
    
    func clickSave() {
        
        if let downConf = _downloadConfiguration {
            if let blockList = downConf.blockList {
                
                //Listes d'URL
                if let valueTextView = ui_textView.text {
                    
                    if valueTextView == "" {
                        ui_textView.text = "Listes d'URL de fichiers de blocage d'IP, séparées par un saut de ligne"
                        ui_textView.textColor = UIColor.lightGray
                        let sources:[String] = [""]
                        downConf.blockList = DlBlockListConfig(sources: sources)
                    } else if valueTextView == "Listes d'URL de fichiers de blocage d'IP, séparées par un saut de ligne" {
                        //ne rien faire
                    } else {
                        let tabTextView = valueTextView.components(separatedBy: "\n")
                        
                        downConf.blockList = DlBlockListConfig(sources: tabTextView)
                    }
                }
                
                
            }
        }
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        self.navigationItem.rightBarButtonItem!.isEnabled = false
        _httpRequestFreebox.updateDownloadConfiguration(downConfig: _downloadConfiguration)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if ui_textView.textColor == UIColor.lightGray {
            ui_textView.text = nil
            ui_textView.textColor = UIColor.black
        }
        self.navigationItem.rightBarButtonItem!.isEnabled = true
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if ui_textView.text.isEmpty {
            ui_textView.text = "Listes d'URL de fichiers de blocage d'IP, séparées par un saut de ligne"
            ui_textView.textColor = UIColor.lightGray
        }
    }
}
