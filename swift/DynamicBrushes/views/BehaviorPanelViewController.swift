//
//  BehaviorPanelViewController.swift
//  Pods
//
//  Created by JENNIFER MARY JACOBS on 6/5/17.
//
//


import UIKit
import SwiftyJSON
class BehaviorCellData{
    let id:String
    let name:String
    var active:Bool
    
    init(id:String,name:String,active:Bool){
        self.id = id
        self.name = name
        self.active = active
        
    }
}

class BehaviorPanelViewController: UITableViewController{
    
    //MARK: Properties
    var behaviors = [BehaviorCellData]()
    var behaviorEvent = Event<(String,String,String?)>();
    let activeIcon = UIImage(named: "behavior_activate_button_active2x")
    let inactiveIcon = UIImage(named: "behavior_activate_button2x")


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
    
   
    func addBehavior(behaviorId:String,behaviorName:String,activeStatus:Bool){
        let newBehavior = BehaviorCellData(id: behaviorId, name: behaviorName, active:activeStatus)
        behaviors.append(newBehavior);
        tableView.reloadData();
        
    }
    
    func loadBehaviors(json:JSON){
        behaviors.removeAll();
        
        for(key,value) in json{
            let newBehavior = BehaviorCellData(id:key,name:value["name"].stringValue, active:value["active_status"].boolValue);
                behaviors.append(newBehavior);

        }

        tableView.reloadData();
    }
    
    func removeBehavior(behaviorId:String){
        for i in 0..<behaviors.count{
            if(behaviors[i].id == behaviorId){
                behaviors.remove(at: i);
                tableView.reloadData();
                break;
            }
        }
        
        
    }
    
    func setActive(id:String){
        for i in 0..<behaviors.count{
            if(behaviors[i].id == id){
                behaviors[i].active = true;
            }
        }
        tableView.reloadData();
    }
    
    
    func setInactive(id:String){
        for i in 0..<behaviors.count{
            if(behaviors[i].id == id){
                behaviors[i].active = false;
            }
        }
        tableView.reloadData();
    }
    
    

    
    @objc private func toggleActive(sender: AnyObject){
     
        let target = ((sender as! UIButton).superview!.superview) as! BehaviorCell
        let target_id = target.id;
        #if DEBUG
            print("toggle active",target_id,target.active);
        #endif
        var behavior_data = behaviors.filter({$0.id == target_id});

        if(target.active){
            print("set target inactive")

            target.active = false;
            behavior_data[0].active = false
            self.behaviorEvent.raise(data: ("DEACTIVATE_BEHAVIOR",target_id!,nil));
            
            (sender as! UIButton).setImage(inactiveIcon, for: UIControl.State.normal)
        }
        else{
            print("set target active")
            target.active = true;
            behavior_data[0].active = true

            self.behaviorEvent.raise(data: ("ACTIVATE_BEHAVIOR",target_id!,nil));
            
            (sender as! UIButton).setImage(activeIcon, for: UIControl.State.normal)
        }
        self.tableView.reloadData();
    }
    
    @objc private func refreshBehavior(sender: AnyObject){
        let target = ((sender as! UIButton).superview!.superview) as! BehaviorCell
        let target_id = target.id;
       
        self.behaviorEvent.raise(data: ("REFRESH_BEHAVIOR",target_id!,nil));
            
    }
    
    
    
    //MARK: Private Methods

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1;
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return behaviors.count
    }
    
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BehaviorTableCell", for: indexPath) as! BehaviorCell
        let behavior = behaviors[indexPath.row]
        
        cell.label.text = behavior.name
        
        cell.id = behavior.id;
        cell.name = behavior.name;
        cell.active = behavior.active
        cell.activateButton.addTarget(self,action:#selector(BehaviorPanelViewController.toggleActive), for: .touchUpInside)
        if(cell.active){
            cell.activateButton.setImage(activeIcon, for: UIControl.State.normal)
        }
        else{
            cell.activateButton.setImage(inactiveIcon, for: UIControl.State.normal)
        }
        
        cell.refreshButton.addTarget(self,action:#selector(BehaviorPanelViewController.refreshBehavior), for: .touchUpInside)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
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
