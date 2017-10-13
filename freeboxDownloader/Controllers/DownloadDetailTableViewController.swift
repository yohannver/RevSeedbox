//
//  DownloadDetailTableViewController.swift
//  freeboxDownloader
//
//  Created by Yohann Verdier on 27/10/2016.
//  Copyright © 2016 Yohann Verdier. All rights reserved.
//

import UIKit
import UserNotifications

class DownloadDetailTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var ui_tableView: UITableView!
    
    var _downloadDetail:DownloadDetail?
    var listDetail:[[String:String]] = [[String: String]]()
    var _timer:Timer?
    var notificationAlreadyDone = false
    var isBitTorrent = false
    
    var _httpRequestFreebox:HttpRequestFreebox = HttpRequestFreebox()
    
    let USER_DEFAULTS = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        _httpRequestFreebox.app_token = USER_DEFAULTS.string(forKey: HttpRequestFreebox.APP_TOKEN)
        
        //Récupération de l'IP de la freeboxserver dans les userdefaults
        _httpRequestFreebox.ipServer = USER_DEFAULTS.string(forKey: HttpRequestFreebox.IP_FREEBOXSERVER)
        //Récupération le port de la freeboxserver dans les userdefaults
        _httpRequestFreebox.portServer = USER_DEFAULTS.integer(forKey: HttpRequestFreebox.REMOTE_ACCESS_PORT)
        
        _httpRequestFreebox.getLocalURLOrIP()
        
        
        
        //par défaut le bouton des notifications est grisé
        //ui_buttonNotification.isEnabled = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        _timer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(DownloadDetailTableViewController.getDetailDownload), userInfo: nil, repeats: true)
        NotificationCenter.default.addObserver(self, selector: #selector(DownloadDetailTableViewController.notifDetailDownload),name:NSNotification.Name(rawValue: "detailDownload"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(DownloadDetailTableViewController.openSplashScreen),name:NSNotification.Name(rawValue: "openSplashScreen2"), object: nil)
        
        //getNotificationActivationFromUserDefaults()
        //changeButtonNotificationNameAndEnabling()
        
        self.navigationItem.title = "Détails"
        
        if let download = _downloadDetail {
            if download.type == DownloadDetail.DownloadType.bt.rawValue {
                isBitTorrent = true
            }
        }
        createListDetail()
    }
    
    //Récupération dans les userdefaults, pour le téléchargement, si l'utilisateur a choisi d'être averti
    //Si c'est le cas et que le téléchargement est actif alors on renseigne l'objet DownloadDetail
    //Sinon on supprime des userdefaults la valeur. L'objet n'a pas besoin d'être renseigné car par défault il est à false
    func getNotificationActivationFromUserDefaults() {
        if let download = _downloadDetail {
            let userDefaultNotificationActivated = self.USER_DEFAULTS.bool(forKey: download.name!)
            print("userDefaultNotificationActivated : \(userDefaultNotificationActivated)")
            //si il a choisi d'être averti et que le téléchargement est toujours actif
            if userDefaultNotificationActivated {
                if let status = download.status {
                    if status == DownloadDetail.DownloadStatus.downloading.rawValue {
                        download.notificationActivated = userDefaultNotificationActivated
                    } else {
                        //le téléchargement n'est plus actif, le système supprime la notification des userdefaults
                        self.USER_DEFAULTS.removeObject(forKey: download.name!)
                    }
                }
            }
        }
    }
    
    //Changement du texte du bouton et grisage en fonction de ce que l'utilisateur a choisi
    /*func changeButtonNotificationNameAndEnabling() {
     
     ui_buttonNotification.title = "M'alerter"
     
     if let download = _downloadDetail {
     if let status = download.status {
     //Si le téléchargement est en cours
     if status == DownloadDetail.DownloadStatus.downloading.rawValue {
     ui_buttonNotification.isEnabled = true
     if download.notificationActivated {
     ui_buttonNotification.title = "Arrêter alerte"
     }
     } else {
     ui_buttonNotification.isEnabled = false
     }
     }
     }
     }*/
    
    //Clique de l'utilisateur sur le bouton pour la programmation d'une notification
    func clickForNotification(_ sender: UIBarButtonItem) {
        if let download = _downloadDetail {
            if download.notificationActivated {
                download.notificationActivated = false
                self.USER_DEFAULTS.removeObject(forKey: download.name!)
                print("Notification active \(download.name!) : faux")
            } else {
                download.notificationActivated = true
                self.USER_DEFAULTS.set(true, forKey: download.name!)
                print("Notification active \(download.name!) : vrai")
            }
        }
        
        //changeButtonNotificationNameAndEnabling()
    }
    
    //Programmation d'une notification
    func scheduleNotification(inSeconds: TimeInterval, completion: @escaping (_ succes: Bool) -> ()) {
        let content = UNMutableNotificationContent()
        content.title = "Téléchargement terminé"
        //content.subtitle =
        content.body = "Le téléchargement de \(_downloadDetail!.name!) vient de se terminer"
        content.badge = 1
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: inSeconds, repeats: false)
        
        let request = UNNotificationRequest(identifier: "notifDownload", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: { error in
            if error != nil {
                print(error)
                completion(false)
            } else {
                completion(true)
            }
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if let timer = _timer {
            timer.invalidate()
            _timer = nil
        }
        NotificationCenter.default.removeObserver(self)
    }
    
    func openSplashScreen() {
        dismiss(animated: true, completion: nil)
    }
    
    func notifDetailDownload() {
        var notifActivated = false
        if let download = _downloadDetail {
            notifActivated = download.notificationActivated
        }
        _downloadDetail = nil
        _downloadDetail = _httpRequestFreebox._downloadDetail
        
        if let newDownloadDetail = _httpRequestFreebox._downloadDetail {
            newDownloadDetail.notificationActivated = notifActivated
        }
        
        createListDetail()
        self.ui_tableView.reloadData()
        
        if let download = _downloadDetail {
            //Si l'utilisateur a demandé à être averti et que cela n'a pas déjà été fait
            if download.notificationActivated && !notificationAlreadyDone {
                if let status = download.status {
                    //Si le téléchargement est en seed ou s'est terminé
                    if status == DownloadDetail.DownloadStatus.seeding.rawValue || status == DownloadDetail.DownloadStatus.done.rawValue {
                        //Déclenchement de la notification
                        scheduleNotification(inSeconds: 1, completion: { succes in
                            if succes {
                                print("Successfuly scheduled notification")
                                self.notificationAlreadyDone = true
                            } else {
                                print("Error scheduling notification")
                            }
                        })
                    }
                }
            }
        }
        
        if self.notificationAlreadyDone {
            getNotificationActivationFromUserDefaults()
            //changeButtonNotificationNameAndEnabling()
        }
    }
    
    func getDetailDownload() {
        _httpRequestFreebox.getDownloadById(id: _downloadDetail!.id!)
    }
    
    //Alimentation d'un dictionnaire à partir du contenu de la classe DownloadDetail
    func createListDetail() {
        listDetail.removeAll()
        if let detail = _downloadDetail {
            if let name = detail.name {
                
                listDetail.append(["Nom":String(name)])
                
            }
            if let size = detail.size {
                
                listDetail.append(["Taille totale":"\(detail.getMoOrGo(size))"])
                
            }
            if let rx_bytes = detail.rx_bytes {
                
                listDetail.append(["Reçu":String(detail.getMoOrGo(rx_bytes))])
                
            }
            if let tx_bytes = detail.tx_bytes {
                
                listDetail.append(["Transmis":String(detail.getMoOrGo(tx_bytes))])
                
            }
            if let download_dir = detail.download_dir {
                
                
                let decodedData = Data(base64Encoded: String(download_dir), options: NSData.Base64DecodingOptions.init(rawValue: 0))
                let decodedString = String(data: decodedData!, encoding: String.Encoding.utf8)
                listDetail.append(["Répertoire":decodedString!])
                
            }
            if let archive_password = detail.archive_password {
                
                if !archive_password.isEmpty {
                    listDetail.append(["Mot de passe archive":String(archive_password)])
                }
                
            }
            if let eta = detail.eta {
                let (h, m, s) = detail.secondsToHoursMinutesSeconds(seconds: eta)
                if h == 0 && m == 0 && s == 0 {
                    listDetail.append(["Temps restant":"--"])
                } else {
                    if h == 0 {
                        listDetail.append(["Temps restant":"\(String(m)) min \(String(s)) s"])
                    } else {
                        listDetail.append(["Temps restant":"\(String(h)) h \(String(m)) min \(String(s)) s"])
                    }
                }
                
            }
            if let tx_rate = detail.tx_rate {
                
                if tx_rate == 0.0 {
                    listDetail.append(["Débit sortant":"--"])
                } else {
                    listDetail.append(["Débit sortant":"\(detail.getOcSKoSOrMoS(tx_rate))"])
                }
                
            }
            if let rx_rate = detail.rx_rate {
                
                if rx_rate == 0.0 {
                    listDetail.append(["Débit entrant":"--"])
                } else {
                    listDetail.append(["Débit entrant":"\(detail.getOcSKoSOrMoS(rx_rate))"])
                }
                
                
            }
            if let rx_pct = detail.rx_pct {
                
                listDetail.append(["Avancement":"\(String(rx_pct/100)) %"])
                
            }
            if let status = detail.status {
                
                listDetail.append(["Statut":String(detail.convertFrStatus(status: status))])
                
            }
            if let io_priority = detail.io_priority {
                
                listDetail.append(["Priorité":String(detail.convertFrPriority(priority: io_priority))])
                
            }
            if let type = detail.type {
                
                listDetail.append(["Type":String(detail.convertFrType(type: type))])
                
            }
            if let error = detail.error {
                if error != "none" {
                    listDetail.append(["Erreur":String(error)])
                }
                
            }
            if let ratio = detail.stop_ratio {
                if isBitTorrent {
                    listDetail.append(["Ratio":"\(avancementRatio()) / \(String(ratio/100))"])
                }
                
            }
            
            /*if let queue_pos = detail.queue_pos {
             
             listDetail.append(["Position":String(queue_pos)])
             
             }*/
            if let created_ts = detail.created_ts {
                let dateFormatter = DateFormatter()
                let date = Date(timeIntervalSince1970: TimeInterval(created_ts))
                
                dateFormatter.dateFormat = "dd-MM-yyyy"
                let dateStr = dateFormatter.string(from: date)
                listDetail.append(["Ajouté le":dateStr])
                
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return listDetail.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "detailDownload", for: indexPath)
        
        let val:[String:String] = listDetail[indexPath.row]
        
        if let label = cell.textLabel {
            if let valFirst = val.first {
                label.font = UIFont.boldSystemFont(ofSize: 18.0)
                label.text = "\(valFirst.key)"
                
                cell.isUserInteractionEnabled = false
                
                if valFirst.key == "Priorité" {
                    cell.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
                    cell.isUserInteractionEnabled = true
                } else if valFirst.key == "Ratio" {
                    cell.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
                    cell.isUserInteractionEnabled = true
                }
            }
            
        }
        
        if let detailLabel = cell.detailTextLabel {
            if let valFirst = val.first {
                detailLabel.text = "\(valFirst.value)"
            }
            
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let val:[String:String] = listDetail[indexPath.row]
        
        if let valFirst = val.first {
            if valFirst.key == "Priorité" {
                
                let alert = UIAlertController(title: "Priorité", message: "Changer la priorité réseau", preferredStyle: UIAlertControllerStyle.actionSheet)
                
                var styleLow = UIAlertActionStyle.default
                var styleNormal = UIAlertActionStyle.default
                var styleHigh = UIAlertActionStyle.default
                
                if valFirst.value == _downloadDetail!.convertFrPriority(priority: DownloadDetail.DownloadPriority.low.rawValue) {
                    styleLow = UIAlertActionStyle.destructive
                } else if valFirst.value == _downloadDetail!.convertFrPriority(priority: DownloadDetail.DownloadPriority.normal.rawValue) {
                    styleNormal = UIAlertActionStyle.destructive
                } else if valFirst.value == _downloadDetail!.convertFrPriority(priority: DownloadDetail.DownloadPriority.high.rawValue) {
                    styleHigh = UIAlertActionStyle.destructive
                }
                
                alert.addAction(UIAlertAction(title: "Haute", style: styleHigh, handler: { action in
                    
                    self._httpRequestFreebox.changePriorityForDownload(id: self._downloadDetail!.id!, priority: 3)
                    
                }))
                
                alert.addAction(UIAlertAction(title: "Normale", style: styleNormal, handler: { action in
                    
                    self._httpRequestFreebox.changePriorityForDownload(id: self._downloadDetail!.id!, priority: 2)
                    
                }))
                
                alert.addAction(UIAlertAction(title: "Basse", style: styleLow, handler: { action in
                    
                    self._httpRequestFreebox.changePriorityForDownload(id: self._downloadDetail!.id!, priority: 1)
                    
                }))
                
                alert.addAction(UIAlertAction(title: "Annuler", style: UIAlertActionStyle.cancel, handler: nil))
                
                self.present(alert, animated: true, completion: nil)
                
            } else if valFirst.key == "Ratio" {
                
                var tabRatio = valFirst.value.components(separatedBy: " / ")
                let ratio = tabRatio[1]
                
                let alert = UIAlertController(title: "Ratio", message: "Changer le ratio de partage", preferredStyle: UIAlertControllerStyle.alert)
                
                alert.addTextField(configurationHandler: { (textField) in
                    textField.placeholder = "Actuel : \(ratio)"
                    textField.keyboardType = UIKeyboardType.decimalPad
                })
                
                alert.addAction(UIAlertAction(title: "Confirmer", style: UIAlertActionStyle.destructive, handler: { action in
                    let textField = alert.textFields![0]
                    print("Text field: \(textField.text)")
                    
                    var ratioDouble:Double = Double(ratio)!
                    
                    if let text = textField.text {
                        let textDot = text.replacingOccurrences(of: ",", with: ".")
                        if let textDouble = Double(textDot) {
                            ratioDouble = textDouble
                        }
                    }
                    
                    
                    self._httpRequestFreebox.changeRatioForBittorrentDownload(id: self._downloadDetail!.id!, ratio: ratioDouble)
                    
                }))
                
                alert.addAction(UIAlertAction(title: "Annuler", style: UIAlertActionStyle.cancel, handler: nil))
                
                self.present(alert, animated: true, completion: nil)
                
            }
        }
        
    }
    
    func avancementRatio() -> Double {
        if let download = _downloadDetail {
            let recuOpt = download.rx_bytes
            let emisOpt = download.tx_bytes
            
            if let recu = recuOpt,
                let emis = emisOpt {
                
                let avancementRatio = round((emis/recu)*100)/100
                
                return avancementRatio
            }
        }
        return 0
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
