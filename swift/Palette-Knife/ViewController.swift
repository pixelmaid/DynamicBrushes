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
    
    //@IBOutlet weak var bitmapView: BitmapCanvasView!
    @IBOutlet weak var eraseButton: UIButton!
    @IBOutlet weak var addLayerButton: UIButton!
    @IBOutlet weak var layerContainerView: UIView!
    
    var layers = [ModifiedCanvasView]();
    var activeLayer:ModifiedCanvasView?
    
    
    var backView:UIImageView
    
    var behaviorManager: BehaviorManager?
    var currentCanvas: Canvas?
    
    let drawKey = NSUUID().uuidString
    let brushEventKey = NSUUID().uuidString
    let dataEventKey = NSUUID().uuidString
    
    var brushes = [String:Brush]()
    var drawInterval:Timer!

    
    required init?(coder: NSCoder) {
        let screenSize = UIScreen.main.bounds
        let sX = (screenSize.width-CGFloat(pX))/2.0
        let sY = (screenSize.height-CGFloat(pY))/2.0
        
       
        
        
        backView = UIImageView(frame: CGRect(x:sX, y:sY, width:CGFloat(pX), height:CGFloat(pY)))
        
        
        super.init(coder: coder);
        
    }
    
    
    override func viewDidLoad() {
        
        
        
        super.viewDidLoad()
        
        self.initCanvas()
       
        
        _ = RequestHandler.dataEvent.addHandler(target: self, handler: ViewController.processRequestHandler, key: dataEventKey)
        
        let configureRequest = Request(target: "storage", action: "configure", data:JSON([]), requester: self)
        
        RequestHandler.addRequest(requestData:configureRequest);

       
        newLayer(sender: nil);
        
        eraseButton.addTarget(self, action: #selector(ViewController.onErase), for: .touchUpInside)
        addLayerButton.addTarget(self, action: #selector(ViewController.newLayer), for: .touchUpInside)
        
        drawInterval  = Timer.scheduledTimer(timeInterval:0.016 , target: self, selector: #selector(ViewController.drawIntervalCallback), userInfo: nil, repeats: true)
        
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated);
         self.presentAlert();

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
    
    
    func presentAlert() {
        let alertController = UIAlertController(title: "login_key", message: "Enter your login key", preferredStyle: .alert)
        print("present alert",alertController);
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
    
    
    @objc func drawIntervalCallback(){
        if(activeLayer != nil){
            let context = activeLayer?.pushContext();
            currentCanvas?.drawSegment(context:context!)
            activeLayer?.popContext();
        }
    }

    
    func newLayer(sender: UIButton!){
        print("new layer created")
        let screenSize = layerContainerView.bounds
        let origin = layerContainerView.frame.origin
        activeLayer = ModifiedCanvasView(frame: CGRect(x:origin.x, y:origin.y, width:screenSize.width, height:screenSize.height))
        self.layers.append(activeLayer!)
        layerContainerView.addSubview(activeLayer!);
        
    }
    
    func onErase(sender: UIButton!) {
        if(activeLayer != nil){
            activeLayer!.erase();
        }
    }
    
    internal func processRequestHandler(data: (String, JSON?), key: String) {
        self.processRequest(data:data)
    }
    
    
    
    //from Requester protocol. Handles result of request
    internal func processRequest(data: (String, JSON?)) {
        print("process request called for \(self,data)");
        
        switch(data.0){
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
    
    /*func canvasDrawHandler(data:(Geometry,String,String), key:String){
        if(activeLayer != nil){
            switch data.2{
                
            case "DRAW":
                switch data.1{
                case "SEGMENT":
                    let seg = data.0 as! Segment
                    
                    let prevSeg = seg.getPreviousSegment()
                    
                    if(prevSeg != nil){
                        
                        let bounds = activeLayer!.bounds
                        var previousLocation = prevSeg!.point.toCGPoint();
                        var location = seg.point.toCGPoint()
                        //location.y = bounds.size.height - location.y
                        //previousLocation.y = bounds.size.height - previousLocation.y
                        
                        var color = seg.color;
                        let alpha = seg.alpha;
                        color.alpha = alpha;
                        let diameter = CGFloat(seg.diameter);
                        
                        activeLayer!.drawStroke(from: previousLocation, to: location, lineWidth: diameter, color: color.toUIColor())
                        
                        
                    }
                    break
                default : break
                }
            default:
                break
            }
        }
    }*/
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if(activeLayer != nil){
            activeLayer?.touchesEnded(touches, with: event)
        }
      
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            if(activeLayer != nil){
                activeLayer?.touchesBegan(touches, with: event)
            }
    }
    
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if(activeLayer != nil){

            self.activeLayer?.touchesMoved(touches, with: event)
        }
    }
    
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if(activeLayer != nil){
            activeLayer?.touchesCancelled(touches, with: event)
        }
        
    }
    

    
    
    @IBAction func handlePinch(recognizer : UIPinchGestureRecognizer) {
        print("pinch")
        if let view = recognizer.view {
            view.transform = view.transform.scaledBy(x: recognizer.scale, y: recognizer.scale)
            recognizer.scale = 1
        }
    }
    
    @IBAction func handleRotate(recognizer : UIRotationGestureRecognizer) {
        print("rotate")

        if let view = recognizer.view {
            view.transform = view.transform.rotated(by: recognizer.rotation)
            recognizer.rotation = 0
        }
    }
    
    @IBAction func handlePan(recognizer:UIPanGestureRecognizer) {
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


