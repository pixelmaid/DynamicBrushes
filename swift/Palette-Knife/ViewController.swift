//
//  ViewController.swift
//  Palette-Knife
//
//  Created by JENNIFER MARY JACOBS on 5/4/16.
//  Copyright © 2016 pixelmaid. All rights reserved.
//

import UIKit
import SwiftyJSON

let behaviorMapper = BehaviorMapper()
var stylus = Stylus(x: 0,y:0,angle:0,force:0)
let uiInput = UIInput();

//CONSTANTS:

let kBrightness =       1.0
let kSaturation =       0.45

let kPaletteHeight =	30
let kPaletteSize =	5
let kMinEraseInterval =	0.5

// Padding for margins
let kLeftMargin =	10.0
let kTopMargin =	10.0
let kRightMargin =      10.0
let pX = 1024
let pY = 768

class ViewController: UIViewController, UIGestureRecognizerDelegate,Requester {
    
    
    
    // MARK: Properties
    

  
    var layerContainerView:LayerContainerView!
    
    
    var behaviorManager: BehaviorManager?
    var currentCanvas: Canvas?
    
    let drawKey = NSUUID().uuidString
    let toolbarKey = NSUUID().uuidString
    let layerEventKey = NSUUID().uuidString
    let colorPickerKey = NSUUID().uuidString

    let brushEventKey = NSUUID().uuidString
    let dataEventKey = NSUUID().uuidString
    
    var toolbarController: ToolbarViewController?
    var layerPanelController: LayerPanelViewController?
    var colorPickerView: SwiftHSVColorPicker?
    override var prefersStatusBarHidden: Bool {
        return true
    }
    var drawInterval:Timer!
    
    @IBOutlet weak var layerPanelContainerView: UIView!
    
    @IBOutlet weak var colorPickerContainerView: UIView!
    
    required init?(coder: NSCoder) {
        let screenSize = UIScreen.main.bounds
        let sX = (screenSize.width-CGFloat(pX))/2.0
        let sY = (screenSize.height-CGFloat(pY))/2.0
        
        layerContainerView = LayerContainerView(width:1000,height:768);
        
        
       // backView = UIImageView(frame: CGRect(x:sX, y:sY, width:CGFloat(pX), height:CGFloat(pY)))
        
        
        super.init(coder: coder);
        
    }
    
   
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("segue \(segue.identifier)");
        if(segue.identifier == "toolbarSegue"){
           toolbarController = segue.destination as? ToolbarViewController;
           _ = toolbarController?.toolEvent.addHandler(target: self, handler: ViewController.toolEventHandler, key: toolbarKey)
            
        }
        else if(segue.identifier == "layerPanelSegue"){
            layerPanelController = segue.destination as? LayerPanelViewController;
           _ = layerPanelController?.layerEvent.addHandler(target: self, handler: ViewController.layerEventHandler, key: layerEventKey)
            
        }
        else if(segue.identifier == "colorPickerSegue"){
            print("color picker segue")
           colorPickerView = SwiftHSVColorPicker(frame: CGRect(x:10, y:20, width:300, height:400))
           segue.destination.view.addSubview(colorPickerView!)
           colorPickerView?.setViewColor(UIColor.red)
            colorPickerView?.colorEvent.addHandler(target: self, handler: ViewController.colorPickerEventHandler, key: colorPickerKey)
        }
        
    }
    
    func colorPickerEventHandler(data:(UIColor), key: String){
        toolbarController?.setColor(color:data);
        uiInput.setColor(color:data);
    }

    func toolEventHandler(data: (String), key: String){
        switch(data){
            case "VIEW_LOADED":
                 toolbarController?.exportButton.addTarget(self, action: #selector(ViewController.exportImage), for: .touchUpInside)

                break;
            case "ERASE_MODE":
                layerContainerView.setDrawActive(val: false);
                break;
        case "BRUSH_MODE":
            layerContainerView.setDrawActive(val: true);
            break;
            
        case "TOGGLE_LAYER_PANEL":
            if(layerPanelContainerView?.isHidden == true){
                layerPanelContainerView?.isHidden = false
            }
            else{
                layerPanelContainerView?.isHidden = true
            }
            colorPickerContainerView?.isHidden = true

            break;
        case "TOGGLE_BEHAVIOR_PANEL":
            
            break;
        case "TOGGLE_COLOR_PANEL":
            if(colorPickerContainerView?.isHidden == true){
                colorPickerContainerView?.isHidden = false
            }
            else{
                colorPickerContainerView?.isHidden = true
            }
            layerPanelContainerView?.isHidden = true

            break
        case "DIAMETER_CHANGED":
            uiInput.setDiameter(val: (toolbarController?.diameterSlider.value)!);
            break;
        case "ALPHA_CHANGED":
            print("alpha slider = ",toolbarController?.alphaSlider.value);
            uiInput.setAlpha(val: (toolbarController?.alphaSlider.value)!);
            break;
        default:
            break;
        }
    }
    
    
    func layerEventHandler(data: (String,String,String?), key: String){
        switch(data.0){
        case "LAYER_SELECTED":
            layerContainerView.setActiveLayer(id:data.1);
            break;
        case "LAYER_ADDED":
            self.newLayer();
            break;
        case "SHOW_LAYER":
            layerContainerView.showLayer(id: data.1);
            break;
        case "HIDE_LAYER":
            layerContainerView.hideLayer(id: data.1);
            break;
        case "DELETE_LAYER":
            self.deleteAlert(layerName: data.2!, layerId: data.1)
            break;
        default:
            break;
        }
    }

    
    override func viewDidLoad() {
        
        
        
        super.viewDidLoad()
        
        self.initCanvas()
        
        
        _ = RequestHandler.dataEvent.addHandler(target: self, handler: ViewController.processRequestHandler, key: dataEventKey)
        
        let configureRequest = Request(target: "storage", action: "configure", data:JSON([]), requester: self)
        
        RequestHandler.addRequest(requestData:configureRequest);
        
        drawInterval  = Timer.scheduledTimer(timeInterval:0.016 , target: self, selector: #selector(ViewController.drawIntervalCallback), userInfo: nil, repeats: true)
        
        layerContainerView.center = CGPoint(x:self.view.frame.size.width/2,y:self.view.frame.size.height/2);
        self.view.addSubview(layerContainerView);
        self.view.sendSubview(toBack: layerContainerView);
    
        let pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(ViewController.handlePinch))
        pinchRecognizer.delegate = self
        layerContainerView.addGestureRecognizer(pinchRecognizer)
        
        let rotateRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(ViewController.handleRotate))
        rotateRecognizer.delegate = self
        layerContainerView.addGestureRecognizer(rotateRecognizer)
        
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(ViewController.handlePan))
        panRecognizer.delegate = self
        panRecognizer.minimumNumberOfTouches = 2;
        layerContainerView.addGestureRecognizer(panRecognizer)
        
        layerPanelContainerView.layer.cornerRadius = 8.0
        layerPanelContainerView.clipsToBounds = true
        self.newLayer();

        layerPanelContainerView.isHidden = true;
        
        colorPickerContainerView.layer.cornerRadius = 8.0
        colorPickerContainerView.clipsToBounds = true
        
       colorPickerContainerView.isHidden = true;
        
        uiInput.setDiameter(val: (toolbarController?.diameterSlider.value)!);
        print("alpha val",toolbarController?.alphaSlider.value);
        uiInput.setAlpha(val: (toolbarController?.alphaSlider.value)!);
        uiInput.setColor(color: (colorPickerView?.color)!)


        
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated);
        self.loginAlert();
        
    }
    
    func addConnectionRequests(){
        print("adding connection request")
        let connectRequest = Request(target: "socket", action: "connect", data:JSON([]), requester: self)
        RequestHandler.addRequest(requestData:connectRequest);
        var templateJSON:JSON = [:]
        templateJSON["filename"] = "templates/basic.json"
        let behaviorDownloadRequest = Request(target: "storage", action: "download", data:templateJSON, requester: self)
        RequestHandler.addRequest(requestData:behaviorDownloadRequest);
        
    }
    
    
    func loginAlert() {
        let alertController = UIAlertController(title: "Login", message: "Enter your login key", preferredStyle: .alert)
        //print("present alert",alertController);
        let confirmAction = UIAlertAction(title: "Confirm", style: .default) { (_) in
            if let field = alertController.textFields?[0] {
                // store your data
                UserDefaults.standard.set(field.text, forKey: "userkey")
                UserDefaults.standard.synchronize()
                self.addConnectionRequests();
            } else {
                print("no login key provided");
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        
        alertController.addTextField { (textField) in
            textField.placeholder = ""
        }
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func recconnectAlert(){
        let alertController = UIAlertController(title:"Connection Issue", message: "You were disconnected from the server. Try to reconnect?", preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: "Confirm", style: .default) { (_) in
            self.addConnectionRequests();
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
        
    }
    
    func deleteAlert(layerName:String, layerId:String){
        let alertController = UIAlertController(title:"Delete Layer", message: "Delete the layer \""+layerName+"\"?", preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: "Confirm", style: .default) { (_) in
            let activeId = self.layerContainerView.deleteLayer(id: layerId)
            self.layerPanelController?.removeLayer(layerId: layerId)
            if(activeId != nil){
                self.layerPanelController?.setActive(layerId:activeId!);
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func exportImage() {
        
        //let contentToShare = self.activeLayer!.exportPNG();
        UIGraphicsBeginImageContext(layerContainerView.bounds.size);
        layerContainerView.layer.render(in: UIGraphicsGetCurrentContext()!);
        let viewImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        let contentToShare = UIImagePNGRepresentation(viewImage!)
        
        if(contentToShare != nil){
            let nsContent = NSData(data: contentToShare!)
            let activityViewController = UIActivityViewController(activityItems: [nsContent], applicationActivities: nil)
            // let activityViewController = UIActivityViewController(activityItems: [shareContent as NSString], applicationActivities: nil)
                activityViewController.popoverPresentationController?.sourceView = toolbarController?.exportButton            
            present(activityViewController, animated: true, completion: {})
        }
        
    }
    
    
    
    @objc func drawIntervalCallback(){
        if(currentCanvas!.dirty){
            layerContainerView.drawIntoCurrentLayer(currentCanvas:currentCanvas!);
        
        }
    }
    
    
    func newLayer(){
        print("new layer created")
        let id = layerContainerView.newLayer();
        layerPanelController?.addLayer(layerId: id);
    }
    
    func onErase(sender: UIButton!) {
        layerContainerView.eraseCurrentLayer();
    }
    
    internal func processRequestHandler(data: (String, JSON?), key: String) {
        self.processRequest(data:data)
    }
    
    
    
    //from Requester protocol. Handles result of request
    internal func processRequest(data: (String, JSON?)) {
        // print("process request called for \(self,data)");
        
        switch(data.0){
        case "disconnected":
            print("disconnected from server");
            recconnectAlert();
            break;
        case "filelist_complete":
            print("adding filelist complete request")
            let filelist_complete_request = Request(target:"socket",action:"send_storage_data",data:data.1,requester:self)
            RequestHandler.addRequest(requestData: filelist_complete_request)
            break;
        case "download_complete":
            print("download complete");
            behaviorManager?.loadBehavior(json: data.1!["data"])
            self.synchronizeWithAuthoringClient();
            break;
        case "upload_complete":
            print("upload complete\(data.1)");
            let uploadtype = data.1!["type"];
            switch(uploadtype){
            case "backup":
                print("backup complete");
                break;
            case "save":
                print("save complete");
                let saveCompleteRequest = Request(target:"socket",action:"send_storage_data",data:data.1,requester:self)
                RequestHandler.addRequest(requestData: saveCompleteRequest)
                break;
            default:
                break;
            }
            break;
        case "synchronize_request", "authoring_client_connected":
            self.synchronizeWithAuthoringClient();
            break;
        case "authoring_request":
            
            do{
                let attempt = try behaviorManager?.handleAuthoringRequest(authoring_data: data.1! as JSON);
                
                //error is here!!!!
                let socketRequest = Request(target: "socket", action: "authoring_response", data: attempt, requester: self)
                print("behavior manager recieved authoring  process request \(attempt)");
                
                RequestHandler.addRequest(requestData:socketRequest);
                // self.backupBehavior();
            }
            catch{
                print("failed authoring request");
                var jsonArg:JSON = [:]
                jsonArg["type"] = "authoring_response"
                jsonArg["result"] = "failed"
                
                let socketRequest = Request(target: "socket", action: "authoring_request_response", data: jsonArg, requester: self)
                
                RequestHandler.addRequest(requestData:socketRequest);
            }
            
            break;
        case "storage_request":
            print("storage request recieved \(data.1)");
            let storage_data = data.1!["data"];
            let type = storage_data["type"].stringValue;
            let filename = storage_data["filename"].stringValue;
            switch(type){
            case "save_request":
                self.saveBehavior(filename: filename);
                
                break;
            case "load_request":
                self.loadBehavior(filename: filename);
                
                break;
            case "filelist_request":
                var filelist_json:JSON = [:]
                filelist_json["targetFolder"] = storage_data["targetFolder"];
                let request = Request(target: "storage", action: "filelist", data: filelist_json, requester: self)
                RequestHandler.addRequest(requestData: request);
                break;
                
            default:
                break;
            }
            
            break;
        default:
            break;
            
        }
    }
    
    func synchronizeWithAuthoringClient(){
        let behavior = behaviorManager?.getAllBehaviorJSON();
        let request = Request(target: "socket", action: "synchronize", data: behavior, requester: self)
        RequestHandler.addRequest(requestData: request)
    }
    
    func backupBehavior(){
        var behavior_json:JSON = [:]
        for (key,val) in BehaviorManager.behaviors{
            behavior_json[key] = val.toJSON();
        }
        let filename = "backups/backup_"+String(Int((NSDate().timeIntervalSince1970)*100000));
        var backupJSON:JSON = [:]
        backupJSON["filename"] = JSON(filename);
        backupJSON["data"] = behavior_json
        backupJSON["type"] = JSON("backup")
        backupJSON["targetFolder"] = JSON("backups")
        
        let request = Request(target: "storage", action: "upload", data: backupJSON, requester: self)
        RequestHandler.addRequest(requestData: request);
    }
    
    func loadBehavior(filename:String){
        let filename = "saved_files/"+filename
        var loadJSON:JSON = [:]
        loadJSON["filename"] = JSON(filename);
        loadJSON["type"] = JSON("load")
        
        loadJSON["targetFolder"] = JSON("saved_files")
        let request = Request(target: "storage", action: "download", data: loadJSON, requester: self)
        RequestHandler.addRequest(requestData: request);
    }
    
    
    func saveBehavior(filename:String){
        var behavior_json:JSON = [:]
        for (key,val) in BehaviorManager.behaviors{
            behavior_json[key] = val.toJSON();
        }
        let filename = "saved_files/"+filename
        var saveJSON:JSON = [:]
        saveJSON["filename"] = JSON(filename);
        saveJSON["data"] = behavior_json
        saveJSON["type"] = JSON("save")
        saveJSON["targetFolder"] = JSON("saved_files")
        let request = Request(target: "storage", action: "upload", data: saveJSON, requester: self)
        RequestHandler.addRequest(requestData: request);
    }
    
    
    //event handler for incoming data
    func dataHandler(data:(String,JSON?), key:String){
        switch(data.0){
        case "data_request":
            let requestJSON:JSON = behaviorManager!.getAllBehaviorJSON();
            
            let socketRequest = Request(target: "socket", action: "data_request_response", data: requestJSON, requester: self)
            
            RequestHandler.addRequest(requestData:socketRequest);
            break
        default:
            break
        }
        
    }
    
    func initCanvas(){
        currentCanvas = Canvas();
        behaviorManager = BehaviorManager(canvas: currentCanvas!);
        currentCanvas!.initDrawing();
        // _ = currentCanvas!.geometryModified.addHandler(target: self,handler: ViewController.canvasDrawHandler, key:drawKey)
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if(layerContainerView.activeLayer != nil){
            layerContainerView.activeLayer?.touchesEnded(touches, with: event)
        }
        
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if(layerContainerView.activeLayer != nil){
            layerContainerView.activeLayer?.touchesBegan(touches, with: event)
        }
    }
    
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if(layerContainerView.activeLayer != nil){
            
           layerContainerView.activeLayer?.touchesMoved(touches, with: event)
        }
    }
    
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if(layerContainerView.activeLayer != nil){
            layerContainerView.activeLayer?.touchesCancelled(touches, with: event)
        }
        
    }
    
    
    

    func handlePinch(recognizer : UIPinchGestureRecognizer) {
        print("pinch")
        if let view = recognizer.view {
            view.transform = view.transform.scaledBy(x: recognizer.scale, y: recognizer.scale)
            recognizer.scale = 1
        }
    }
    
     func handleRotate(recognizer : UIRotationGestureRecognizer) {
        // print("rotate")
        
        if let view = recognizer.view {
            view.transform = view.transform.rotated(by: recognizer.rotation)
            recognizer.rotation = 0
        }
    }
    
  func handlePan(recognizer:UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: self.view)
        if let view = recognizer.view {
            view.center = CGPoint(x:view.center.x + translation.x,
                                  y:view.center.y + translation.y)
        }
        recognizer.setTranslation(CGPoint.zero, in: self.view)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    
}


