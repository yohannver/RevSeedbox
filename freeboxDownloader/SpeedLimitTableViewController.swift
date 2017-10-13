//
//  SpeedLimitTableViewController.swift
//  freeboxDownloader
//
//  Created by Yohann Verdier on 11/11/2016.
//  Copyright © 2016 Yohann Verdier. All rights reserved.
//

import UIKit

protocol writeValueBackDelegate {
    func writeValueBack(value: String)
}

class SpeedLimitTableViewController: UITableViewController, writeValueBackDelegate {
    
    @IBOutlet weak var ui_tableViewCellModeChoice: UITableViewCell!
    
    @IBOutlet weak var ui_textFieldNormalDownload: UITextField!
    
    @IBOutlet weak var ui_textFieldNormalUpload: UITextField!
    
    @IBOutlet weak var ui_textFieldReduitDownload: UITextField!
    
    @IBOutlet weak var ui_textFieldReduitUpload: UITextField!
    
    //La configuration des téléchargements récupéré sur la freebox
    var _downloadConfiguration:DownloadConfiguration?
    
    //Les différents modes disponibles
    let mode = ["Normal", "Réduit", "Planification", "Arrêter"]
    
    //Le mode actuellement sélectionné
    var currentMode = ""
    
    let USER_DEFAULTS = UserDefaults.standard
    
    var _httpRequestFreebox:HttpRequestFreebox = HttpRequestFreebox()
    
    //Permet de savoir si une alerte a poppé (erreur)
    var alertPopped = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Récupération de l'app_token de la freeboxserver dans les userdefaults
        _httpRequestFreebox.app_token = USER_DEFAULTS.string(forKey: HttpRequestFreebox.APP_TOKEN)
        
        //Récupération de l'IP de la freeboxserver dans les userdefaults
        _httpRequestFreebox.ipServer = USER_DEFAULTS.string(forKey: HttpRequestFreebox.IP_FREEBOXSERVER)
        //Récupération le port de la freeboxserver dans les userdefaults
        _httpRequestFreebox.portServer = USER_DEFAULTS.integer(forKey: HttpRequestFreebox.REMOTE_ACCESS_PORT)
        
        _httpRequestFreebox.getLocalURLOrIP()
        
        //On lie le delegate pour pouvoir appeler la méthode du writeValueBackDelegate
        ChoiceModeTableViewController.delegate = self
        
        //Affichage des informations dans la vue
        if let downConf = _downloadConfiguration {
            if let throttling = downConf.throttling {
                
                if let mode = throttling.mode {
                    //Le mode sélectionné est celui récupéré sur la freebox
                    currentMode = throttling.convertFrMode(mode: mode)
                }
                
                //Normal
                if let normal = throttling.normal {
                    
                    //Download
                    if let rx_rate = normal.rx_rate {
                        ui_textFieldNormalDownload.text = normal.getOcSKoSOrMoS(Double(rx_rate))
                    }
                    
                    //Upload
                    if let tx_rate = normal.tx_rate {
                        ui_textFieldNormalUpload.text = normal.getOcSKoSOrMoS(Double(tx_rate))
                    }
                }
                
                //Slow
                if let slow = throttling.slow {
                    
                    //Download
                    if let rx_rate = slow.rx_rate {
                        ui_textFieldReduitDownload.text = slow.getOcSKoSOrMoS(Double(rx_rate))
                    }
                    
                    //Upload
                    if let tx_rate = slow.tx_rate {
                        
                        ui_textFieldReduitUpload.text = slow.getOcSKoSOrMoS(Double(tx_rate))
                    }
                }
            }
        }
        
        //Affichage du mode sélectionné sur la vue
        ui_tableViewCellModeChoice.detailTextLabel!.text = currentMode
        
        self.navigationItem.title = "Limites de vitesse"
        
        //Création du selector pour le clique du bouton save
        let mySelector: Selector = #selector(SpeedLimitTableViewController.clickSave)
        
        //Ajout du bouton save à la vue
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "checkmark"), style: UIBarButtonItemStyle.done, target: self, action: mySelector)
        
        //Désactivation du bouton save
        self.navigationItem.rightBarButtonItem!.isEnabled = false
    }
    
    //Lorsque la vue va apparaître
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(SpeedLimitTableViewController.openParameters),name:NSNotification.Name(rawValue: "updateDownloadConfigurationSuccess"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SpeedLimitTableViewController.errorAlert),name:NSNotification.Name(rawValue: "updateDownloadConfigurationFail"), object: nil)
    }
    
    //Lorsque la vue va disparaître
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }
    
    //Ouverture de la vue précédente lorsque le save s'est bien déroulé
    func openParameters() {
        //Suppression de l'indicateur de chargement réseau
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        
        //Retour sur la vue précédente
        self.navigationController!.popViewController(animated: true)
    }
    
    //Affichage d'une erreur lorsque le save s'est mal déroulé
    func errorAlert() {
        //Suppression de l'indicateur de chargement réseau
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        
        let alert = UIAlertController(title: "Erreur", message: "Erreur de communication avec le freebox server", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func clickSave() {
        
        alertPopped = false
        
        if let downConf = _downloadConfiguration {
            if let throttling = downConf.throttling {
                
                //mode
                throttling.mode = throttling.convertEnumLanguageMode(mode: currentMode)
                
                //Normal
                if let normal = throttling.normal {
                    
                    //Download
                    if let valueTextField = ui_textFieldNormalDownload.text {
                        //si une valeur est renseignée
                        if valueTextField == "illimité" {
                            normal.rx_rate = 0
                            ui_textFieldNormalDownload.text = "illimité"
                        } else if valueTextField == "" {
                            //si aucune valeur n'est renseignée
                            let alert = UIAlertController(title: "Mode normal", message: "Veuillez renseigner une valeur", preferredStyle: UIAlertControllerStyle.alert)
                            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
                            self.present(alert, animated: true, completion: nil)
                            alertPopped = true
                        } else {
                            if let intValue = Int(valueTextField) {
                                //si la valeur renseignée est numérique
                                normal.rx_rate = intValue * 1000
                                
                                if normal.rx_rate == 0 {
                                    ui_textFieldNormalDownload.text = "illimité"
                                }
                                
                            } else {
                                //si la valeur renseignée n'est pas en numérique
                                let alert = UIAlertController(title: "Mode normal", message: "Veuillez renseigner une valeur numérique", preferredStyle: UIAlertControllerStyle.alert)
                                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
                                self.present(alert, animated: true, completion: nil)
                                alertPopped = true
                            }
                        }
                    }
                    
                    //Upload
                    if let valueTextField = ui_textFieldNormalUpload.text {
                        //si une valeur est renseignée
                        if valueTextField == "illimité" {
                            normal.tx_rate = 0
                            
                        } else if valueTextField == "" {
                            //si aucune valeur n'est renseignée
                            let alert = UIAlertController(title: "Mode normal", message: "Veuillez renseigner une valeur", preferredStyle: UIAlertControllerStyle.alert)
                            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
                            self.present(alert, animated: true, completion: nil)
                            alertPopped = true
                        } else {
                            if let intValue = Int(valueTextField) {
                                //si la valeur renseignée est numérique
                                normal.tx_rate = intValue * 1000
                                
                                if normal.tx_rate == 0 {
                                    ui_textFieldNormalUpload.text = "illimité"
                                }
                                
                            } else {
                                //si la valeur renseignée n'est pas en numérique
                                let alert = UIAlertController(title: "Mode normal", message: "Veuillez renseigner une valeur numérique", preferredStyle: UIAlertControllerStyle.alert)
                                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
                                self.present(alert, animated: true, completion: nil)
                                alertPopped = true
                            }
                        }
                    }
                    
                    
                }
                
                //Slow
                if let slow = throttling.slow {
                    
                    //Download
                    if let valueTextField = ui_textFieldReduitDownload.text {
                        //si une valeur est renseignée
                        if valueTextField == "illimité" {
                            slow.rx_rate = 0
                        } else if valueTextField == "" {
                            //si aucune valeur n'est renseignée
                            let alert = UIAlertController(title: "Mode réduit", message: "Veuillez renseigner une valeur", preferredStyle: UIAlertControllerStyle.alert)
                            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
                            self.present(alert, animated: true, completion: nil)
                            alertPopped = true
                        } else {
                            if let intValue = Int(valueTextField) {
                                //si la valeur renseignée est numérique
                                slow.rx_rate = intValue * 1000
                                
                                if slow.rx_rate == 0 {
                                    ui_textFieldReduitDownload.text = "illimité"
                                }
                                
                            } else {
                                //si la valeur renseignée n'est pas en numérique
                                let alert = UIAlertController(title: "Mode réduit", message: "Veuillez renseigner une valeur numérique", preferredStyle: UIAlertControllerStyle.alert)
                                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
                                self.present(alert, animated: true, completion: nil)
                                alertPopped = true
                            }
                        }
                    }
                    
                    //Upload
                    if let valueTextField = ui_textFieldReduitUpload.text {
                        //si une valeur est renseignée
                        if valueTextField == "illimité" {
                            slow.tx_rate = 0
                            
                        } else if valueTextField == "" {
                            //si aucune valeur n'est renseignée
                            let alert = UIAlertController(title: "Mode réduit", message: "Veuillez renseigner une valeur", preferredStyle: UIAlertControllerStyle.alert)
                            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
                            self.present(alert, animated: true, completion: nil)
                            alertPopped = true
                        } else {
                            if let intValue = Int(valueTextField) {
                                //si la valeur renseignée est numérique
                                slow.tx_rate = intValue * 1000
                                
                                if slow.tx_rate == 0 {
                                    ui_textFieldReduitUpload.text = "illimité"
                                }
                                
                            } else {
                                //si la valeur renseignée n'est pas en numérique
                                let alert = UIAlertController(title: "Mode réduit", message: "Veuillez renseigner une valeur numérique", preferredStyle: UIAlertControllerStyle.alert)
                                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
                                self.present(alert, animated: true, completion: nil)
                                alertPopped = true
                            }
                        }
                    }
                    
                    
                }
                
            }
        }
        
        //Si il n'y a eu aucune erreur
        if !alertPopped {
            //Envoi de la requête http sur la freebox
            _httpRequestFreebox.updateDownloadConfiguration(downConfig: _downloadConfiguration)
            
            //Désactivation du bouton save
            self.navigationItem.rightBarButtonItem!.isEnabled = false
            
            //Affichage de l'indicateur de chargement réseau
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Permet de récupérer la valeur de la vue suivante
    func writeValueBack(value: String) {
        currentMode = value
        ui_tableViewCellModeChoice.detailTextLabel!.text = currentMode
        self.navigationItem.rightBarButtonItem!.isEnabled = true
    }
    
    @IBAction func textFieldDownloadNormalEditChanged(_ sender: UITextField) {
        //Activation du bouton save
        self.navigationItem.rightBarButtonItem!.isEnabled = true
    }
    
    @IBAction func textFieldUploadNormalEditChanged(_ sender: UITextField) {
        //Activation du bouton save
        self.navigationItem.rightBarButtonItem!.isEnabled = true
    }
    
    @IBAction func textFieldDownloadSlowEditChanged(_ sender: UITextField) {
        //Activation du bouton save
        self.navigationItem.rightBarButtonItem!.isEnabled = true
    }
    
    @IBAction func textFieldUploadSlowEditChanged(_ sender: UITextField) {
        //Activation du bouton save
        self.navigationItem.rightBarButtonItem!.isEnabled = true
    }
    
    //Si une cellule est sélectionnée
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //Déselectionner la cellule avec une animation
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    //Segue pour passer l'objet à la vue suivante
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showMode" {
            let destination = segue.destination as! ChoiceModeTableViewController
            destination.cellSelected = currentMode
        }
    }
    
}
