//
//  LayerPanelViewController.swift
//  DynamicBrushes
//
//  Created by JENNIFER MARY JACOBS on 5/18/17.
//  Copyright © 2017 pixelmaid. All rights reserved.
//


import UIKit
class LayerCellData{
    let id:String
    let name:String
    var selected:Bool
    
    init(id:String,name:String,selected:Bool){
        self.id = id
        self.name = name
        self.selected = selected
    }
}

class LayerPanelViewController: UITableViewController{
    
    //MARK: Properties
    var layers = [LayerCellData]()
    var layerEvent = Event<(String,String)>();
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    //MARK: Public Methods
    
    
    func deactivateAll(){
        self.tableView.isUserInteractionEnabled = false;
        self.tableView.alpha = 0.75
        self.tableView.isHidden = false;
        
           }
    
    func activateAll(){
        self.tableView.isUserInteractionEnabled = true;
        self.tableView.alpha = 1;
        self.tableView.isHidden = true;
        
    }
    
    func addLayer(layerId:String){
        for var l in layers {
            l.selected = false;
        }
        let newLayer = LayerCellData(id: layerId, name: "Layer " + String(layers.count+1), selected: true)
        layers.append(newLayer);
        tableView.reloadData();
        
        
    }
    
    func removeLayer(layerId:String){
        for i in 0..<layers.count{
            if(layers[i].id == layerId){
               layers.remove(at: i);
                tableView.reloadData();
                break;
            }
        }
        
        
    }
    
    //MARK: Private Methods
    
    @objc private func moveCellUp(sender: AnyObject){
        let target = ((sender as! UIButton).superview!.superview) as! LayerCell
        let target_id = target.id;
        for i in 0..<layers.count{
            if(layers[i].id == target_id){
                if(i != 0){
                    let t = layers.remove(at: i);
                    layers.insert(t, at: i-1)
                    tableView.reloadData();
                    self.layerEvent.raise(data: ("MOVE_LAYER_UP",target_id!));
                    
                    break;
                }
            }
        }
    }
    
    @objc private func moveCellDown(sender: AnyObject){
        let target = ((sender as! UIButton).superview!.superview) as! LayerCell
        let target_id = target.id;
        for i in 0..<layers.count{
            if(layers[i].id == target_id){
                if(i != layers.count-1){
                    let t = layers.remove(at: i);
                    layers.insert(t, at: i+1)
                    tableView.reloadData();
                    self.layerEvent.raise(data: ("MOVE_LAYER_DOWN",target_id!));
                    
                    break;
                }
            }
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    

    
    override func numberOfSections(in tableView: UITableView) -> Int {
        print("num of sections called");
        return 1;
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("layers count \(layers.count)");
        
        return layers.count
    }
    
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LayerTableCell", for: indexPath) as! LayerCell
        let layer = layers[indexPath.row]
        
        cell.layerLabel.text = layer.name
        print("layer selected",layer.name,layer.selected,indexPath.row);
        if(layer.selected){
            cell.contentView.backgroundColor = UIColor.darkGray;
        }
        else{
            cell.contentView.backgroundColor = UIColor.black;
 
        }
        //cell.strokeImage.clear();
        // cell.strokeImage.drawSingleStroke(stroke, i: indexPath.row)
        cell.id = layer.id;
        cell.moveUpButton.addTarget(self, action: #selector(LayerPanelViewController.moveCellUp), for: .touchUpInside)
        cell.moveDownButton.addTarget(self, action: #selector(LayerPanelViewController.moveCellDown), for: .touchUpInside)
        
        print("tableView \(cell)");
        
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("You selected cell\(layers[indexPath.row],indexPath.row)!")
        for var l in layers {
            l.selected = false;
        }

        layers[indexPath.row].selected = true;
        tableView.reloadData();
        layerEvent.raise(data:("LAYER_SELECTED",layers[indexPath.row].id))

    }
    
    
    /*
     // Override to support conditional editing of the table view.
     override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */
    
    /*
     // Override to support editing the table view.
     override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
     if editingStyle == .delete {
     // Delete the row from the data source
     tableView.deleteRows(at: [indexPath], with: .fade)
     } else if editingStyle == .insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */
    
    /*
     // Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
     
     }
     */
    
    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
