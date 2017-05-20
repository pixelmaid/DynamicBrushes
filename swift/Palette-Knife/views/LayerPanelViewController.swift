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
    var layerEvent = Event<(String,String,String?)>();
    let hideIcon = UIImage(named: "layerVisible_button2x")
    let showIcon = UIImage(named: "layerVisible_button_active2x")
    var layerNameCounter = 1;
    @IBOutlet weak var layerAddButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        layerAddButton.addTarget(self, action:#selector(LayerPanelViewController.layerAddPressed), for: .touchUpInside)
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
    
    func layerAddPressed(){
        self.layerEvent.raise(data: ("LAYER_ADDED","",nil));
    }
    
    func addLayer(layerId:String){
        for l in layers {
            l.selected = false;
        }
        let newLayer = LayerCellData(id: layerId, name: "Layer " + String(layerNameCounter), selected: true)
        layers.append(newLayer);
        layerNameCounter += 1
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
    
    func setActive(layerId:String){
        for i in 0..<layers.count{
            if(layers[i].id == layerId){
                layers[i].selected = true;
            }
            else{
                layers[i].selected = false;
            }
        }
        tableView.reloadData();
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
                    self.layerEvent.raise(data: ("MOVE_LAYER_UP",target_id!,nil));
                    
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
                    self.layerEvent.raise(data: ("MOVE_LAYER_DOWN",target_id!, nil));
                    
                    break;
                }
            }
        }
    }
    
    
    @objc private func toggleLayerVisibility(sender: AnyObject){
        let target = ((sender as! UIButton).superview!.superview) as! LayerCell
        let target_id = target.id;
        if(target.visible){
            target.visible = false;
            self.layerEvent.raise(data: ("HIDE_LAYER",target_id!,nil));
            (sender as! UIButton).setImage(hideIcon, for: UIControlState.normal)
        }
        else{
            target.visible = true;
            self.layerEvent.raise(data: ("SHOW_LAYER",target_id!,nil));
            (sender as! UIButton).setImage(showIcon, for: UIControlState.normal)
        }
    }
    
    @objc private func deleteLayer(sender: AnyObject){
        let target = ((sender as! UIButton).superview!.superview) as! LayerCell
        let target_id = target.id;
        let target_name = target.name;
        self.layerEvent.raise(data: ("DELETE_LAYER",target_id!,target_name));
            
        
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
        
        cell.id = layer.id;
        cell.name = layer.name;
        cell.layerVisibleButton.addTarget(self,action:#selector(LayerPanelViewController.toggleLayerVisibility), for: .touchUpInside)
        cell.deleteLayerButton.addTarget(self,action:#selector(LayerPanelViewController.deleteLayer), for: .touchUpInside)

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("You selected cell\(layers[indexPath.row],indexPath.row)!")
        for l in layers {
            l.selected = false;
        }

        layers[indexPath.row].selected = true;
        tableView.reloadData();
        layerEvent.raise(data:("LAYER_SELECTED",layers[indexPath.row].id,nil))

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
