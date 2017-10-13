//
//  FeedsTableViewController.swift
//  freeboxDownloader
//
//  Created by Yohann Verdier on 12/11/2016.
//  Copyright © 2016 Yohann Verdier. All rights reserved.
//

import UIKit

class FeedsTableViewController: UITableViewController {
    
    @IBOutlet weak var ui_textFieldUpdatePeriod: UITextField!
    
    @IBOutlet weak var ui_textFieldMaxItems: UITextField!
    
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
            if let feeds = down.feed {
                if let fetch_interval = feeds.fetch_interval {
                    ui_textFieldUpdatePeriod.text = "\(fetch_interval)"
                }
                if let max_items = feeds.max_items {
                    ui_textFieldMaxItems.text = "\(max_items)"
                }
            }
        }
        
        let mySelector: Selector = #selector(FeedsTableViewController.clickSave)
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "checkmark"), style: UIBarButtonItemStyle.done, target: self, action: mySelector)
        
        self.navigationItem.rightBarButtonItem!.isEnabled = false
        
        self.navigationItem.title = "Flux RSS"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(FeedsTableViewController.openParameters),name:NSNotification.Name(rawValue: "updateDownloadConfigurationSuccess"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(FeedsTableViewController.errorAlert),name:NSNotification.Name(rawValue: "updateDownloadConfigurationFail"), object: nil)
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
        
        alertPopped = false
        
        if let downConf = _downloadConfiguration {
            if let feed = downConf.feed {
                
                //Période mise à jour
                if let valueTextField = ui_textFieldUpdatePeriod.text {
                    //si une valeur est renseignée
                    if valueTextField == "" {
                        //si aucune valeur n'est renseignée
                        let alert = UIAlertController(title: "Période de mise à jour", message: "Veuillez renseigner une valeur", preferredStyle: UIAlertControllerStyle.alert)
                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                        alertPopped = true
                    } else {
                        if let intValue = Int(valueTextField) {
                            //si la valeur renseignée est numérique
                            
                            if intValue < 10 {
                                let alert = UIAlertController(title: "Période de mise à jour", message: "La valeur doit être au minimum de 10", preferredStyle: UIAlertControllerStyle.alert)
                                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
                                self.present(alert, animated: true, completion: nil)
                                alertPopped = true
                            } else {
                                feed.fetch_interval = intValue
                            }
                            
                        } else {
                            //si la valeur renseignée n'est pas en numérique
                            let alert = UIAlertController(title: "Période de mise à jour", message: "Veuillez renseigner une valeur numérique", preferredStyle: UIAlertControllerStyle.alert)
                            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
                            self.present(alert, animated: true, completion: nil)
                            alertPopped = true
                        }
                    }
                    
                }
                
                //Nombre d'éléments à conserver
                if let valueTextField = ui_textFieldMaxItems.text {
                    //si une valeur est renseignée
                    if valueTextField == "" {
                        //si aucune valeur n'est renseignée
                        let alert = UIAlertController(title: "Nombre d'éléments à conserver", message: "Veuillez renseigner une valeur", preferredStyle: UIAlertControllerStyle.alert)
                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                        alertPopped = true
                    } else {
                        if let intValue = Int(valueTextField) {
                            //si la valeur renseignée est numérique
                            
                            if intValue < 10 || intValue > 150 {
                                let alert = UIAlertController(title: "Nombre d'éléments à conserver", message: "La valeur doit être comprise entre 10 et 150", preferredStyle: UIAlertControllerStyle.alert)
                                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil))
                                self.present(alert, animated: true, completion: nil)
                                alertPopped = true
                            } else {
                                feed.max_items = intValue
                            }
                            
                        } else {
                            //si la valeur renseignée n'est pas en numérique
                            let alert = UIAlertController(title: "Nombre d'éléments à conserver", message: "Veuillez renseigner une valeur numérique", preferredStyle: UIAlertControllerStyle.alert)
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func clickTextFieldUpdatePeriod(_ sender: UITextField) {
        self.navigationItem.rightBarButtonItem!.isEnabled = true
    }
    
    @IBAction func clickTextFieldMaxItems(_ sender: UITextField) {
        self.navigationItem.rightBarButtonItem!.isEnabled = true
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}
