//
//  HttpRequestFreebox.swift
//  freeboxDownloader
//
//  Created by Yohann Verdier on 26/10/2016.
//  Copyright © 2016 Yohann Verdier. All rights reserved.
//

import Foundation
import Alamofire

class HttpRequestFreebox {
    
    //TEST
    //Constante APP_TOKEN utile pour la sauvegarde dans les userdefaults
    //l'app_token est valable tant que l'utilisateur ne l'a pas révoqué dans les réglages du freebox server
    static let APP_TOKEN = "APP_TOKEN"
    
    static let IP_FREEBOXSERVER = "IP_FREEBOXSERVER"
    
    static let REMOTE_ACCESS = "REMOTE_ACCESS"
    
    static let REMOTE_ACCESS_PORT = "REMOTE_ACCESS_PORT"
    
    var urlFreebox:String = "mafreebox.freebox.fr"
    
    let URL_FREEBOX_LOCAL = "mafreebox.freebox.fr"
    
    let USER_DEFAULTS = UserDefaults.standard
    
    var nbTentative = 0
    
    
    //le challenge est nécessaire à la génération du mot de passe à partir de l'app_token
    //il change à chaque appel et à une durée limitée
    var challenge:String?
    
    var app_token:String?
    var track_id:Int?
    var ipServer:String?
    var portServer:Int?
    var password:String?
    var session_token:String = ""
    var status:String?
    
    var _connectionStatus:ConnectionStatus?
    
    var _connectionConfiguration:ConnectionConfiguration?
    
    var _downloadDetail:DownloadDetail?
    
    var _downloadListOnFreeboxServer:[DownloadDetail] = []
    
    var _diskListOnFreeboxServer:[DiskDetail] = []
    
    var _downloadConfiguration:DownloadConfiguration?
    
    //requête pour le requestAuthorization()
    let parametersAuth: Parameters = [
        "app_id": "fr.yohannver.cocoapods",
        "app_name": "Test App",
        "app_version": "0.0.0",
        "device_name": "Emulateur 7plus"
    ]
    
    func getLocalURLOrIP() {
        //return urlFreeboxLocal
        
        //ne fonctionne pas encore
        if let ip = ipServer,
            let port = portServer {
            print("------------------\(ip):\(port)------------------")
            urlFreebox = "\(ip):\(port)"
        } else {
            print("------------------\(URL_FREEBOX_LOCAL)------------------")
            urlFreebox = URL_FREEBOX_LOCAL
        }
    }
    
    //Récupération d'un app_token auprès du freebox server et attente de l'interaction de l'utilisateur sur l'écran LCD
    func requestAuthorization() {
        Alamofire.request("http://\(urlFreebox)/api/v3/login/authorize/", method: .post, parameters: parametersAuth, encoding: JSONEncoding.default).responseJSON { (response) in
            debugPrint(response)
            if response.result.isSuccess {
                if let json = response.result.value {
                    let reponse = json as! NSDictionary
                    let result = reponse["result"] as? NSDictionary
                    
                    if let res = result {
                        //récupération du app_token
                        let app = res["app_token"]
                        if let app_token_temp = app {
                            print("app_token_temp : \(app_token_temp)")
                            self.app_token = app_token_temp as? String
                            print("app_token : \(self.app_token)")
                        }
                        
                        //récupération du track_id
                        let track = res["track_id"]
                        if let track_id_temp = track {
                            print("track_id_temp : \(track_id_temp)")
                            self.track_id = track_id_temp as? Int
                            print("track_id : \(self.track_id)")
                        }
                        
                        //Attente de l'interaction de l'utilisateur sur l'écran LCD du freebox server
                        self.trackAuthorizationProgress()
                    } else {
                        print("Erreur interne")
                    }
                }
            } else {
                print("Erreur : \(response.result.error)")
            }
        }
    }
    
    //Attente de l'interaction de l'utilisateur sur l'écran LCD du freebox server
    func trackAuthorizationProgress() {
        Alamofire.request("http://\(urlFreebox)/api/v3/login/authorize/\(track_id!)", method: .get, encoding: JSONEncoding.default).responseJSON { (response) in
            debugPrint(response)
            if response.result.isSuccess {
                if let json = response.result.value {
                    let reponse = json as! NSDictionary
                    let result = reponse["result"] as! NSDictionary
                    
                    //récupération du statut
                    let status = result["status"] as! String
                    print("--------------------")
                    print("Statut : \(status)")
                    print("--------------------")
                    self.status = status
                    switch status {
                    case "unknown":
                        //app_token invalide ou a été révoqué dans les réglages du freebox server
                        
                        
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "unknown"), object: nil)
                        
                        print("Téléphone révoqué!")
                    case "pending":
                        //l'utilisateur n'a pas confirmé l'autorisation sur l'écran LCD, rappel de la fonction trackAuthorizationProgress()
                        
                        //self.ui_labelConnexion.text = "Veuillez confirmer l'autorisation sur l'écran de la freebox"
                        //self.ui_buttonAppair.isEnabled = false
                        //self.ui_activityIndicator.isHidden = false
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "pending"), object: nil)
                        self.trackAuthorizationProgress()
                    case "timeout":
                        //l'utilisateur n'a pas confirmé l'autorisation sur l'écran LCD dans le temps imparti
                        
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "timeout"), object: nil)
                        print("Timeout!")
                    case "granted":
                        //l'utilisateur a accepté l'autorisation sur l'écran LCD
                        print("Accepté!")
                        //sauvegarde du app_token dans les userdefaults
                        self.USER_DEFAULTS.set(self.app_token!, forKey: HttpRequestFreebox.APP_TOKEN)
                        
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "granted"), object: nil)
                        //récupération du challenge
                        self.getChallenge(from: "authorization", downloadId: 0, priority: 0, ratio: 0, downConfig: nil, urlString: "", url : nil)
                    case "denied":
                        //l'utilisateur a refusé l'autorisation sur l'écran LCD
                        
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "denied"), object: nil)
                        print("Refusé!")
                    default:
                        //statut inconnu
                        print("Erreur lors du trackAuthorizationProgress")
                    }
                }
            } else {
                print("Erreur : \(response.result.error)")
            }
        }
    }
    
    //Récupération du challenge qui change à chaque appel et qui a une durée limitée
    func getChallenge(from:String, downloadId:Int, priority:Int, ratio:Double, downConfig:DownloadConfiguration?, urlString:String, url: URL?) {
        Alamofire.request("http://\(urlFreebox)/api/v3/login/", method: .get, encoding: JSONEncoding.default).responseJSON { (response) in
            print("-----début de getChallenge-----")
            debugPrint(response)
            if response.result.isSuccess {
                if let json = response.result.value {
                    let reponse = json as! NSDictionary
                    let result = reponse["result"] as! NSDictionary
                    
                    //récupération du challenge
                    let chall = result["challenge"] as! String
                    print("--------------------")
                    print("Challenge : \(chall)")
                    print("--------------------")
                    self.challenge = chall
                    
                    if let app_tok = self.app_token {
                        //ouverture d'une session
                        self.openSession(app_tok: app_tok,from: from, downloadId: downloadId, priority: priority, ratio: ratio, downConfig: downConfig, urlString: urlString, url: url)
                    } else {
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "openSplashScreen"), object: nil)
                    }
                }
            } else {
                print("Erreur : \(response.result.error)")
            }
            print("-----fin de getChallenge-----")
        }
    }
    
    //Ouverture d'une session auprès du freebox server
    func openSession(app_tok:String, from:String, downloadId:Int, priority:Int, ratio:Double, downConfig:DownloadConfiguration?, urlString:String, url: URL?) {
        //génération du mot de passe de session
        self.createPasswordSession(app_tok: app_tok)
        
        //création de la requête
        let parametersSession: Parameters = [
            "app_id": "fr.yohannver.cocoapods",
            "password": "\(self.password!)"
        ]
        
        print("-----début de openSession-----")
        
        
        
        Alamofire.request("http://\(urlFreebox)/api/v3/login/session/", method: .post, parameters: parametersSession, encoding: JSONEncoding.default).responseJSON { (response) in
            debugPrint(response)
            if response.result.isSuccess {
                if let json = response.result.value {
                    let reponse = json as! NSDictionary
                    print(reponse)
                    let result = reponse["result"] as! NSDictionary
                    
                    //récupération du session_token
                    let sess_tok = result["session_token"] as? String
                    
                    if let ses_to = sess_tok {
                        self.nbTentative = 0
                        
                        //session ouverte
                        print("--------------------")
                        print("Session_token : \(ses_to)")
                        print("--------------------")
                        self.session_token = ses_to
                        
                        if from == "authorization" {
                            self.getConnectionStatus()
                            self.getConnectionConfiguration()
                        } else if from == "listDownloads" {
                            self.getAllDownloads()
                        } else if from == "detailDownload" {
                            self.getDownloadById(id: downloadId)
                        } else if from == "deleteDownload" {
                            self.deleteDownloadById(id: downloadId)
                        } else if from == "stopDownload" {
                            self.stopDownloadById(id: downloadId)
                        } else if from == "resumeDownload" {
                            self.resumeDownloadById(id: downloadId)
                        } else if from == "listDisks" {
                            self.getListOfDisks()
                        } else if from == "changePriority" {
                            self.changePriorityForDownload(id: downloadId, priority: priority)
                        } else if from == "changeRatio" {
                            self.changeRatioForBittorrentDownload(id: downloadId, ratio: ratio)
                        } else if from == "downloadConfiguration" {
                            self.getCurrentDownloadConfiguration()
                        } else if from == "updateDownloadConfiguration" {
                            self.updateDownloadConfiguration(downConfig: downConfig)
                        } else if from == "addSingleDownloadUrl" {
                            self.addSingleDownloadByURL(url: urlString)
                        } else if from == "addDownloadByFileUploading" {
                            self.addDownloadByFileUploading(fileUrl: url)
                        }
                        
                        
                    } else {
                        //session non ouverte,
                        let error_code = reponse["error_code"]  as! String
                        print("--------------------")
                        print("Error code : \(error_code)")
                        print("--------------------")
                        
                        self.nbTentative = self.nbTentative + 1
                        
                        if self.nbTentative < 4 {
                            print("Tentative de reconnexion : \(self.nbTentative)")
                            self.getChallenge(from: from, downloadId: downloadId, priority: priority, ratio: ratio, downConfig: downConfig, urlString: urlString, url: url)
                        } else {
                            //Si les 3 tentatives de reconnexion ont échoué
                            self.nbTentative = 0
                            //suppression de l'app_token des userdefaults car il a été révoqué
                            self.USER_DEFAULTS.removeObject(forKey: HttpRequestFreebox.APP_TOKEN)
                            self.USER_DEFAULTS.removeObject(forKey: HttpRequestFreebox.IP_FREEBOXSERVER)
                            self.USER_DEFAULTS.removeObject(forKey: HttpRequestFreebox.REMOTE_ACCESS_PORT)
                            
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "openSplashScreen"), object: nil)
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "openSplashScreen2"), object: nil)
                        }
                    }
                    
                    print("-----fin de openSession-----")
                }
            } else {
                print("Erreur : \(response.result.error)")
            }
        }
    }
    
    //Liste les téléchargements du freebox server
    func getConnectionStatus() {
        let headers: HTTPHeaders = [
            "X-Fbx-App-Auth": "\(self.session_token)"
        ]
        
        print("-----début de getConnectionStatus-----")
        
        Alamofire.request("http://\(urlFreebox)/api/v3/connection/", method: .get, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            debugPrint(response)
            if response.result.isSuccess {
                if let json = response.result.value {
                    let results = json as! NSDictionary
                    let connectStatusRes = results["result"] as! [String:AnyObject]
                    
                    let ipv4 = connectStatusRes["ipv4"] as? String
                    let ipv6 = connectStatusRes["ipv6"] as? String
                    let state = connectStatusRes["state"] as? String
                    
                    self._connectionStatus = ConnectionStatus(ip4: ipv4, ip6: ipv6, state: state)
                    if let ip4 = ipv4 {
                        self.USER_DEFAULTS.set(ip4, forKey: HttpRequestFreebox.IP_FREEBOXSERVER)
                    }
                    
                    print("-----fin de getConnectionStatus-----")
                }
            } else {
                print("Erreur : \(response.result.error)")
            }
        }
    }
    
    //Récupère la configuration de la connexion
    func getConnectionConfiguration() {
        let headers: HTTPHeaders = [
            "X-Fbx-App-Auth": "\(self.session_token)"
        ]
        
        print("-----début de getConnectionConfiguration-----")
        
        Alamofire.request("http://\(urlFreebox)/api/v3/connection/config/", method: .get, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            debugPrint(response)
            if response.result.isSuccess {
                if let json = response.result.value {
                    let results = json as! NSDictionary
                    let connectStatusRes = results["result"] as! [String:AnyObject]
                    
                    let remote_access = connectStatusRes["remote_access"] as? Bool
                    let remote_access_port = connectStatusRes["remote_access_port"] as? Int
                    
                    self._connectionConfiguration = ConnectionConfiguration(remote_access_port: remote_access_port, remote_access: remote_access)
                    if let remoteaccess = remote_access {
                        self.USER_DEFAULTS.set(remoteaccess, forKey: HttpRequestFreebox.REMOTE_ACCESS)
                    }
                    
                    if let remoteaccessport = remote_access_port {
                        self.USER_DEFAULTS.set(remoteaccessport, forKey: HttpRequestFreebox.REMOTE_ACCESS_PORT)
                    }
                    
                    print("-----fin de getConnectionConfiguration-----")
                }
            } else {
                print("Erreur : \(response.result.error)")
            }
        }
    }
    
    //Liste les téléchargements du freebox server
    func getAllDownloads() {
        
        let headers: HTTPHeaders = [
            "X-Fbx-App-Auth": "\(self.session_token)"
        ]
        
        print("-----début de getAllDownloads-----")
        
        Alamofire.request("http://\(urlFreebox)/api/v3/downloads/", method: .get, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            debugPrint(response)
            if response.result.isSuccess {
                if let json = response.result.value {
                    let results = json as! NSDictionary
                    let listDownload = results["result"] as? [[String:AnyObject]]
                    let success = results["success"] as? Bool
                    
                    if let succes = success {
                        
                        if succes {
                            self._downloadListOnFreeboxServer.removeAll()
                            
                            if let listDown = listDownload {
                                for download in listDown {
                                    let rx_bytes = download["rx_bytes"] as! Double
                                    let tx_bytes = download["tx_bytes"] as! Double
                                    let archive_password = download["archive_password"] as! String
                                    let eta = download["eta"] as! Int
                                    let io_priority = download["io_priority"] as! String
                                    let type = download["type"] as! String
                                    let error = download["error"] as! String
                                    let queue_pos = download["queue_pos"] as! Int
                                    let created_ts = download["created_ts"] as! Int
                                    let tx_rate = download["tx_rate"] as! Double
                                    let rx_pct = download["rx_pct"] as! Double
                                    let rx_rate = download["rx_rate"] as! Double
                                    let tx_pct = download["tx_pct"] as! Double
                                    let name = download["name"] as! String
                                    let down_dir = download["download_dir"] as! String
                                    let size = download["size"] as! Double
                                    let status = download["status"] as! String
                                    let id = download["id"] as! Int
                                    let ratio = download["stop_ratio"] as! Double
                                    
                                    self._downloadListOnFreeboxServer.append(DownloadDetail(name: name, downDir: down_dir, size: size, status: status, id: id, rx_bytes: rx_bytes, tx_bytes: tx_bytes, archive_password: archive_password, eta: eta, io_priority: io_priority, type: type, error: error, queue_pos: queue_pos, created_ts: created_ts, tx_rate: tx_rate, rx_pct: rx_pct, rx_rate: rx_rate, tx_pct: tx_pct, ratio: ratio))
                                }
                            }
                            //tri du tableau dans l'ordre décroissant
                            self._downloadListOnFreeboxServer.sort(by: { (elem1:DownloadDetail, elem2:DownloadDetail) -> Bool in
                                elem1.id! > elem2.id!
                            })
                            print("-----fin de getAllDownloads-----")
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "displayDownloadsList"), object: nil)
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "load"), object: nil)
                        } else {
                            print("Erreur d'authentification à la freebox (getAllDownloads)")
                            self.getChallenge(from: "listDownloads", downloadId: 0, priority: 0, ratio: 0, downConfig: nil, urlString: "", url: nil)
                        }
                    }
                }
            } else {
                print("Erreur : \(response.result.error)")
            }
        }
    }
    
    //Récupère un téléchargement du freebox server
    func getDownloadById(id:Int) {
        let headers: HTTPHeaders = [
            "X-Fbx-App-Auth": "\(self.session_token)"
        ]
        
        Alamofire.request("http://\(urlFreebox)/api/v3/downloads/\(id)", method: .get, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            debugPrint(response)
            if response.result.isSuccess {
                if let json = response.result.value {
                    let results = json as! NSDictionary
                    
                    let success = results["success"] as! Bool
                    
                    if success {
                        let download = results["result"] as! [String:AnyObject]
                        
                        let rx_bytes = download["rx_bytes"] as! Double
                        let tx_bytes = download["tx_bytes"] as! Double
                        let archive_password = download["archive_password"] as! String
                        let eta = download["eta"] as! Int
                        let io_priority = download["io_priority"] as! String
                        let type = download["type"] as! String
                        let error = download["error"] as! String
                        let queue_pos = download["queue_pos"] as! Int
                        let created_ts = download["created_ts"] as! Int
                        let tx_rate = download["tx_rate"] as! Double
                        let rx_pct = download["rx_pct"] as! Double
                        let rx_rate = download["rx_rate"] as! Double
                        let tx_pct = download["tx_pct"] as! Double
                        let name = download["name"] as! String
                        let down_dir = download["download_dir"] as! String
                        let size = download["size"] as! Double
                        let status = download["status"] as! String
                        let id = download["id"] as! Int
                        let ratio = download["stop_ratio"] as! Double
                        
                        self._downloadDetail = DownloadDetail(name: name, downDir: down_dir, size: size, status: status, id: id, rx_bytes: rx_bytes, tx_bytes: tx_bytes, archive_password: archive_password, eta: eta, io_priority: io_priority, type: type, error: error, queue_pos: queue_pos, created_ts: created_ts, tx_rate: tx_rate, rx_pct: rx_pct, rx_rate: rx_rate, tx_pct: tx_pct, ratio: ratio)
                        
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "detailDownload"), object: nil)
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "cellDownload"), object: nil)
                    } else {
                        print("Erreur d'authentification à la freebox (getDownloadById)")
                        self.getChallenge(from: "detailDownload", downloadId: id, priority: 0, ratio: 0, downConfig: nil, urlString: "", url: nil)
                    }
                }
            } else {
                print("Erreur : \(response.result.error)")
            }
        }
    }
    
    //Supprime un téléchargement du freebox server
    func deleteDownloadById(id:Int) {
        let headers: HTTPHeaders = [
            "X-Fbx-App-Auth": "\(self.session_token)"
        ]
        
        Alamofire.request("http://\(urlFreebox)/api/v3/downloads/\(id)/erase", method: .delete, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            debugPrint(response)
            if response.result.isSuccess {
                if let json = response.result.value {
                    let results = json as! NSDictionary
                    let downloadDeleted = results["success"] as! Bool
                    
                    if downloadDeleted {
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "downloadDeletedSuccess"), object: nil)
                    } else {
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "downloadDeletedFail"), object: nil)
                        print("Erreur d'authentification à la freebox (deleteDownloadById)")
                        self.getChallenge(from: "deleteDownload", downloadId: id, priority: 0, ratio: 0, downConfig: nil, urlString: "", url: nil)
                    }
                }
            } else {
                print("Erreur : \(response.result.error)")
            }
        }
    }
    
    //Arrête un téléchargement du freebox server
    func stopDownloadById(id:Int) {
        let headers: HTTPHeaders = [
            "X-Fbx-App-Auth": "\(self.session_token)"
        ]
        
        //création de la requête
        let param: Parameters = [
            "status": DownloadDetail.DownloadStatus.stopped.rawValue
        ]
        
        Alamofire.request("http://\(urlFreebox)/api/v3/downloads/\(id)", method: .put, parameters: param, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            debugPrint(response)
            if response.result.isSuccess {
                if let json = response.result.value {
                    let results = json as! NSDictionary
                    let downloadStopped = results["success"] as! Bool
                    
                    if downloadStopped {
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "downloadStoppedSuccess"), object: nil)
                    } else {
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "downloadStoppedFail"), object: nil)
                        print("Erreur d'authentification à la freebox (stopDownloadById)")
                        self.getChallenge(from: "stopDownload", downloadId: id, priority: 0, ratio: 0, downConfig: nil, urlString: "", url: nil)
                    }
                }
            } else {
                print("Erreur : \(response.result.error)")
            }
        }
    }
    
    //Reprend un téléchargement du freebox server
    func resumeDownloadById(id:Int) {
        let headers: HTTPHeaders = [
            "X-Fbx-App-Auth": "\(self.session_token)"
        ]
        
        //création de la requête
        let param: Parameters = [
            "status": DownloadDetail.DownloadStatus.downloading.rawValue
        ]
        
        Alamofire.request("http://\(urlFreebox)/api/v3/downloads/\(id)", method: .put, parameters: param, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            debugPrint(response)
            if response.result.isSuccess {
                if let json = response.result.value {
                    let results = json as! NSDictionary
                    let downloadResumed = results["success"] as! Bool
                    
                    if downloadResumed {
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "downloadResumedSuccess"), object: nil)
                    } else {
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "downloadResumedFail"), object: nil)
                        print("Erreur d'authentification à la freebox (resumeDownloadById)")
                        self.getChallenge(from: "resumeDownload", downloadId: id, priority: 0, ratio: 0, downConfig: nil, urlString: "", url: nil)
                    }
                }
            } else {
                print("Erreur : \(response.result.error)")
            }
        }
    }
    
    //Change la priorité d'un téléchargement du freebox server
    func changePriorityForDownload(id:Int, priority:Int) {
        let headers: HTTPHeaders = [
            "X-Fbx-App-Auth": "\(self.session_token)"
        ]
        
        var io_priority = ""
        
        if priority == 1 {
            io_priority = DownloadDetail.DownloadPriority.low.rawValue
        } else if priority == 2 {
            io_priority = DownloadDetail.DownloadPriority.normal.rawValue
        } else if priority == 3 {
            io_priority = DownloadDetail.DownloadPriority.high.rawValue
        }
        
        //création de la requête
        let param: Parameters = [
            "io_priority": io_priority
        ]
        
        Alamofire.request("http://\(urlFreebox)/api/v3/downloads/\(id)", method: .put, parameters: param, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            debugPrint(response)
            if response.result.isSuccess {
                if let json = response.result.value {
                    let results = json as! NSDictionary
                    let priorityChanged = results["success"] as! Bool
                    
                    if priorityChanged {
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "priorityChanged"), object: nil)
                    } else {
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "priorityChangedFailed"), object: nil)
                        print("Erreur d'authentification à la freebox (changePriorityForDownload)")
                        self.getChallenge(from: "changePriority", downloadId: id, priority: priority, ratio: 0, downConfig: nil, urlString: "", url: nil)
                    }
                }
            } else {
                print("Erreur : \(response.result.error)")
            }
        }
    }
    
    //Change le ratio d'un téléchargement bittorent du freebox server
    func changeRatioForBittorrentDownload(id:Int, ratio:Double) {
        let headers: HTTPHeaders = [
            "X-Fbx-App-Auth": "\(self.session_token)"
        ]
        
        //création de la requête
        let param: Parameters = [
            "stop_ratio": ratio*100
        ]
        
        Alamofire.request("http://\(urlFreebox)/api/v3/downloads/\(id)", method: .put, parameters: param, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            debugPrint(response)
            if response.result.isSuccess {
                if let json = response.result.value {
                    let results = json as! NSDictionary
                    let ratioChanged = results["success"] as! Bool
                    
                    if ratioChanged {
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ratioChanged"), object: nil)
                    } else {
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ratioChangedFailed"), object: nil)
                        print("Erreur d'authentification à la freebox (changeRatioForBittorrentDownload)")
                        self.getChallenge(from: "changeRatio", downloadId: id, priority: 0, ratio: ratio, downConfig: nil, urlString: "", url: nil)
                    }
                }
            } else {
                print("Erreur : \(response.result.error)")
            }
        }
    }
    
    //Ajout d'un téléchargement par l'URL
    func addSingleDownloadByURL(url: String) {
        //création de la requête
        let parametersDownload: Parameters = [
            "download_url": url
        ]
        
        let headers: HTTPHeaders = [
            "X-Fbx-App-Auth": "\(self.session_token)"
        ]
        
        Alamofire.request("http://\(urlFreebox)/api/v3/downloads/add", method: .post, parameters: parametersDownload, headers: headers).responseJSON { (response) in
            debugPrint(response)
            if response.result.isSuccess {
                if let json = response.result.value {
                    let reponse = json as! NSDictionary
                    print(reponse)
                    //let result = reponse["result"] as! NSDictionary
                    
                    //récupération du session_token
                    let successDown = reponse["success"] as! Bool
                    
                    if successDown {
                        //ajout du download
                        print("--------------------")
                        print("Ajout du download : \(successDown)")
                        print("--------------------")
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "addDownloadSuccess"), object: nil)
                    } else {
                        let error_code = reponse["error_code"] as! String
                        if error_code == "auth_required" {
                            self.getChallenge(from: "addSingleDownloadUrl", downloadId: 0, priority: 0, ratio: 0, downConfig: nil, urlString: url, url: nil)
                        }
                    }
                }
            } else {
                print("Erreur : \(response.result.error)")
            }
        }
    }
    
    //Ajout d'un téléchargement par upload de fichier
    func addDownloadByFileUploading(fileUrl: URL?) {
        
        let headers: HTTPHeaders = [
            "X-Fbx-App-Auth": "\(self.session_token)"
        ]
        
        //let fileURL = Bundle.main.url(forResource: "fichier", withExtension: "torrent", subdirectory: "Documents")
        
        Alamofire.upload(
            multipartFormData: { multipartFormData in
                multipartFormData.append(fileUrl!, withName: "download_file")
        },
            to: "http://\(urlFreebox)/api/v3/downloads/add",
            method: .post,
            headers: headers,
            encodingCompletion: { encodingResult in
                switch encodingResult {
                case .success(let upload, _, _):
                    upload.responseJSON { response in
                        debugPrint(response)
                        if let json = response.result.value {
                            let reponse = json as! NSDictionary
                            let success = reponse["success"] as! Bool
                            
                            if success {
                                print("SUCCES")
                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "addDownloadSuccess"), object: nil)
                            } else {
                                let error_code = reponse["error_code"] as! String
                                if error_code == "auth_required" {
                                    self.getChallenge(from: "addDownloadByFileUploading", downloadId: 0, priority: 0, ratio: 0, downConfig: nil, urlString: "", url: fileUrl!)
                                }
                            }
                        }
                    }
                case .failure(let encodingError):
                    print(encodingError)
                    print("ERROR")
                }
        }
        )
    }
    
    //Liste des disques du freebox server
    func getListOfDisks() {
        let headers: HTTPHeaders = [
            "X-Fbx-App-Auth": "\(self.session_token)"
        ]
        
        print("-----début de getListOfDisks-----")
        
        Alamofire.request("http://\(urlFreebox)/api/v3/storage/disk/", method: .get, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            debugPrint(response)
            if response.result.isSuccess {
                if let json = response.result.value {
                    let results = json as! NSDictionary
                    let listDisksOpt = results["result"] as? [[String:AnyObject]]
                    let success = results["success"] as? Bool
                    
                    if let succes = success {
                        
                        if succes {
                            
                            if let listDisks = listDisksOpt {
                                for disk in listDisks {
                                    let type = disk["type"] as! String
                                    let state = disk["state"] as! String
                                    let total_bytes = disk["total_bytes"] as! Double
                                    let listPartitionsOpt = disk["partitions"] as? [[String:AnyObject]]
                                    
                                    var listPartitionsFinal:[PartitionDetail] = []
                                    
                                    if let listPartitions = listPartitionsOpt {
                                        listPartitionsFinal.removeAll()
                                        for partition in listPartitions {
                                            let total_bytes = partition["total_bytes"] as! Double
                                            let label = partition["label"] as! String
                                            let statePart = partition["state"] as! String
                                            let free_bytes = partition["free_bytes"] as! Double
                                            let used_bytes = partition["used_bytes"] as! Double
                                            let path = partition["path"] as! String
                                            
                                            listPartitionsFinal.append(PartitionDetail(total_bytes: total_bytes, label: label, statePart: statePart, free_bytes: free_bytes, used_bytes: used_bytes, path: path))
                                        }
                                    }
                                    
                                    self._diskListOnFreeboxServer.append(DiskDetail(type: type, state: state, total_bytes: total_bytes, listPartitions: listPartitionsFinal))
                                }
                            }
                            print("-----fin de getListOfDisks-----")
                            //NotificationCenter.default.post(name: NSNotification.Name(rawValue: "displayButtonDownloads"), object: nil)
                            //NotificationCenter.default.post(name: NSNotification.Name(rawValue: "load"), object: nil)
                        } else {
                            print("Erreur d'authentification à la freebox (getListOfDisks)")
                            self.getChallenge(from: "listDisks", downloadId: 0, priority: 0, ratio: 0, downConfig: nil, urlString: "", url: nil)
                        }
                    }
                }
            } else {
                print("Erreur : \(response.result.error)")
            }
        }
    }
    
    //Configuration des téléchargements du freebox server
    func getCurrentDownloadConfiguration() {
        let headers: HTTPHeaders = [
            "X-Fbx-App-Auth": "\(self.session_token)"
        ]
        
        print("-----début de getCurrentDownloadConfiguration-----")
        
        Alamofire.request("http://\(urlFreebox)/api/v3/downloads/config/", method: .get, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            debugPrint(response)
            if response.result.isSuccess {
                if let json = response.result.value {
                    let results = json as! NSDictionary
                    let listConfigurationOpt = results["result"] as? NSDictionary
                    let success = results["success"] as? Bool
                    
                    if let succes = success {
                        
                        if succes {
                            
                            if let listConfiguration = listConfigurationOpt {
                                
                                //BLOCKLIST
                                var dlBlockListConfig:DlBlockListConfig?
                                let blocklistOpt = listConfiguration["blocklist"] as? [String:AnyObject]
                                if let blocklist = blocklistOpt {
                                    let sources = blocklist["sources"] as? [String]
                                    
                                    dlBlockListConfig = DlBlockListConfig(sources: sources)
                                }
                                
                                //FEED
                                var dlFeedConfig:DlFeedConfig?
                                let feedOpt = listConfiguration["feed"] as? [String:AnyObject]
                                if let feed = feedOpt {
                                    let max_items = feed["max_items"] as? Int
                                    let fetch_interval = feed["fetch_interval"] as? Int
                                    
                                    dlFeedConfig = DlFeedConfig(fetch_interval: fetch_interval, max_items: max_items)
                                }
                                
                                //NEWS
                                var dlNewsConfig:DlNewsConfig?
                                let newsOpt = listConfiguration["news"] as? [String:AnyObject]
                                if let news = newsOpt {
                                    let user = news["user"] as? String
                                    let erase_tmp = news["erase_tmp"] as? Bool
                                    let port = news["port"] as? Int
                                    let nthreads = news["nthreads"] as? Int
                                    let auto_repair = news["auto_repair"] as? Bool
                                    let ssl = news["ssl"] as? Bool
                                    let auto_extract = news["auto_extract"] as? Bool
                                    let lazy_par2 = news["lazy_par2"] as? Bool
                                    let server = news["server"] as? String
                                    let password = news["password"] as? String
                                    
                                    dlNewsConfig = DlNewsConfig(server: server, port: port, ssl: ssl, user: user, password: password, nthreads: nthreads, auto_repair: auto_repair, lazy_par2: lazy_par2, auto_extract: auto_extract, erase_tmp: erase_tmp)
                                }
                                
                                //BITTORRENT
                                var dlBtConfig:DlBtConfig?
                                let btOpt = listConfiguration["bt"] as? [String:AnyObject]
                                if let bt = btOpt {
                                    let max_peers = bt["max_peers"] as? Int
                                    let stop_ratio = bt["stop_ratio"] as? Int
                                    let crypto_support = bt["crypto_support"] as? String
                                    let enable_pex = bt["enable_pex"] as? Bool
                                    let announce_timeout = bt["announce_timeout"] as? Int
                                    let main_port = bt["main_port"] as? Int
                                    let dht_port = bt["dht_port"] as? Int
                                    let enable_dht = bt["enable_dht"] as? Bool
                                    
                                    
                                    dlBtConfig = DlBtConfig(max_peers: max_peers, stop_ratio: stop_ratio, crypto_support: crypto_support, enable_dht: enable_dht, enable_pex: enable_pex, announce_timeout: announce_timeout, main_port: main_port, dht_port: dht_port)
                                }
                                
                                //THROTTLING
                                var dlThrottlingConfig:DlThrottlingConfig?
                                let throttlingOpt = listConfiguration["throttling"] as? [String:AnyObject]
                                if let throttling = throttlingOpt {
                                    
                                    var normalDlRate:DlRate?
                                    let normalOpt = throttling["normal"] as? [String:AnyObject]
                                    if let normal = normalOpt {
                                        let rx_rate = normal["rx_rate"] as? Int
                                        let tx_rate = normal["tx_rate"] as? Int
                                        
                                        normalDlRate = DlRate(tx_rate: tx_rate, rx_rate: rx_rate)
                                    }
                                    
                                    var slowDlRate:DlRate?
                                    let slowOpt = throttling["slow"] as? [String:AnyObject]
                                    if let slow = slowOpt {
                                        let rx_rate = slow["rx_rate"] as? Int
                                        let tx_rate = slow["tx_rate"] as? Int
                                        
                                        slowDlRate = DlRate(tx_rate: tx_rate, rx_rate: rx_rate)
                                    }
                                    
                                    let scheduleOpt = throttling["schedule"] as? [String]
                                    let mode = throttling["mode"] as? String
                                    
                                    dlThrottlingConfig = DlThrottlingConfig(normal: normalDlRate, slow: slowDlRate, schedule: scheduleOpt, mode: mode)
                                }
                                
                                let use_watch_dir = listConfiguration["use_watch_dir"] as? Bool
                                let watch_dir = listConfiguration["watch_dir"] as? String
                                let max_downloading_tasks = listConfiguration["max_downloading_tasks"] as? Int
                                let download_dir = listConfiguration["download_dir"] as? String
                                
                                self._downloadConfiguration = DownloadConfiguration(max_downloading_tasks: max_downloading_tasks, download_dir: download_dir, watch_dir: watch_dir, use_watch_dir: use_watch_dir, throttling: dlThrottlingConfig, news: dlNewsConfig, bt: dlBtConfig, feed: dlFeedConfig, blockList: dlBlockListConfig)
                            }
                            print("-----fin de getCurrentDownloadConfiguration-----")
                            //NotificationCenter.default.post(name: NSNotification.Name(rawValue: "displayButtonDownloads"), object: nil)
                            //NotificationCenter.default.post(name: NSNotification.Name(rawValue: "load"), object: nil)
                        } else {
                            print("Erreur d'authentification à la freebox (getCurrentDownloadConfiguration)")
                            self.getChallenge(from: "downloadConfiguration", downloadId: 0, priority: 0, ratio: 0, downConfig: nil, urlString: "", url: nil)
                        }
                    }
                }
            } else {
                print("Erreur : \(response.result.error)")
            }
        }
    }
    
    //Met à jour la configuration des téléchargements
    func updateDownloadConfiguration(downConfig:DownloadConfiguration?) {
        let headers: HTTPHeaders = [
            "X-Fbx-App-Auth": "\(self.session_token)"
        ]
        
        //Création de la requête
        let param: Parameters = createRequestDownloadConfiguration(downConfig: downConfig)
        
        print("-----début de updateDownloadConfiguration-----")
        
        Alamofire.request("http://\(urlFreebox)/api/v3/downloads/config/", method: .put, parameters: param, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            debugPrint(response)
            if response.result.isSuccess {
                if let json = response.result.value {
                    
                    let results = json as! NSDictionary
                    let downloadResumed = results["success"] as! Bool
                    
                    
                    if downloadResumed {
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "updateDownloadConfigurationSuccess"), object: nil)
                    } else {
                        let error_code = results["error_code"] as! String
                        if error_code == "auth_required" {
                            print("Erreur d'authentification à la freebox (updateDownloadConfiguration)")
                            self.getChallenge(from: "updateDownloadConfiguration", downloadId: 0, priority: 0, ratio: 0, downConfig: downConfig, urlString: "", url: nil)
                        } else {
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "updateDownloadConfigurationFail"), object: nil)
                        }
                    }
                    print("-----fin de updateDownloadConfiguration-----")
                }
            } else {
                print("Erreur : \(response.result.error)")
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "updateDownloadConfigurationFail"), object: nil)
            }
        }
    }
    
    //Création de la requête pour la mise à jour de la configuration des téléchargements
    func createRequestDownloadConfiguration(downConfig:DownloadConfiguration?) -> Parameters {
        
        var bt: Parameters = Parameters()
        var feed: Parameters = Parameters()
        var news: Parameters = Parameters()
        var blocklist: Parameters = Parameters()
        var normalParam: Parameters = Parameters()
        var slowParam: Parameters = Parameters()
        var throttling: Parameters = Parameters()
        
        var requete: Parameters = Parameters()
        
        if let downConf = downConfig {
            
            if let bittorrent = downConf.bt {
                
                if let announce_timeout = bittorrent.announce_timeout {
                    bt["announce_timeout"] = announce_timeout
                }
                if let crypto_support = bittorrent.crypto_support {
                    bt["crypto_support"] = crypto_support
                }
                if let dht_port = bittorrent.dht_port {
                    bt["dht_port"] = dht_port
                }
                if let enable_dht = bittorrent.enable_dht {
                    bt["enable_dht"] = enable_dht
                }
                if let enable_pex = bittorrent.enable_pex {
                    bt["enable_pex"] = enable_pex
                }
                if let main_port = bittorrent.main_port {
                    bt["main_port"] = main_port
                }
                if let max_peers = bittorrent.max_peers {
                    bt["max_peers"] = max_peers
                }
                if let stop_ratio = bittorrent.stop_ratio {
                    bt["stop_ratio"] = stop_ratio
                }
                
            }
            
            if let block = downConf.blockList {
                
                if let sources = block.sources {
                    blocklist["sources"] = sources
                }
                
            }
            
            if let feedNotOpt = downConf.feed {
                
                if let fetch_interval = feedNotOpt.fetch_interval {
                    feed["fetch_interval"] = fetch_interval
                }
                if let max_items = feedNotOpt.max_items {
                    feed["max_items"] = max_items
                }
                
            }
            
            if let newsNotOpt = downConf.news {
                
                if let auto_extract = newsNotOpt.auto_extract {
                    news["auto_extract"] = auto_extract
                }
                if let auto_repair = newsNotOpt.auto_repair {
                    news["auto_repair"] = auto_repair
                }
                if let erase_tmp = newsNotOpt.erase_tmp {
                    news["erase_tmp"] = erase_tmp
                }
                if let lazy_par2 = newsNotOpt.lazy_par2 {
                    news["lazy_par2"] = lazy_par2
                }
                if let nthreads = newsNotOpt.nthreads {
                    news["nthreads"] = nthreads
                }
                if let port = newsNotOpt.port {
                    news["port"] = port
                }
                if let server = newsNotOpt.server {
                    news["server"] = server
                }
                if let ssl = newsNotOpt.ssl {
                    news["ssl"] = ssl
                }
                if let user = newsNotOpt.user {
                    news["user"] = user
                }
                if let password = newsNotOpt.password {
                    news["password"] = password
                }
                
            }
            
            
            
            if let throttlingNotOpt = downConf.throttling {
                
                if let mode = throttlingNotOpt.mode {
                    throttling["mode"] = mode
                }
                if let normal = throttlingNotOpt.normal {
                    
                    if let rx_rate = normal.rx_rate {
                        normalParam["rx_rate"] = rx_rate
                    }
                    if let tx_rate = normal.tx_rate {
                        normalParam["tx_rate"] = tx_rate
                    }
                    
                    throttling["normal"] = normalParam
                    
                }
                if let slow = throttlingNotOpt.slow {
                    
                    if let rx_rate = slow.rx_rate {
                        slowParam["rx_rate"] = rx_rate
                    }
                    if let tx_rate = slow.tx_rate {
                        slowParam["tx_rate"] = tx_rate
                    }
                    
                    throttling["slow"] = slowParam
                    
                }
                if let schedule = throttlingNotOpt.schedule {
                    throttling["schedule"] = schedule
                }
                
            }
            
            if let max_downloading_tasks = downConf.max_downloading_tasks {
                requete["max_downloading_tasks"] = max_downloading_tasks
            }
            
            if let use_watch_dir = downConf.use_watch_dir {
                requete["use_watch_dir"] = use_watch_dir
            }
        }
        
        if !bt.isEmpty {
            requete["bt"] = bt
        }
        
        if !feed.isEmpty {
            requete["feed"] = feed
        }
        
        if !news.isEmpty {
            requete["news"] = news
        }
        
        if !blocklist.isEmpty {
            requete["blocklist"] = blocklist
        }
        
        if !throttling.isEmpty {
            requete["throttling"] = throttling
        }
        
        return requete
    }
    
    //Génération du mot de passe de session à partir de l'app_token et du challenge
    func createPasswordSession(app_tok:String) {
        self.password = challenge!.hmacHexa(algorithm: HMACAlgorithm.SHA1, key: app_tok)
        
        print("---------APP_TOKEN-----------")
        print("App_token : \(app_tok)")
        print("----------------------------")
        print("---------PASSWORD-----------")
        print("Password : \(self.password!)")
        print("----------------------------")
    }
}
