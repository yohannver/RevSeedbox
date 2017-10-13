//
//  OptionSecondTableViewController.swift
//  freeboxDownloader
//
//  Created by Yohann Verdier on 10/11/2016.
//  Copyright © 2016 Yohann Verdier. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController {
    
    //La configuration des téléchargements récupéré sur la freebox
    var _downloadConfiguration:DownloadConfiguration?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    //Clique sur le bouton fermer
    @IBAction func clickClose(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //Si une cellule est sélectionnée
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //Déselectionner la cellule avec une animation
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    //Segue pour passer l'objet download configuration à la vue suivante
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showSpeedLimit" {
            let destination = segue.destination as! SpeedLimitTableViewController
            destination._downloadConfiguration = _downloadConfiguration
        }
        if segue.identifier == "showDownloadGeneral" {
            let destination = segue.destination as! DownloadsGeneralOptionsTableViewController
            destination._downloadConfiguration = _downloadConfiguration
        }
        if segue.identifier == "showTorrent" {
            let destination = segue.destination as! TorrentTableViewController
            destination._downloadConfiguration = _downloadConfiguration
        }
        if segue.identifier == "showNewsgroup" {
            let destination = segue.destination as! NewsgroupTableViewController
            destination._downloadConfiguration = _downloadConfiguration
        }
        if segue.identifier == "showFeeds" {
            let destination = segue.destination as! FeedsTableViewController
            destination._downloadConfiguration = _downloadConfiguration
        }
        if segue.identifier == "showBlockList" {
            let destination = segue.destination as! BlockListTableViewController
            destination._downloadConfiguration = _downloadConfiguration
        }
    }

}
