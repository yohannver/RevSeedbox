//
//  EncryptionConnexionsTableViewController.swift
//  freeboxDownloader
//
//  Created by Yohann Verdier on 11/11/2016.
//  Copyright © 2016 Yohann Verdier. All rights reserved.
//

import UIKit

class EncryptionConnexionsTableViewController: UITableViewController {
    
    @IBOutlet weak var ui_desactivatedCell: UITableViewCell!
    
    @IBOutlet weak var ui_authorizedCell: UITableViewCell!
    
    @IBOutlet weak var ui_preferedCell: UITableViewCell!
    
    @IBOutlet weak var ui_mandatoryCell: UITableViewCell!
    
    static var delegate : writeValueBackDelegate!
    
    let encryptionConnexion = ["Désactivé", "Autorisé", "Préféré", "Obligatoire"]
    
    var cellSelected = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        self.navigationItem.title = "Chiffrement des connexions"

    }
    
    override func viewWillAppear(_ animated: Bool) {
        checkCell(cellTitle:cellSelected)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cellOpt = tableView.cellForRow(at: indexPath)
        
        if let cell = cellOpt {
            if let label = cell.textLabel {
                if label.text == encryptionConnexion[0] {
                    checkCell(cellTitle: encryptionConnexion[0])
                } else if label.text == encryptionConnexion[1] {
                    checkCell(cellTitle: encryptionConnexion[1])
                } else if label.text == encryptionConnexion[2] {
                    checkCell(cellTitle: encryptionConnexion[2])
                } else if label.text == encryptionConnexion[3] {
                    checkCell(cellTitle: encryptionConnexion[3])
                }
            }
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func checkCell(cellTitle:String) {
        if cellTitle == encryptionConnexion[0] {
            ui_desactivatedCell.accessoryType = UITableViewCellAccessoryType.checkmark
            
            ui_authorizedCell.accessoryType = UITableViewCellAccessoryType.none
            ui_preferedCell.accessoryType = UITableViewCellAccessoryType.none
            ui_mandatoryCell.accessoryType = UITableViewCellAccessoryType.none
        } else if cellTitle == encryptionConnexion[1] {
            ui_authorizedCell.accessoryType = UITableViewCellAccessoryType.checkmark
            
            ui_desactivatedCell.accessoryType = UITableViewCellAccessoryType.none
            ui_preferedCell.accessoryType = UITableViewCellAccessoryType.none
            ui_mandatoryCell.accessoryType = UITableViewCellAccessoryType.none
        } else if cellTitle == encryptionConnexion[2] {
            ui_preferedCell.accessoryType = UITableViewCellAccessoryType.checkmark
            
            ui_authorizedCell.accessoryType = UITableViewCellAccessoryType.none
            ui_desactivatedCell.accessoryType = UITableViewCellAccessoryType.none
            ui_mandatoryCell.accessoryType = UITableViewCellAccessoryType.none
        } else if cellTitle == encryptionConnexion[3] {
            ui_mandatoryCell.accessoryType = UITableViewCellAccessoryType.checkmark
            
            ui_authorizedCell.accessoryType = UITableViewCellAccessoryType.none
            ui_preferedCell.accessoryType = UITableViewCellAccessoryType.none
            ui_desactivatedCell.accessoryType = UITableViewCellAccessoryType.none
        }
        
        EncryptionConnexionsTableViewController.delegate.writeValueBack(value: cellTitle)
    }
}
