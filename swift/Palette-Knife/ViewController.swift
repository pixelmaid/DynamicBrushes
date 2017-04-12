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

class ViewController: UIViewController {
    
    // MARK: Properties
    
    @IBOutlet weak var dualBrushButton: UIButton!
    @IBOutlet weak var largeBrushButton: UIButton!
    @IBOutlet weak var smallBrushButton: UIButton!
    var canvasViewSm:CanvasView
    var canvasViewLg:CanvasView
    var bakeViewSm:CanvasView
    
    var bakeViewLg:CanvasView
    var backView:UIImageView
    var fabricatorView = FabricatorView();
    // var canvasViewBakeSm:CanvasView;
    // var canvasViewBakeLg:CanvasView;
    
    
    @IBOutlet weak var xOutput: UITextField!
    
    @IBOutlet weak var yOutput: UITextField!
    
    @IBOutlet weak var zOutput: UITextField!
    
    @IBOutlet weak var statusOutput: UITextField!
    
    
    
    var socketManager = SocketManager();
    var behaviorManager: BehaviorManager?
    var currentCanvas: Canvas?
    let socketKey = NSUUID().uuidString
    let drawKey = NSUUID().uuidString
    let brushEventKey = NSUUID().uuidString

    
    var downInCanvas = false;
    
    var radialBrush:Brush?
    var bakeBrush:Brush?
    
    var brushes = [String:Brush]()
    
    required init?(coder: NSCoder) {
        let screenSize = UIScreen.main.bounds
        let sX = (screenSize.width-CGFloat(GCodeGenerator.pX))/2.0
        let sY = (screenSize.height-CGFloat(GCodeGenerator.pY))/2.0
        
        GCodeGenerator.setCanvasOffset(x: Float(sX),y:Float(sY));
        canvasViewSm = CanvasView(frame: CGRect(x:sX, y:sY, width:CGFloat(GCodeGenerator.pX), height:CGFloat(GCodeGenerator.pY)))
        
         canvasViewLg = CanvasView(frame: CGRect(x:sX, y:sY, width:CGFloat(GCodeGenerator.pX), height:CGFloat(GCodeGenerator.pY)))
        
        bakeViewSm = CanvasView(frame: CGRect(x:sX, y:sY, width:CGFloat(GCodeGenerator.pX), height:CGFloat(GCodeGenerator.pY)))
        
         bakeViewLg = CanvasView(frame: CGRect(x:sX, y:sY, width:CGFloat(GCodeGenerator.pX), height:CGFloat(GCodeGenerator.pY)))
         backView = UIImageView(frame: CGRect(x:sX, y:sY, width:CGFloat(GCodeGenerator.pX), height:CGFloat(GCodeGenerator.pY)))
 
        
        super.init(coder: coder);
        
    }
    
    
    override func viewDidLoad() {
        
        
        super.viewDidLoad()
        socketManager.socketEvent.addHandler(target: self,handler: ViewController.socketHandler, key:socketKey)
        socketManager.connect();
        

        
        canvasViewSm.backgroundColor=UIColor.white
        self.view.addSubview(canvasViewSm)
        
        canvasViewLg.backgroundColor=UIColor.clear
        self.view.addSubview(canvasViewLg)
        
        
        bakeViewLg.backgroundColor=UIColor.clear
        self.view.addSubview(bakeViewLg)
        
        bakeViewSm.backgroundColor=UIColor.clear
        self.view.addSubview(bakeViewSm)
        
        backView.backgroundColor=UIColor.white
        self.view.addSubview(backView)
        
        fabricatorView.frame = CGRect(x:0, y:0, width:CGFloat(GCodeGenerator.pX), height:CGFloat(GCodeGenerator.pY))
        fabricatorView.backgroundColor = UIColor.clear;
        self.view.addSubview(fabricatorView);
        self.view.sendSubview(toBack: fabricatorView)
        self.view.sendSubview(toBack: bakeViewLg)
        self.view.sendSubview(toBack: bakeViewSm)

        self.view.sendSubview(toBack: canvasViewLg)
        self.view.sendSubview(toBack: canvasViewSm)
        self.view.sendSubview(toBack: backView)

        canvasViewLg.alpha = 1;
        canvasViewSm.alpha = 0.25;
        
        
        self.fabricatorView.drawFabricatorPosition(x: Float(0), y: Float(0), z: Float(0))
        self.initCanvas()
       // self.initRadialBrush();
       // self.initBakeBrush();

        //radialBrush?.active = false;
        
    }
    
    
    
    //event handler for socket connections
    func socketHandler(data:(String,JSON?), key:String){
        switch(data.0){
        case "first_connection":
            behaviorManager?.loadStandardTemplate();
            break;
        case "disconnected":
            break;
        case "connected":
            break
        case "data_request":
            socketManager.sendBehaviorData(data: behaviorManager!.getAllBehaviorJSON());
            break
        case "authoring_request":
            do{
            let attempt = try behaviorManager!.handleAuthoringRequest(authoring_data: data.1! as JSON);
                var jsonArg = "null";
                if(attempt.2 != nil){
                    jsonArg = (attempt.2?.rawString())!;
                }
                
                socketManager.sendData(data: "{\"type\":\"authoring_response\",\"result\":\""+attempt.1+"\",\"authoring_type\":\""+attempt.0+"\",\"data\":"+jsonArg+"}");
                behaviorManager!.backupBehavior();
            }
            catch{
                print("failed authoring request");
                socketManager.sendData(data: "{\"type\":\"authoring_response\",\"result\":\"error thrown\"}");
            }
            
            break;
        case "fabricator_data":
            let json = data.1! as JSON;
            let x = json["x"].stringValue;
            let y = json["y"].stringValue;
            
            let z = json["z"].stringValue;
            
            let status = json["status"].stringValue;
            
            self.xOutput.text = x;
            self.yOutput.text = y;
            self.zOutput.text = z;
            self.statusOutput.text = status;
            self.fabricatorView.drawFabricatorPosition(x: Float(x)!, y: Float(y)!, z: Float(z)!)
            
            GCodeGenerator.fabricatorX = Float(x);
            GCodeGenerator.fabricatorY = Float(y);
            GCodeGenerator.fabricatorZ = Float(z);
            GCodeGenerator.fabricatorStatus.set(newValue: Float(status)!);
            
            let _x = Numerical.map(value: Float(x)!, istart:0, istop: GCodeGenerator.inX, ostart: 0, ostop: GCodeGenerator.pX)
            
            let _y = Numerical.map(value: Float(y)!, istart:0, istop:GCodeGenerator.inY, ostart:  GCodeGenerator.pY, ostop: 0 )
            let _z = Numerical.map(value: Float(z)!, istart: 0.2, istop: GCodeGenerator.depthLimit, ostart: 0.2, ostop: 42)

            let zFloat:Float = Float(z)!
            if(Float(status)! == 33 && zFloat <= Float(0)){
                currentCanvas?.currentDrawing!.checkBake(x: _x,y:_y,z:_z);
            }
            
            break;
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
        socketManager.initAction(target: currentCanvas!,type:"canvas_init");
        //socketManager.initAction(stylus);
        currentCanvas!.initDrawing();
        currentCanvas!.geometryModified.addHandler(target: self,handler: ViewController.canvasDrawHandler, key:drawKey)
        
        
    }
    
    
     //----------------------------------  HARDCODED BRUSHES ---------------------------------- //
    func initDripBrush(){
        let dripBehavior = behaviorManager?.initDripBehavior();
        let dripBrush = Brush(name:"parentBehavior",behaviorDef: dripBehavior, parent:nil, canvas:self.currentCanvas!)
        socketManager.initAction(target: dripBrush,type:"brush_init");

    }
    
    
    func initBakeBrush(){
        let bake_behavior = behaviorManager?.initBakeBehavior();
        bakeBrush = Brush(name:"bake_brush",behaviorDef: bake_behavior, parent:nil, canvas:self.currentCanvas!)
        socketManager.initAction(target: bakeBrush!,type:"brush_init");
    }
    
 
    func initRadialBrush(){
        let radial_behavior = behaviorManager?.initRadialBehavior();
        radialBrush = Brush(name:"radial",behaviorDef: radial_behavior, parent:nil, canvas:self.currentCanvas!)
        socketManager.initAction(target: radialBrush!,type:"brush_init");

    }
    
   func initFractalBrush(){
        let rootBehavior = behaviorManager?.initFractalBehavior();
        let rootBehaviorBrush = Brush(name:"rootBehaviorBrush",behaviorDef: rootBehavior, parent:nil, canvas:self.currentCanvas!)
        rootBehaviorBrush.strokeColor.b = 255;
        socketManager.initAction(target: rootBehaviorBrush,type:"brush_init");


    }
    
    //---------------------------------- END HARDCODED BRUSHES ---------------------------------- //

    
    
    func canvasDrawHandler(data:(Geometry,String,String), key:String){
        switch data.2{
            
        case "DRAW":
            switch data.1{
            case "SEGMENT":
                let seg = data.0 as! Segment
                
                let prevSeg = seg.getPreviousSegment()
                
                if(prevSeg != nil){
                    
                    canvasViewLg.drawIsolatedPath(fP: prevSeg!.point,tP: seg.point, w:seg.diameter, c:seg.color)
                    
                    
                    
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
                
                _ = touch.location(in: canvasViewSm);
                _ = Float(touch.force);
                _ = Float(touch.azimuthAngle(in: canvasViewSm))
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
            let point = touch.location(in: canvasViewSm)
            let x = Float(point.x)
            let y = Float(point.y)
            ;
            let force = Float(touch.force);
            let angle = Float(touch.azimuthAngle(in: canvasViewSm))
                           if(x>=0 && y>=0 && x<=GCodeGenerator.pX && y<=GCodeGenerator.pY){
                stylus.onStylusDown(x: x, y:y, force:force, angle:angle)
                    downInCanvas = true;
                }
                // socketManager.sendStylusData(force, position: stylus.position, angle: angle, delta: stylus.position.sub(stylus.prevPosition),penDown:stylus.penDown)
                // socketManager.sendStylusData();
                
            
               // currentCanvas!.hitTest(Point(x:x,y:y),threshold:20);
        
        }
        
    }
    
    
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
            if let touch = touches.first  {
                
                let point = touch.location(in: canvasViewSm);
                let x = Float(point.x)
                let y = Float(point.y)
                let force = Float(touch.force);
                let angle = Float(touch.azimuthAngle(in: canvasViewSm))
                if(x>=0 && y>=0 && x<=GCodeGenerator.pX && y<=GCodeGenerator.pY){

                stylus.onStylusMove(x: x, y:y, force:force, angle:angle)
                    downInCanvas = true;

                }
                // socketManager.sendStylusData(force, position: stylus.position, angle: angle, delta: stylus.position.sub(stylus.prevPosition),penDown:stylus.penDown)
                // socketManager.sendStylusData();
            }
        
    }
    
    
}


