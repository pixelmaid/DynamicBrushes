//
//  SavedFilesPanelViewController.swift
//  DynamicBrushes
//
//  Created by JENNIFER MARY JACOBS on 5/22/17.
//  Copyright © 2017 pixelmaid. All rights reserved.
//

import Foundation


import UIKit
class FileCellData{
    let id:String
    let name:String
    var selected:Bool
    
    init(id:String,name:String){
        self.id = id
        self.name = name
       self.selected = false
    }
}

class SavedFilesPanelViewController: UITableViewController{
    var files = [FileCellData]()
    var fileEvent = Event<(String,String,String?)>();

    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func loadFiles(newFiles:[String:String]){
        files.removeAll();
        for (key,value) in newFiles{
            let id = key
            let newFile = FileCellData(id: id, name: value)
            files.append(newFile);
        }
        DispatchQueue.main.async {
            self.tableView.reloadData();
        }
    }
    
    
      // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1;
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return files.count
    }
    
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FileTableCell", for: indexPath) as! FileCell
        let file = files[indexPath.row]
        
        cell.label.text = file.name
        if(file.selected){
            cell.contentView.backgroundColor = UIColor.darkGray;
        }
        else{
            cell.contentView.backgroundColor = UIColor.black;
        }
        
        cell.id = file.id;
        cell.name = file.name;
       
        return cell
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        for f in files {
            f.selected = false;
        }
        
        files[indexPath.row].selected = true;
        tableView.reloadData();
        fileEvent.raise(data:("FILE_SELECTED",files[indexPath.row].id,files[indexPath.row].name))
        
    }
    
    
}
