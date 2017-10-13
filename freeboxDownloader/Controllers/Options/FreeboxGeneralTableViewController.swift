//
//  FreeboxGeneralTableViewController.swift
//  freeboxDownloader
//
//  Created by Yohann Verdier on 10/11/2016.
//  Copyright © 2016 Yohann Verdier. All rights reserved.
//

import UIKit

class FreeboxGeneralTableViewController: UITableViewController {
    
    let USER_DEFAULTS = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Général"
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1
    }
    
    //Clique sur une cellule
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //Récupération des informations de la cellule
        let cellOpt = tableView.cellForRow(at: indexPath)
        
        if let cell = cellOpt {
            if let label = cell.textLabel {
                if label.text == "Déconnexion" {
                    //Suppression de l'app_token des user defaults
                    self.USER_DEFAULTS.removeObject(forKey: HttpRequestFreebox.APP_TOKEN)
                }
            }
        }
    }
    
}
