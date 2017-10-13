//
//  SplashScreenViewController.swift
//  freeboxDownloader
//
//  Created by Yohann Verdier on 24/10/2016.
//  Copyright © 2016 Yohann Verdier. All rights reserved.
//

import UIKit

class SplashScreenViewController: UIViewController {
    
    //Label de connexion
    @IBOutlet weak var ui_labelConnexion: UILabel!
    
    //Indicateur de chargement
    @IBOutlet weak var ui_activityIndicator: UIActivityIndicatorView!
    
    //Bouton d'appairage
    @IBOutlet weak var ui_buttonAppair: UIButton!
    
    //Bouton d'ouverture des téléchargements
    @IBOutlet weak var ui_openDownloads: UIButton!
    
    let USER_DEFAULTS = UserDefaults.standard
    
    var _httpRequestFreebox:HttpRequestFreebox = HttpRequestFreebox()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    //La vue va apparaitre
    override func viewWillAppear(_ animated: Bool) {
        
        //Récupération de l'app_token de la freeboxserver dans les userdefaults
        _httpRequestFreebox.app_token = USER_DEFAULTS.string(forKey: HttpRequestFreebox.APP_TOKEN)
        //Récupération de l'IP de la freeboxserver dans les userdefaults
        _httpRequestFreebox.ipServer = USER_DEFAULTS.string(forKey: HttpRequestFreebox.IP_FREEBOXSERVER)
        //Récupération le port de la freeboxserver dans les userdefaults
        _httpRequestFreebox.portServer = USER_DEFAULTS.integer(forKey: HttpRequestFreebox.REMOTE_ACCESS_PORT)
        _httpRequestFreebox.getLocalURLOrIP()
        
        self.ui_openDownloads.layer.cornerRadius = 10
        self.ui_buttonAppair.layer.cornerRadius = 10
        
        //Abonnement au centre de notification
        NotificationCenter.default.addObserver(self, selector: #selector(SplashScreenViewController.unknownStatus),name:NSNotification.Name(rawValue: "unknown"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SplashScreenViewController.pendingStatus),name:NSNotification.Name(rawValue: "pending"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SplashScreenViewController.timeOutStatus),name:NSNotification.Name(rawValue: "timeout"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SplashScreenViewController.grantedStatus),name:NSNotification.Name(rawValue: "granted"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SplashScreenViewController.deniedStatus),name:NSNotification.Name(rawValue: "denied"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SplashScreenViewController.openDownloadsList),name:NSNotification.Name(rawValue: "displayDownloadsList"), object: nil)
        
        if let app_tok = _httpRequestFreebox.app_token {
            //si il y a un app_token on se connecte et on récupère les téléchargements, la liste des disques et la configuration
            self.ui_labelConnexion.text = "Connexion en cours"
            ui_openDownloads.isEnabled = false
            ui_openDownloads.isHidden = true
            ui_activityIndicator.isHidden = false
            ui_labelConnexion.isHidden = false
            ui_buttonAppair.isHidden = true
            
            _httpRequestFreebox.getAllDownloads()
            _httpRequestFreebox.getListOfDisks()
            _httpRequestFreebox.getCurrentDownloadConfiguration()
            
        } else {
            //si il n'y a pas d'app_token dans les userdefaults on en demande à l'utilisateur de s'appairer
            self.ui_openDownloads.isEnabled = false
            self.ui_openDownloads.isHidden = true
            self.ui_labelConnexion.text = "Veuillez vous appairer"
            self.ui_labelConnexion.isHidden = false
            self.ui_buttonAppair.isEnabled = true
            self.ui_buttonAppair.isHidden = false
            self.ui_activityIndicator.isHidden = true
        }
    }
    
    //Lorsque la vue va apparaître
    override func viewWillDisappear(_ animated: Bool) {
        //Désabonnement du centre de notification
        NotificationCenter.default.removeObserver(self)
    }
    
    //Segue pour passer l'objet à la vue suivante
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDownloads" {
            
            let navController = segue.destination as! UINavigationController
            let viewController:DownloadsViewController = navController.topViewController as! DownloadsViewController
            
            viewController._downloadListToDisplay = _httpRequestFreebox._downloadListOnFreeboxServer
            viewController._diskListOnFreeboxServer = _httpRequestFreebox._diskListOnFreeboxServer
            viewController._downloadConfiguration = _httpRequestFreebox._downloadConfiguration
        }
    }
    
    //Clique sur bouton d'ouverture des téléchargements
    @IBAction func OpenListDownloads(_ sender: UIButton) {
        //Ouverture de la vue suivante
        self.performSegue(withIdentifier: "showDownloads", sender:self)
    }
    
    //Clique sur bouton d'appairage
    @IBAction func clickAppair(_ sender: UIButton) {
        _httpRequestFreebox.requestAuthorization()
    }
    
    //La freebox renvoie un statut inconnu lors de l'appairage
    func unknownStatus() {
        self.ui_labelConnexion.text = "Veuillez vous réappairer"
        self.ui_buttonAppair.isEnabled = true
        self.ui_activityIndicator.isHidden = true
    }
    
    //La freebox renvoie un time out lors de l'appairage
    func timeOutStatus() {
        self.ui_labelConnexion.text = "Délai dépassé, veuillez vous appairer"
        self.ui_buttonAppair.isEnabled = true
        self.ui_activityIndicator.isHidden = true
    }
    
    //La freebox attend lors de l'appairage
    func pendingStatus() {
        self.ui_labelConnexion.text = "Veuillez valider sur l'écran de la freebox"
        self.ui_buttonAppair.isEnabled = false
        self.ui_activityIndicator.isHidden = false
    }
    
    //La freebox renvoie un accord lors de l'appairage
    func grantedStatus() {
        self.ui_labelConnexion.text = "Appairage réussi, connexion à la freebox"
        self.ui_buttonAppair.isHidden = true
        self.ui_activityIndicator.isHidden = false
        self.ui_openDownloads.isEnabled = false
        
        _httpRequestFreebox.getAllDownloads()
        _httpRequestFreebox.getListOfDisks()
    }
    
    //La freebox renvoie un refus out lors de l'appairage
    func deniedStatus() {
        self.ui_labelConnexion.text = "Refus lors de l'appairage"
        self.ui_buttonAppair.isEnabled = true
        self.ui_activityIndicator.isHidden = true
        print("Denied")
    }
    
    //Affichage de la liste des téléchargements
    func openDownloadsList() {
        self.performSegue(withIdentifier: "showDownloads", sender:self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
