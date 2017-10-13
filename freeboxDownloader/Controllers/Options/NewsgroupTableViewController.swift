//
//  NewsgroupTableViewController.swift
//  freeboxDownloader
//
//  Created by Yohann Verdier on 12/11/2016.
//  Copyright © 2016 Yohann Verdier. All rights reserved.
//

import UIKit

class NewsgroupTableViewController: UITableViewController {
    
    @IBOutlet weak var ui_textFieldServer: UITextField!
    
    @IBOutlet weak var ui_textFieldPort: UITextField!
    
    @IBOutlet weak var ui_switchSSL: UISwitch!
    
    @IBOutlet weak var ui_textFieldNbConnexions: UITextField!
    
    @IBOutlet weak var ui_textFieldUser: UITextField!
    
    @IBOutlet weak var ui_textFieldPassword: UITextField!
    
    @IBOutlet weak var ui_switchNotPar2: UISwitch!
    
    @IBOutlet weak var ui_switchAutomaticReparation: UISwitch!
    
    @IBOutlet weak var ui_switchAutomaticExtraction: UISwitch!
    
    @IBOutlet weak var ui_switchEraseFiles: UISwitch!
    
    var _downloadConfiguration:DownloadConfiguration?
    
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
        
        if let down = _downloadConfiguration {
            if let newsGroups = down.news {
                if let server = newsGroups.server {
                    ui_textFieldServer.text = server
                }
                if let port = newsGroups.port {
                    ui_textFieldPort.text = "\(port)"
                }
                if let ssl = newsGroups.ssl {
                    ui_switchSSL.isOn = ssl
                }
                if let nthreads = newsGroups.nthreads {
                    ui_textFieldNbConnexions.text = "\(nthreads)"
                }
                if let user = newsGroups.user {
                    ui_textFieldUser.text = user
                }
                if let password = newsGroups.password {
                    ui_textFieldPassword.text = password
                }
                if let lazy_par2 = newsGroups.lazy_par2 {
                    ui_switchNotPar2.isOn = lazy_par2
                }
                if let auto_repair = newsGroups.auto_repair {
                    ui_switchAutomaticReparation.isOn = auto_repair
                }
                if let auto_extract = newsGroups.auto_extract {
                    ui_switchAutomaticExtraction.isOn = auto_extract
                }
                if let erase_tmp = newsGroups.erase_tmp {
                    ui_switchEraseFiles.isOn = erase_tmp
                }
            }
        }
        
        let mySelector: Selector = #selector(NewsgroupTableViewController.clickSave)
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "checkmark"), style: UIBarButtonItemStyle.done, target: self, action: mySelector)
        
        self.navigationItem.rightBarButtonItem!.isEnabled = false
        
        self.navigationItem.title = "Newsgroups"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(NewsgroupTableViewController.openParameters),name:NSNotification.Name(rawValue: "updateDownloadConfigurationSuccess"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(NewsgroupTableViewController.errorAlert),name:NSNotification.Name(rawValue: "updateDownloadConfigurationFail"), object: nil)
    }
    
    func clickSave() {
        
        alertPopped = false
        
        if let downConf = _downloadConfiguration {
            
            if let news = downConf.news {
                
                //server
                if let valueTextField = ui_textFieldServer.text {
                    
                    if valueTextField == "" {
                        //si aucune valeur n'est renseignée
                        let alert = UIAlertController(title: "Serveur", message: "Veuillez renseigner une valeur", preferredStyle: UIAlertControllerStyle.alert)
                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                        alertPopped = true
                    } else {
                        news.server = valueTextField
                    }
                }
                
                //port
                if let valueTextField = ui_textFieldPort.text {
                    
                    if valueTextField == "" {
                        //si aucune valeur n'est renseignée
                        let alert = UIAlertController(title: "Port", message: "Veuillez renseigner une valeur", preferredStyle: UIAlertControllerStyle.alert)
                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                        alertPopped = true
                    } else {
                        if let intValue = Int(valueTextField) {
                            //si la valeur renseignée est numérique
                            news.port = intValue
                        } else {
                            //si la valeur renseignée n'est pas en numérique
                            let alert = UIAlertController(title: "Port", message: "Veuillez renseigner une valeur numérique", preferredStyle: UIAlertControllerStyle.alert)
                            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
                            self.present(alert, animated: true, completion: nil)
                            alertPopped = true
                        }
                    }
                }
                
                //SSL
                news.ssl = ui_switchSSL.isOn
                
                //nombre connexions
                if let valueTextField = ui_textFieldNbConnexions.text {
                    
                    if valueTextField == "" {
                        //si aucune valeur n'est renseignée
                        let alert = UIAlertController(title: "Nombre de connexions", message: "Veuillez renseigner une valeur", preferredStyle: UIAlertControllerStyle.alert)
                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                        alertPopped = true
                    } else {
                        if let intValue = Int(valueTextField) {
                            //si la valeur renseignée est numérique
                            
                            if intValue < 1 || intValue > 30 {
                                let alert = UIAlertController(title: "Nombre de connexions", message: "La valeur doit être comprise entre 1 et 30", preferredStyle: UIAlertControllerStyle.alert)
                                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
                                self.present(alert, animated: true, completion: nil)
                                alertPopped = true
                            } else {
                                news.nthreads = intValue
                            }
                            
                        } else {
                            //si la valeur renseignée n'est pas en numérique
                            let alert = UIAlertController(title: "Nombre de connexions", message: "Veuillez renseigner une valeur numérique", preferredStyle: UIAlertControllerStyle.alert)
                            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
                            self.present(alert, animated: true, completion: nil)
                            alertPopped = true
                        }
                    }
                }
                
                //user
                news.user = ui_textFieldUser.text
                
                //password
                news.password = ui_textFieldPassword.text
                
                //par2
                news.lazy_par2 = ui_switchNotPar2.isOn
                
                //auto repair
                news.auto_repair = ui_switchAutomaticReparation.isOn
                
                //auto extraction
                news.auto_extract = ui_switchAutomaticExtraction.isOn
                
                //erase files
                news.erase_tmp = ui_switchEraseFiles.isOn
                
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
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func clickTextFieldServer(_ sender: UITextField) {
        self.navigationItem.rightBarButtonItem!.isEnabled = true
    }
    
    @IBAction func clickTextFieldPort(_ sender: UITextField) {
        self.navigationItem.rightBarButtonItem!.isEnabled = true
    }
    
    @IBAction func clickSwitchSSL(_ sender: UISwitch) {
        self.navigationItem.rightBarButtonItem!.isEnabled = true
    }
    
    @IBAction func clickTextFieldNbConnexions(_ sender: UITextField) {
        self.navigationItem.rightBarButtonItem!.isEnabled = true
    }
    
    @IBAction func clickTextFieldUser(_ sender: UITextField) {
        self.navigationItem.rightBarButtonItem!.isEnabled = true
    }
    
    @IBAction func clickTextFieldPassword(_ sender: UITextField) {
        self.navigationItem.rightBarButtonItem!.isEnabled = true
    }
    
    @IBAction func clickSwitchPar2(_ sender: UISwitch) {
        self.navigationItem.rightBarButtonItem!.isEnabled = true
    }
    
    @IBAction func clickSwitchRepairAuto(_ sender: UISwitch) {
        self.navigationItem.rightBarButtonItem!.isEnabled = true
    }
    
    @IBAction func clickSwitchExtractAuto(_ sender: UISwitch) {
        self.navigationItem.rightBarButtonItem!.isEnabled = true
    }
    
    @IBAction func clickSwitchEraseFiles(_ sender: UISwitch) {
        self.navigationItem.rightBarButtonItem!.isEnabled = true
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}
