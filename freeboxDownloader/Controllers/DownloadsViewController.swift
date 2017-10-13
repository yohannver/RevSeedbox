//
//  ViewController.swift
//  freeboxDownloader
//
//  Created by Yohann Verdier on 23/10/2016.
//  Copyright © 2016 Yohann Verdier. All rights reserved.
//

import UIKit
import Foundation

class DownloadsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    let USER_DEFAULTS = UserDefaults.standard
    
    @IBOutlet weak var ui_tableView: UITableView!
    
    @IBOutlet weak var ui_totalDownloadSpeed: UILabel!
    
    @IBOutlet weak var ui_totalUploadSpeed: UILabel!
    
    @IBOutlet weak var ui_diskSize: UILabel!
    
    @IBOutlet weak var ui_buttonPause: UIBarButtonItem!
    
    @IBOutlet weak var ui_buttonResume: UIBarButtonItem!
    
    //Liste des téléchargements à afficher
    var _downloadListToDisplay:[DownloadDetail] = []
    
    //Liste des téléchargements sur le freebox server
    var _downloadListAllOnFreeboxServer:[DownloadDetail] = []
    
    //Liste des téléchargements en cours sur le freebox server
    var _downloadListInProgressOnFreeboxServer:[DownloadDetail] = []
    
    //Liste des disques dur sur le freebox server
    var _diskListOnFreeboxServer:[DiskDetail] = []
    
    var _downloadConfiguration:DownloadConfiguration?
    
    var _httpRequestFreebox:HttpRequestFreebox = HttpRequestFreebox()
    
    var positionDownload:Int?
    
    var _timer:Timer?
    
    var allSelected = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        _httpRequestFreebox.app_token = USER_DEFAULTS.string(forKey: HttpRequestFreebox.APP_TOKEN)
        
        //Récupération de l'IP de la freeboxserver dans les userdefaults
        _httpRequestFreebox.ipServer = USER_DEFAULTS.string(forKey: HttpRequestFreebox.IP_FREEBOXSERVER)
        //Récupération le port de la freeboxserver dans les userdefaults
        _httpRequestFreebox.portServer = USER_DEFAULTS.integer(forKey: HttpRequestFreebox.REMOTE_ACCESS_PORT)
        
        _httpRequestFreebox.getLocalURLOrIP()
        
        _downloadListAllOnFreeboxServer = _downloadListToDisplay
        createDownloadListInProgress()
        
        displayPauseAndPlayButton()
        
        ui_diskSize.text = getDiskInternalSize()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(DownloadsViewController.loadListFromTimer),name:NSNotification.Name(rawValue: "load"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(DownloadsViewController.deleteDownload),name:NSNotification.Name(rawValue: "downloadDeletedSuccess"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(DownloadsViewController.doNotDeleteDownload),name:NSNotification.Name(rawValue: "downloadDeletedFail"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(DownloadsViewController.stoppedDownload),name:NSNotification.Name(rawValue: "downloadStoppedSuccess"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(DownloadsViewController.doNotStoppedDownload),name:NSNotification.Name(rawValue: "downloadStoppedFail"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(DownloadsViewController.resumedDownload),name:NSNotification.Name(rawValue: "downloadResumedSuccess"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(DownloadsViewController.doNoResumedDownload),name:NSNotification.Name(rawValue: "downloadResumedFail"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(DownloadsViewController.openSplashScreen),name:NSNotification.Name(rawValue: "openSplashScreen"), object: nil)
        launchTimer(seconds:2)
    }
    
    @IBAction func clickFilterDownloads(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex
        {
        case 0:
            allSelected = true
            loadList()
        case 1:
            allSelected = false
            loadList()
        default:
            break;
        }
    }
    
    @IBAction func clickAllResume(_ sender: UIBarButtonItem) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        for download in _downloadListAllOnFreeboxServer {
            if let id = download.id {
                self._httpRequestFreebox.resumeDownloadById(id: id)
            }
        }
    }
    
    @IBAction func clickAllStop(_ sender: UIBarButtonItem) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        for download in _downloadListAllOnFreeboxServer {
            if let id = download.id {
                self._httpRequestFreebox.stopDownloadById(id: id)
            }
        }
    }
    
    func getDiskInternalSize() -> String {
        for disk in _diskListOnFreeboxServer {
            if disk.type == "internal" {
                if let listPartitions = disk.listPartitions {
                    for partition in listPartitions {
                        if partition.label == "Disque dur" {
                            let totalSize = partition.getMoOrGo(partition.total_bytes!)
                            let freeSize = partition.getMoOrGo(partition.free_bytes!)
                            
                            return "\(freeSize) / \(totalSize)"
                        }
                    }
                }
            }
        }
        
        return ""
    }
    
    func createDownloadListInProgress() {
        var newListDownloads:[DownloadDetail] = []
        for down in self._downloadListAllOnFreeboxServer {
            if down.status != DownloadDetail.DownloadStatus.stopped.rawValue && down.status != DownloadDetail.DownloadStatus.done.rawValue {
                newListDownloads.append(down)
            }
        }
        self._downloadListInProgressOnFreeboxServer.removeAll()
        self._downloadListInProgressOnFreeboxServer = newListDownloads
    }
    
    func getListDownloads() {
        _httpRequestFreebox.getAllDownloads()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if let timer = _timer {
            timer.invalidate()
            _timer = nil
        }
        NotificationCenter.default.removeObserver(self)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //Change the selected background view of the cell.
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return _downloadListToDisplay.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:DownloadTableViewCell = tableView.dequeueReusableCell(withIdentifier: "download_cell", for: indexPath) as! DownloadTableViewCell
        
        let downloadDetail = _downloadListToDisplay[indexPath.row]
        
        //affichage de la cellule
        cell.display(download: downloadDetail)
        
        //affichage des informations globales
        if let speedDown = getTotalDownloadSpeed() {
            ui_totalDownloadSpeed.text = "DL : \(speedDown)"
        } else {
            ui_totalDownloadSpeed.text = "DL :"
        }
        if let speedUp = getTotalUploadSpeed() {
            ui_totalUploadSpeed.text = "UL : \(speedUp)"
        } else {
            ui_totalUploadSpeed.text = "UL :"
        }
        
        return cell
    }
    
    func getTotalDownloadSpeed() -> String? {
        var speedDownload:Double = 0
        for download in _downloadListInProgressOnFreeboxServer {
            if let speed = download.rx_rate {
                speedDownload += speed
            }
        }
        
        return _downloadListInProgressOnFreeboxServer.first?.getOcSKoSOrMoS(speedDownload)
    }
    
    func getTotalUploadSpeed() -> String? {
        var speedUpload:Double = 0
        for download in _downloadListInProgressOnFreeboxServer {
            if let speed = download.tx_rate {
                speedUpload += speed
            }
        }
        
        return _downloadListInProgressOnFreeboxServer.first?.getOcSKoSOrMoS(speedUpload)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        print("blabla")
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        if let timer = _timer {
            timer.invalidate()
            _timer = nil
            print("Timer arrêté")
        }
        
        self.positionDownload = indexPath.row
        let idDownload = self._downloadListToDisplay[indexPath.row].id! as Int
        
        let deleteAction = UITableViewRowAction(style: .default, title: "Supprimer") {action in
            self._httpRequestFreebox.deleteDownloadById(id: idDownload)
            print("Suppression")
            
            self.ui_buttonResume.isEnabled = true
            self.ui_buttonPause.isEnabled = true
        }
        
        
        let buttonName = getEditButtonName(position: self.positionDownload)
        var editAction:UITableViewRowAction = UITableViewRowAction()
        
        if buttonName != "Fini" {
            editAction = UITableViewRowAction(style: .normal, title: buttonName) {action in
                
                
                if buttonName == "Reprendre" {
                    self._httpRequestFreebox.resumeDownloadById(id: idDownload)
                } else if buttonName == "Arrêter" {
                    self._httpRequestFreebox.stopDownloadById(id: idDownload)
                }
                
                self.ui_buttonResume.isEnabled = true
                self.ui_buttonPause.isEnabled = true
                print(buttonName)
            }
        }
        
        return [deleteAction, editAction]
    }
    
    func getEditButtonName(position:Int?) -> String {
        if let pos = position {
            let status = self._downloadListToDisplay[pos].status
            if let stat = status {
                if stat == DownloadDetail.DownloadStatus.stopped.rawValue || stat == DownloadDetail.DownloadStatus.stopping.rawValue {
                    return "Reprendre"
                } else if stat == DownloadDetail.DownloadStatus.starting.rawValue || stat == DownloadDetail.DownloadStatus.downloading.rawValue || stat == DownloadDetail.DownloadStatus.checking.rawValue || stat == DownloadDetail.DownloadStatus.repairing.rawValue || stat == DownloadDetail.DownloadStatus.extracting.rawValue || stat == DownloadDetail.DownloadStatus.seeding.rawValue {
                    return "Arrêter"
                } else if stat == DownloadDetail.DownloadStatus.done.rawValue {
                    return "Fini"
                } else {
                    return "Arrêter"
                }
            }
        }
        return "Arrêter"
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetails" {
            if let cell = sender as? UITableViewCell {
                if let indexPath = self.ui_tableView.indexPath(for: cell) {
                    let selectedDownload = _downloadListToDisplay[indexPath.row]
                    let downDetailViewController:DownloadDetailTableViewController = segue.destination as! DownloadDetailTableViewController
                    downDetailViewController._downloadDetail = selectedDownload
                }
            }
        }
        if segue.identifier == "showOptions" {
            let navController = segue.destination as! UINavigationController
            let controller = navController.topViewController as! SettingsTableViewController
            controller._downloadConfiguration = _downloadConfiguration
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
        if _timer == nil {
            launchTimer(seconds: 2)
            print("Timer relancé")
        }
        
    }
    
    func launchTimer(seconds:Double) {
        _timer = Timer.scheduledTimer(timeInterval: seconds, target: self, selector: #selector(DownloadsViewController.getListDownloads), userInfo: nil, repeats: true)
    }
    
    func openSplashScreen() {
        dismiss(animated: true, completion: nil)
    }
    
    func stoppedDownload() {
        if let pos = self.positionDownload {
            self._downloadListAllOnFreeboxServer[pos].status = DownloadDetail.DownloadStatus.stopped.rawValue
        }
        positionDownload = nil
        loadList()
    }
    
    func doNotStoppedDownload() {
        positionDownload = nil
        loadList()
    }
    
    func resumedDownload() {
        if let pos = self.positionDownload {
            self._downloadListAllOnFreeboxServer[pos].status = DownloadDetail.DownloadStatus.downloading.rawValue
        }
        positionDownload = nil
        loadList()
    }
    
    func doNoResumedDownload() {
        positionDownload = nil
        loadList()
    }
    
    func deleteDownload() {
        if let pos = positionDownload {
            _downloadListAllOnFreeboxServer.remove(at: pos)
            loadList()
            positionDownload = nil
        }
    }
    
    func doNotDeleteDownload() {
        positionDownload = nil
        self.ui_tableView.reloadData()
    }
    
    func loadListFromTimer(){
        
        self._downloadListAllOnFreeboxServer.removeAll()
        _downloadListAllOnFreeboxServer = _httpRequestFreebox._downloadListOnFreeboxServer
        
        createDownloadListInProgress()
        self._downloadListToDisplay.removeAll()
        
        if allSelected {
            
            self._downloadListToDisplay = self._downloadListAllOnFreeboxServer
        } else {
            //self._downloadListAllOnFreeboxServer = self._downloadListToDisplay
            self._downloadListToDisplay = self._downloadListInProgressOnFreeboxServer
        }
        
        if _timer != nil {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            displayPauseAndPlayButton()
            self.ui_tableView.reloadData()
        }
    }
    
    func loadList() {
        createDownloadListInProgress()
        self._downloadListToDisplay.removeAll()
        
        if allSelected {
            self._downloadListToDisplay = self._downloadListAllOnFreeboxServer
        } else {
            self._downloadListToDisplay = self._downloadListInProgressOnFreeboxServer
        }
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        displayPauseAndPlayButton()
        self.ui_tableView.reloadData()
    }
    
    func displayPauseAndPlayButton() {
        
        ui_buttonPause.isEnabled = false
        ui_buttonResume.isEnabled = false
        
        for download in self._downloadListToDisplay {
            if download.status != DownloadDetail.DownloadStatus.stopped.rawValue && download.status != DownloadDetail.DownloadStatus.done.rawValue {
                ui_buttonPause.isEnabled = true
                break
            }
        }
        
        for download in self._downloadListToDisplay {
            if download.status == DownloadDetail.DownloadStatus.stopped.rawValue {
                ui_buttonResume.isEnabled = true
                break
            }
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

