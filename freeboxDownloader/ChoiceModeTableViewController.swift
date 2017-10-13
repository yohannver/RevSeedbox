//
//  ChoiceModeTableViewController.swift
//  freeboxDownloader
//
//  Created by Yohann Verdier on 11/11/2016.
//  Copyright © 2016 Yohann Verdier. All rights reserved.
//

import UIKit

class ChoiceModeTableViewController: UITableViewController {
    
    @IBOutlet weak var ui_normalCell: UITableViewCell!
    
    @IBOutlet weak var ui_reduitCell: UITableViewCell!
    
    @IBOutlet weak var ui_planificationCell: UITableViewCell!
    
    @IBOutlet weak var ui_stopCell: UITableViewCell!
    
    static var delegate : writeValueBackDelegate!
    
    let mode = ["Normal", "Réduit", "Planification", "Arrêter"]
    
    var cellSelected = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        self.navigationItem.title = "Choix du mode"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        checkCell(cellTitle:cellSelected)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        if let controller = viewController as? SpeedLimitTableViewController {
            controller.current = cellSelected
        }
    }*/

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cellOpt = tableView.cellForRow(at: indexPath)
        
        if let cell = cellOpt {
            if let label = cell.textLabel {
                if label.text == mode[0] {
                    checkCell(cellTitle: mode[0])
                } else if label.text == mode[1] {
                    checkCell(cellTitle: mode[1])
                } else if label.text == mode[2] {
                    checkCell(cellTitle: mode[2])
                } else if label.text == mode[3] {
                    checkCell(cellTitle: mode[3])
                }
            }
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func checkCell(cellTitle:String) {
        if cellTitle == mode[0] {
            ui_normalCell.accessoryType = UITableViewCellAccessoryType.checkmark
            
            ui_reduitCell.accessoryType = UITableViewCellAccessoryType.none
            ui_planificationCell.accessoryType = UITableViewCellAccessoryType.none
            ui_stopCell.accessoryType = UITableViewCellAccessoryType.none
        } else if cellTitle == mode[1] {
            ui_reduitCell.accessoryType = UITableViewCellAccessoryType.checkmark
            
            ui_normalCell.accessoryType = UITableViewCellAccessoryType.none
            ui_planificationCell.accessoryType = UITableViewCellAccessoryType.none
            ui_stopCell.accessoryType = UITableViewCellAccessoryType.none
        } else if cellTitle == mode[2] {
            ui_planificationCell.accessoryType = UITableViewCellAccessoryType.checkmark
            
            ui_reduitCell.accessoryType = UITableViewCellAccessoryType.none
            ui_normalCell.accessoryType = UITableViewCellAccessoryType.none
            ui_stopCell.accessoryType = UITableViewCellAccessoryType.none
        } else if cellTitle == mode[3] {
            ui_stopCell.accessoryType = UITableViewCellAccessoryType.checkmark
            
            ui_reduitCell.accessoryType = UITableViewCellAccessoryType.none
            ui_planificationCell.accessoryType = UITableViewCellAccessoryType.none
            ui_normalCell.accessoryType = UITableViewCellAccessoryType.none
        }
        
        ChoiceModeTableViewController.delegate.writeValueBack(value: cellTitle)
    }

}
