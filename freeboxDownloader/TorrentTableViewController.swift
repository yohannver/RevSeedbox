//
//  TorrentTableViewController.swift
//  freeboxDownloader
//
//  Created by Yohann Verdier on 11/11/2016.
//  Copyright © 2016 Yohann Verdier. All rights reserved.
//

import UIKit

class TorrentTableViewController: UITableViewController, writeValueBackDelegate {
    
    @IBOutlet weak var ui_sliderMaxPair: UISlider!
    
    @IBOutlet weak var ui_labelMaxPairs: UILabel!
    
    @IBOutlet weak var ui_textFieldShareRatio: UITextField!
    
    @IBOutlet weak var ui_encryptionConnexionCell: UITableViewCell!
    
    @IBOutlet weak var ui_switchDhtActivation: UISwitch!
    
    @IBOutlet weak var ui_switchSharePairActivation: UISwitch!
    
    @IBOutlet weak var ui_sliderWaitTime: UISlider!
    
    @IBOutlet weak var ui_labelWaitingTime: UILabel!
    
    @IBOutlet weak var ui_textFieldEntrancePort: UITextField!
    
    @IBOutlet weak var ui_textFieldDhtEntrancePort: UITextField!
    
    var _downloadConfiguration:DownloadConfiguration?
    
    var currentEncryptionConnexion = ""
    
    let USER_DEFAULTS = UserDefaults.standard
    
    var _httpRequestFreebox:HttpRequestFreebox = HttpRequestFreebox()
    
    var alertPopped = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        _httpRequestFreebox.app_token = USER_DEFAULTS.string(forKey: HttpRequestFreebox.APP_TOKEN)
        
        //Récupération de l'IP de la freeboxserver dans les userdefaults
        _httpRequestFreebox.ipServer = USER_DEFAULTS.string(forKey: HttpRequestFreebox.IP_FREEBOXSERVER)
        //Récupération le port de la freeboxserver dans les userdefaults
        _httpRequestFreebox.portServer = USER_DEFAULTS.integer(forKey: HttpRequestFreebox.REMOTE_ACCESS_PORT)
        
        _httpRequestFreebox.getLocalURLOrIP()
        
        EncryptionConnexionsTableViewController.delegate = self
        
        if let down = _downloadConfiguration {
            if let bitTorrent = down.bt {
                if let dhtPort = bitTorrent.dht_port {
                    ui_textFieldDhtEntrancePort.text = "\(dhtPort)"
                }
                if let mainPort = bitTorrent.main_port {
                    ui_textFieldEntrancePort.text = "\(mainPort)"
                }
                if let annouceTimeOut = bitTorrent.announce_timeout {
                    ui_sliderWaitTime.value = Float(annouceTimeOut)
                }
                if let cryptoSupport = bitTorrent.crypto_support {
                    currentEncryptionConnexion = bitTorrent.convertFrCrypto(mode: cryptoSupport)
                    ui_encryptionConnexionCell.detailTextLabel!.text = currentEncryptionConnexion
                }
                if let enableDht = bitTorrent.enable_dht {
                    ui_switchDhtActivation.isOn = enableDht
                }
                if let enablePex = bitTorrent.enable_pex {
                    ui_switchSharePairActivation.isOn = enablePex
                }
                if let maxPeers = bitTorrent.max_peers {
                    ui_sliderMaxPair.value = Float(maxPeers)
                }
                if let stopRatio = bitTorrent.stop_ratio {
                    let ratio:Double = Double(stopRatio) / 100
                    if ratio == 0 {
                        ui_textFieldShareRatio.text = "illimité"
                    } else {
                        ui_textFieldShareRatio.text = "\(ratio)"
                    }
                }
            }
        }
        
        ui_labelWaitingTime.text = "\(Int(ui_sliderWaitTime.value))"
        ui_labelMaxPairs.text = "\(Int(ui_sliderMaxPair.value))"
        
        let mySelector: Selector = #selector(NewsgroupTableViewController.clickSave)
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "checkmark"), style: UIBarButtonItemStyle.done, target: self, action: mySelector)
        
        self.navigationItem.title = "Torrent"
        
        self.navigationItem.rightBarButtonItem!.isEnabled = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(NewsgroupTableViewController.openParameters),name:NSNotification.Name(rawValue: "updateDownloadConfigurationSuccess"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(NewsgroupTableViewController.errorAlert),name:NSNotification.Name(rawValue: "updateDownloadConfigurationFail"), object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }
    
    func clickSave() {
        
        alertPopped = false
        
        if let downConf = _downloadConfiguration {
            
            if let bittorrent = downConf.bt {
                
                //nb pairs max
                bittorrent.max_peers = Int(ui_sliderMaxPair.value)
                
                //share ratio
                if let valueTextField = ui_textFieldShareRatio.text {
                    
                    //si une valeur est renseignée
                    if valueTextField == "illimité" {
                        bittorrent.stop_ratio = 0
                        
                    }else if valueTextField == "" {
                        //si aucune valeur n'est renseignée
                        let alert = UIAlertController(title: "Ratio de partage", message: "Veuillez renseigner une valeur", preferredStyle: UIAlertControllerStyle.alert)
                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                        alertPopped = true
                    } else {
                        
                        let valueTextFieldWithDot = valueTextField.replacingOccurrences(of: ",", with: ".")
                        
                        if let doubleValue = Double(valueTextFieldWithDot) {
                            //si la valeur renseignée est un double
                            let intValue = Int(doubleValue * 100)
                            
                            if intValue < 0 || intValue > 10000 {
                                let alert = UIAlertController(title: "Ratio de partage", message: "La valeur doit être comprise entre 0 et 100", preferredStyle: UIAlertControllerStyle.alert)
                                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
                                self.present(alert, animated: true, completion: nil)
                                alertPopped = true
                            } else {
                                bittorrent.stop_ratio = intValue
                            }
                            
                        } else {
                            //si la valeur renseignée n'est pas un double
                            let alert = UIAlertController(title: "Ratio de partage", message: "Veuillez renseigner une valeur décimale", preferredStyle: UIAlertControllerStyle.alert)
                            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
                            self.present(alert, animated: true, completion: nil)
                            alertPopped = true
                        }
                    }
                }
                
                //encryption connexion
                bittorrent.crypto_support = bittorrent.convertEnumLanguageCrypto(mode: currentEncryptionConnexion)
                
                //DHT activation
                bittorrent.enable_dht = ui_switchDhtActivation.isOn
                
                //peers share activation
                bittorrent.enable_pex = ui_switchSharePairActivation.isOn
                
                //waiting time
                bittorrent.announce_timeout = Int(ui_sliderWaitTime.value)
                
                //entrance port
                if let valueTextField = ui_textFieldEntrancePort.text {
                    //si une valeur est renseignée
                    if valueTextField == "" {
                        //si aucune valeur n'est renseignée
                        let alert = UIAlertController(title: "Port entrant principal", message: "Veuillez renseigner une valeur", preferredStyle: UIAlertControllerStyle.alert)
                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                        alertPopped = true
                    } else {
                        if let intValue = Int(valueTextField) {
                            //si la valeur renseignée est numérique
                            
                            if intValue < 1 || intValue > 65535 {
                                let alert = UIAlertController(title: "Port entrant principal", message: "La valeur doit être comprise entre 1 et 65535", preferredStyle: UIAlertControllerStyle.alert)
                                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
                                self.present(alert, animated: true, completion: nil)
                                alertPopped = true
                            } else {
                                bittorrent.main_port = intValue
                            }
                        } else {
                            //si la valeur renseignée n'est pas en numérique
                            let alert = UIAlertController(title: "Port entrant principal", message: "Veuillez renseigner une valeur numérique", preferredStyle: UIAlertControllerStyle.alert)
                            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
                            self.present(alert, animated: true, completion: nil)
                            alertPopped = true
                        }
                    }
                }
                
                //DHT entrance port
                if let valueTextField = ui_textFieldDhtEntrancePort.text {
                    //si une valeur est renseignée
                    if valueTextField == "" {
                        //si aucune valeur n'est renseignée
                        let alert = UIAlertController(title: "Port entrant DHT", message: "Veuillez renseigner une valeur", preferredStyle: UIAlertControllerStyle.alert)
                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                        alertPopped = true
                    } else {
                        if let intValue = Int(valueTextField) {
                            //si la valeur renseignée est numérique
                            
                            if intValue < 1 || intValue > 65535 {
                                let alert = UIAlertController(title: "Port entrant DHT", message: "La valeur doit être comprise entre 1 et 65535", preferredStyle: UIAlertControllerStyle.alert)
                                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
                                self.present(alert, animated: true, completion: nil)
                                alertPopped = true
                            } else {
                                bittorrent.dht_port = intValue
                            }
                        } else {
                            //si la valeur renseignée n'est pas en numérique
                            let alert = UIAlertController(title: "Port entrant DHT", message: "Veuillez renseigner une valeur numérique", preferredStyle: UIAlertControllerStyle.alert)
                            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
                            self.present(alert, animated: true, completion: nil)
                            alertPopped = true
                        }
                    }
                }
                
                
                
            }
            
        }
        
        if !alertPopped {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            self.navigationItem.rightBarButtonItem!.isEnabled = false
            _httpRequestFreebox.updateDownloadConfiguration(downConfig: _downloadConfiguration)
        }
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
    
    func writeValueBack(value: String) {
        currentEncryptionConnexion = value
        ui_encryptionConnexionCell.detailTextLabel!.text = currentEncryptionConnexion
        self.navigationItem.rightBarButtonItem!.isEnabled = true
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showEncryptionConnexions" {
            let destination = segue.destination as! EncryptionConnexionsTableViewController
            destination.cellSelected = currentEncryptionConnexion
        }
    }
    
    @IBAction func clickMaxPair(_ sender: UISlider) {
        ui_labelMaxPairs.text = "\(Int(sender.value))"
        self.navigationItem.rightBarButtonItem!.isEnabled = true
    }
    
    @IBAction func clickWaitingTime(_ sender: UISlider) {
        ui_labelWaitingTime.text = "\(Int(sender.value))"
        self.navigationItem.rightBarButtonItem!.isEnabled = true
    }
    
    @IBAction func clickTextFieldShareRatio(_ sender: UITextField) {
        self.navigationItem.rightBarButtonItem!.isEnabled = true
    }
    
    @IBAction func clickSwitchDhtActivation(_ sender: UISwitch) {
        self.navigationItem.rightBarButtonItem!.isEnabled = true
    }
    
    @IBAction func clickSwitchSharePairsActivation(_ sender: UISwitch) {
        self.navigationItem.rightBarButtonItem!.isEnabled = true
    }
    
    @IBAction func clickTextFieldEntrancePort(_ sender: UITextField) {
        self.navigationItem.rightBarButtonItem!.isEnabled = true
    }
    
    @IBAction func clickTextFieldDhtEntrancePort(_ sender: UITextField) {
        self.navigationItem.rightBarButtonItem!.isEnabled = true
    }
    
}
