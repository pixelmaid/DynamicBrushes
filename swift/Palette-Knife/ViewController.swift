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


class ViewController: UIViewController, Requester {
    
    
    
    // MARK: Properties
    
    @IBOutlet weak var dualBrushButton: UIButton!
    @IBOutlet weak var largeBrushButton: UIButton!
    @IBOutlet weak var smallBrushButton: UIButton!
    @IBOutlet weak var bitmapView: BitmapCanvasView!
    
    //var canvasViewLg:CanvasView
    
    var backView:UIImageView
    var fabricatorView = FabricatorView();
    // var canvasViewBakeSm:CanvasView;
    // var canvasViewBakeLg:CanvasView;
    
    
    @IBOutlet weak var xOutput: UITextField!
    
    @IBOutlet weak var yOutput: UITextField!
    
    @IBOutlet weak var zOutput: UITextField!
    
    @IBOutlet weak var statusOutput: UITextField!
    
    
    
    //var socketManager = SocketManager();
    var behaviorManager: BehaviorManager?
    var currentCanvas: Canvas?
    let drawKey = NSUUID().uuidString
    let brushEventKey = NSUUID().uuidString
    let dataEventKey = NSUUID().uuidString
    
    
    var downInCanvas = false;
    
    var radialBrush:Brush?
    var bakeBrush:Brush?
    
    var brushes = [String:Brush]()
    
    required init?(coder: NSCoder) {
        let screenSize = UIScreen.main.bounds
        let sX = (screenSize.width-CGFloat(GCodeGenerator.pX))/2.0
        let sY = (screenSize.height-CGFloat(GCodeGenerator.pY))/2.0
        
        GCodeGenerator.setCanvasOffset(x: Float(sX),y:Float(sY));
        
        //canvasViewLg = CanvasView(frame: CGRect(x:sX, y:sY, width:CGFloat(GCodeGenerator.pX), height:CGFloat(GCodeGenerator.pY)))
        
        //bitmapView = BitmapCanvasView(frame:CGRect(x:sX, y:sY, width:CGFloat(GCodeGenerator.pX), height:CGFloat(GCodeGenerator.pY)))
        
        backView = UIImageView(frame: CGRect(x:sX, y:sY, width:CGFloat(GCodeGenerator.pX), height:CGFloat(GCodeGenerator.pY)))
        
        super.init(coder: coder);
        
    }
    
    
    override func viewDidLoad() {
        
        
        super.viewDidLoad()
        
        
     //   canvasViewLg.backgroundColor=UIColor.clear
      //  self.view.addSubview(canvasViewLg)
      //self.view.addSubview(bitmapView);
        
        

        
        //self.view.sendSubview(toBack: bitmapView)
        //self.view.sendSubview(toBack: canvasViewLg)
        
        //canvasViewLg.alpha = 1;
        
        
       // self.fabricatorView.drawFabricatorPosition(x: Float(0), y: Float(0), z: Float(0))
        self.initCanvas()
        
        _ = RequestHandler.dataEvent.addHandler(target: self, handler: ViewController.processRequestHandler, key: dataEventKey)
        
        let configureRequest = Request(target: "storage", action: "configure", data:JSON([]), requester: self)
        
        let connectRequest = Request(target: "socket", action: "connect", data:JSON([]), requester: self)
        
        var templateJSON:JSON = [:]
        templateJSON["filename"] = "templates/basic.json"
        let behaviorDownloadRequest = Request(target: "storage", action: "download", data:templateJSON, requester: self)
        
        RequestHandler.addRequest(requestData:configureRequest);
        RequestHandler.addRequest(requestData:connectRequest);
        RequestHandler.addRequest(requestData:behaviorDownloadRequest);
        
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
    
    
    
    func newCanvasClicked(sender: AnyObject?){
        self.initCanvas();
    }
    
    func newDrawingClicked(sender: AnyObject){
        currentCanvas?.initDrawing();
    }
    
    func initCanvas(){
        currentCanvas = Canvas();
        behaviorManager = BehaviorManager(canvas: currentCanvas!);
        //socketManager.initAction(target: currentCanvas!,type:"canvas_init");
        //socketManager.initAction(stylus);
        
        currentCanvas!.initDrawing();
        _ = currentCanvas!.geometryModified.addHandler(target: self,handler: ViewController.canvasDrawHandler, key:drawKey)
        
        
    }
    
    
    //----------------------------------  HARDCODED BRUSHES ---------------------------------- //
    func initDripBrush(){
        let dripBehavior = behaviorManager?.initDripBehavior();
        let dripBrush = Brush(name:"parentBehavior",behaviorDef: dripBehavior, parent:nil, canvas:self.currentCanvas!)
        //socketManager.initAction(target: dripBrush,type:"brush_init");
        
    }
    
    
    func initBakeBrush(){
        let bake_behavior = behaviorManager?.initBakeBehavior();
        bakeBrush = Brush(name:"bake_brush",behaviorDef: bake_behavior, parent:nil, canvas:self.currentCanvas!)
        //socketManager.initAction(target: bakeBrush!,type:"brush_init");
    }
    
    
    func initRadialBrush(){
        let radial_behavior = behaviorManager?.initRadialBehavior();
        radialBrush = Brush(name:"radial",behaviorDef: radial_behavior, parent:nil, canvas:self.currentCanvas!)
        // socketManager.initAction(target: radialBrush!,type:"brush_init");
        
    }
    
    func initFractalBrush(){
        let rootBehavior = behaviorManager?.initFractalBehavior();
        let rootBehaviorBrush = Brush(name:"rootBehaviorBrush",behaviorDef: rootBehavior, parent:nil, canvas:self.currentCanvas!)
        //rootBehaviorBrush.strokeColor.b = 255;
        // socketManager.initAction(target: rootBehaviorBrush,type:"brush_init");
        
        
    }
    
    //---------------------------------- END HARDCODED BRUSHES ---------------------------------- //
    
    
    
    func canvasDrawHandler(data:(Geometry,String,String), key:String){
        print("draw handler called")
        switch data.2{
            
        case "DRAW":
            switch data.1{
            case "SEGMENT":
                let seg = data.0 as! Segment
                
                let prevSeg = seg.getPreviousSegment()
                
                if(prevSeg != nil){
                    print("Rendering line")
                    
                    let bounds = bitmapView.bounds
                    var previousLocation = prevSeg!.point.toCGPoint();
                    var location = seg.point.toCGPoint()
                        location.y = bounds.size.height - location.y
                        previousLocation.y = bounds.size.height - previousLocation.y
                    
                    let color = seg.color.toCGColor().components;
                    let alpha = seg.alpha;
                    print("alpha = ",alpha);
                    let diameter = seg.diameter;
                    
                    
                    // Defer to the OpenGL view to set the brush color
                    bitmapView.setBrushColor(red:color![0], green: color![1], blue: color![2], alpha: alpha)
                    bitmapView.setBrushDiameter(brushDiameter: diameter)
                

                    
                    bitmapView.renderLine(from:previousLocation, to: location);
                    
                    
                    
                }
                break
                /*case "ARC":
                 let arc = data.0 as! Arc
                 canvasView.drawArc(arc.center, radius: arc.radius, startAngle: arc.startAngle, endAngle: arc.endAngle, w: 10, c: Color(r:0,g:0,b:0))
                 break*/
                
            case "LINE":
                _ = data.0 as! Line
                
                break
                
            case "LEAF":
                _ = data.0 as! StoredDrawing
                
                break
                
            case "FLOWER":
                _ = data.0 as! StoredDrawing
                
                break
                
            case "POLYGON":
                //canvasView.drawPath(stylus.prevPosition, tP:stylus.position, w:10, c:Color(r:0,g:0,b:0))
                break
            default:
                break
                
            }
            break
        case "DELETE":
            
            break
        default : break
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if let touch = touches.first  {
            
            _ = touch.location(in: bitmapView);
            _ = Float(touch.force);
            _ = Float(touch.azimuthAngle(in: bitmapView))
            if(downInCanvas){
                stylus.onStylusUp()
                downInCanvas = false
            }
            // socketManager.sendStylusData(force, position: stylus.position, angle: angle, delta: stylus.position.sub(stylus.prevPosition),penDown:stylus.penDown)
            //socketManager.sendStylusData();
            
        }
        
        
        
    }
    
    
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first  {
            let point = touch.location(in: bitmapView)
            let x = Float(point.x)
            let y = Float(point.y)
            ;
            let force = Float(touch.force);
            let angle = Float(touch.azimuthAngle(in: bitmapView))
                stylus.onStylusDown(x: x, y:y, force:force, angle:angle)
                downInCanvas = true;
            
            // socketManager.sendStylusData(force, position: stylus.position, angle: angle, delta: stylus.position.sub(stylus.prevPosition),penDown:stylus.penDown)
            // socketManager.sendStylusData();
            
            
            // currentCanvas!.hitTest(Point(x:x,y:y),threshold:20);
            
        }
        
    }
    
    
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if let touch = touches.first  {
            
            let point = touch.location(in: bitmapView);
            let x = Float(point.x)
            let y = Float(point.y)
            let force = Float(touch.force);
            let angle = Float(touch.azimuthAngle(in: bitmapView))
            
                stylus.onStylusMove(x: x, y:y, force:force, angle:angle)
                downInCanvas = true;
                
                        // socketManager.sendStylusData(force, position: stylus.position, angle: angle, delta: stylus.position.sub(stylus.prevPosition),penDown:stylus.penDown)
            // socketManager.sendStylusData();
        }
        
    }
    
    
}


