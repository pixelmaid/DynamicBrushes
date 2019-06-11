//
//  Brush.swift
//  Palette-Knife
//
//  Created by JENNIFER MARY JACOBS on 5/5/16.
//  Copyright © 2016 pixelmaid. All rights reserved.
//
import Foundation
import SwiftyJSON



class Brush: TimeSeries, Hashable, Renderable{
    public var unrendered: Bool = false;
    
    //hierarcical data
    var children = [Brush]();
    var parent: Brush!
    
    //dictionary to store expressions for emitter->action handlers
    var states = [String:State]();
    var transitions = [String:StateTransition]();
    var currentState:String
    var prevState:String;
    var prevTransition:String;
    let params:BrushStateStorage;
    //geometric/stylistic properties
    let bPosition:Point //actual position
    
    let position:LinkedPoint //settable positon
    let x:Observable<Float>
    let y:Observable<Float>
    
    let polarPosition:LinkedPoint //settable position for polar coordinates
    let theta:Observable<Float>
    let radius:Observable<Float>

    let delta:LinkedPoint
    let dx:Observable<Float>
    let dy:Observable<Float>
    
    let origin:Point;
    let ox:Observable<Float>
    let oy:Observable<Float>
    
    let scaling:Point;
    let sx:Observable<Float>
    let sy:Observable<Float>
    
    let reflectY:Observable<Float>
    let reflectX:Observable<Float>
    let rotation:Observable<Float>
    
    let distance:Observable<Float>
    let xDistance:Observable<Float>
    let yDistance:Observable<Float>
    
    
    var time:Observable<Float>
    let intersections:Observable<Float>
    let index:Observable<Float>
    let level:Observable<Float>

    let siblingcount:Observable<Float>
    
    let weight:Observable<Float>
    let alpha:Observable<Float>
    let hue:Observable<Float>
    let lightness:Observable<Float>
    let saturation:Observable<Float>
    
  /*  let xBuffer:CircularBuffer
    let yBuffer:CircularBuffer
    let weightBuffer:CircularBuffer
    let bufferLimitX:Observable<Float>
    let bufferLimitY:Observable<Float>*/
    
    //list of obeservables (for later disposal)
    
    var currentDrawing:Drawing?
    
    //Events
    var dieEvent = Event<(String)>()
    var signalEvent = Event<(String,String,StateStorage)>()
    //Events
    
    var behavior_id:String?
    var behaviorDef:BehaviorDefinition?
    var matrix = Matrix();
    var deltaKey = NSUUID().uuidString;
    
    var drawKey = NSUUID().uuidString;
    var bufferKey = NSUUID().uuidString;
    let childDieHandlerKey = NSUUID().uuidString;
    var undergoing_transition = false;
    var transitionEvents = [Disposable]();
    var transitionDelayTimer: Timer!;
    
    init(name:String, behaviorDef:BehaviorDefinition?, parent:Brush?, drawing:Drawing){
        
        //==BEGIN OBSERVABLES==//
        self.bPosition = Point(x:0,y:0)
        self.position = LinkedPoint(x:0,y:0)
        self.x = self.position.x;
        self.y = self.position.y;
        self.x.printname = "brush_position_x"
        self.y.printname = "brush_position_y"

        self.position.name = "brush_position";
        
        self.polarPosition = LinkedPoint(x:0,y:0)
        self.radius = self.polarPosition.x;
        self.theta = self.polarPosition.y;
        self.radius.printname = "brush_radius"
        self.theta.printname = "brush_theta"
        
        self.polarPosition.name = "brush_polarPosition";
        
        self.delta = LinkedPoint(x:0,y:0)
        self.dx = delta.x;
        self.dy = delta.y
        self.dx.printname = "brush_delta_x"
        self.dy.printname = "brush_delta_y"

        self.origin = Point(x:0,y:0)
        self.ox = origin.x;
        self.oy = origin.y;
        
        self.scaling = Point(x:100,y:100)
        self.sx = scaling.x;
        self.sy = scaling.y;
        
        self.reflectY = Observable<Float>(0)
        self.reflectX = Observable<Float>(0)
        self.rotation = Observable<Float>(0)
        self.rotation.name = "rotation";
        
        
        self.distance = Observable<Float>(0)
        self.xDistance = Observable<Float>(0)
        self.yDistance = Observable<Float>(0)
        
        self.index = Observable<Float>(0)
        self.level = Observable<Float>(0)
        self.siblingcount = Observable<Float>(0)
        self.intersections = Observable<Float>(0)
        self.time = Observable<Float>(0)
        
        self.weight = Observable<Float>(1)
        self.weight.printname = "brush_diameter"
        self.weight.name = "diameter";

        self.alpha = Observable<Float>(100)
        self.hue = Observable<Float>(100)
        self.lightness = Observable<Float>(100)
        self.saturation = Observable<Float>(100)
        
        /*self.xBuffer = CircularBuffer(id:id+"_xBuffer")
        self.yBuffer = CircularBuffer(id:id+"_yBuffer")
        self.weightBuffer = CircularBuffer(id:id+"_weightBuffer")
 
       self.bufferLimitX = Observable<Float>(0)
        self.bufferLimitY = Observable<Float>(0)*/
        //==END OBSERVABLES==//
        
        
        self.currentState = "start";
        self.prevState = "null";
        self.prevTransition = "null";
        self.params = BrushStateStorage();
        
        super.init()
        
        //TODO: this code is annoying because KVC assigment issues. Find a fix?
        self.time = _time
        
        self.kvcDictionary["x"] = self.x;
        self.kvcDictionary["y"] = self.y;
        self.kvcDictionary["theta"] = self.theta;
        self.kvcDictionary["radius"] = self.radius;
        self.kvcDictionary["dx"] = self.dx;
        self.kvcDictionary["dy"] = self.dy;
        self.kvcDictionary["ox"] = self.ox;
        self.kvcDictionary["oy"] = self.oy;
        self.kvcDictionary["sx"] = self.sx;
        self.kvcDictionary["sy"] = self.sy;
        self.kvcDictionary["reflectX"] = self.reflectX;
        self.kvcDictionary["reflectY"] = self.reflectY;
        self.kvcDictionary["rotation"] = self.rotation;
        self.kvcDictionary["distance"] = self.distance;
        self.kvcDictionary["xDistance"] = self.xDistance;
        self.kvcDictionary["yDistance"] = self.yDistance;
        self.kvcDictionary["time"] = self.time;
        self.kvcDictionary["intersections"] = self.intersections;
        self.kvcDictionary["index"] = self.index;
        self.kvcDictionary["level"] = self.level;
        self.kvcDictionary["siblingcount"] = self.siblingcount;
        self.kvcDictionary["diameter"] = self.weight;
        self.kvcDictionary["alpha"] = self.alpha;
        self.kvcDictionary["hue"] = self.hue;
        self.kvcDictionary["lightness"] = self.lightness;
        self.kvcDictionary["saturation"] = self.saturation;
        
        
        //==BEGIN APPEND OBSERVABLES==//
        observables.append(bPosition)
        observables.append(delta)
        observables.append(position)
        observables.append(polarPosition)

        observables.append(origin)
        observables.append(scaling)
        
        observables.append(reflectY);
        observables.append(reflectX);
        observables.append(rotation);
        
        observables.append(distance)
        observables.append(xDistance)
        observables.append(yDistance)
        
        observables.append(index)
        observables.append(siblingcount)
        observables.append(level)

        
        observables.append(weight)
        observables.append(alpha)
        observables.append(hue)
        observables.append(lightness)
        observables.append(saturation)
        
       /* observables.append(xBuffer);
        observables.append(yBuffer);
        observables.append(weightBuffer);
        
        observables.append(bufferLimitX)
        observables.append(bufferLimitY)*/
        //==END APPØEND OBSERVABLES==//
        
        
        self.behavior_id = behaviorDef!.id;
        self.behaviorDef = behaviorDef;
        
        
        self.name = name;
        
     
        
        
        //setup listener for delta observable
        _ = self.delta.didChange.addHandler(target: self, handler:Brush.deltaChange, key:deltaKey)
        _ = self.position.didChange.addHandler(target: self, handler:Brush.positionChange, key:deltaKey)
        _ = self.polarPosition.didChange.addHandler(target: self, handler:Brush.polarPositionChange, key:deltaKey)

       // _ = self.xBuffer.bufferEvent.addHandler(target: self, handler: Brush.deltaBufferLimitReached, key: bufferKey)
        
        
        self.setDrawingTarget(drawing: drawing)
        self.parent = parent
        
        //setup behavior
        if(behaviorDef != nil){
            behaviorDef?.addBrush(targetBrush: self)
        }
        self.delta.name = "delta_"+self.id;
    }
    
    
    func storeInitialValues(){
        
        let paramData = ["dx": 0, "dy": 0, "pr": 0, "pt": 0, "ox": 0, "oy": 0, "rotation": 0, "sx": 0, "sy": 0, "weight": 1, "hue": 100, "saturation": 100, "lightness": 100, "alpha": 100, "dist": 0, "xDist": 0, "yDist": 0, "x": 0, "y": 0, "cx":0, "cy":0, "time": 0, "i": self.index.getSilent(), "sc": self.siblingcount.getSilent(), "lv": self.level.getSilent(), "parent": "none", "active":true] as [String : Any]
        self.params.updateAll(data: paramData)
        self.signalEvent.raise(data: (self.behavior_id!,self.id,self.params));
    }
 
    func setupTransition(){
        
        let setupTransition = self.getTransitionByName(name: "setup");
        if(setupTransition != nil && (setupTransition?.condition.evaluate())!){
            
            self.transitionToState(transition: setupTransition!)
            print("$$ setup data generated");

        }
        else{
            #if DEBUG
                print("setup transition does not exist for \(self.id)");
            #endif
        }
    }
    
    //MARK: - Hashable
    var hashValue : Int {
        get {
            return "\(self.id)".hashValue
        }
    }
    
    func createState(id:String,name:String){
        states[id] = State(id:id,name:name);
    }
    
    
    func deltaBufferLimitReached(data:(String), key:String){
       // bufferLimitX.set(newValue: 1)
    }
    
    func positionChange(data:(String,(Float,Float),(Float,Float)),key:String){
        #if DEBUG
           // print("position change called",self.index.get(id:nil),self.position.get(id: nil));
        #endif
        if(!self.undergoing_transition){
            let polarCoordinates = MathUtil.cartToPolar(x1: self.origin.x.getSilent(), y1: self.origin.x.getSilent(), x2: self.position.x.getSilent(), y2: self.position.y.getSilent());
            self.polarPosition.x.setSilent(newValue: polarCoordinates.0);
            self.polarPosition.y.setSilent(newValue: polarCoordinates.1);
            let calculatedDelta = self.position.sub(point: Point(x:data.1.0,y:data.1.1));
            self.delta.x.setSilent(newValue: calculatedDelta.x.get(id: nil));
            self.delta.y.setSilent(newValue: calculatedDelta.y.get(id: nil));
            self.calculateProperties();
        
        }
    }
    
    func polarPositionChange(data:(String,(Float,Float),(Float,Float)),key:String){
        
          #if DEBUG
            //print("polar change called");
        #endif
        if(!self.undergoing_transition){
            let t =  MathUtil.map(value: self.polarPosition.y.get(id: nil),low1: 0,high1: 100,low2: 0,high2: 360);
            let cartPos = MathUtil.polarToCart(r: self.polarPosition.x.get(id: nil),theta:t);
            let calculatedPosition = Point(x:cartPos.0+self.origin.x.get(id: nil),y:cartPos.1+self.origin.y.get(id: nil));
            self.position.x.setSilent(newValue: calculatedPosition.x.getSilent());
            self.position.y.setSilent(newValue: calculatedPosition.y.getSilent());
            let calculatedDelta = calculatedPosition.sub(point: self.bPosition)
            self.delta.x.setSilent(newValue: calculatedDelta.x.get(id: nil));
            self.delta.y.setSilent(newValue: calculatedDelta.y.get(id: nil));
            self.calculateProperties();
            
        }
        
        
    }

    
    
    func deltaChange(data:(String,(Float,Float),(Float,Float)),key:String){
        let calculatedPosition = self.position.clone().add(point: self.delta);
        self.position.x.setSilent(newValue: calculatedPosition.x.getSilent());
        self.position.y.setSilent(newValue: calculatedPosition.y.getSilent());
        let polarCoordinates = MathUtil.cartToPolar(x1: self.origin.x.getSilent(), y1: self.origin.x.getSilent(), x2: calculatedPosition.x.getSilent(), y2: calculatedPosition.y.getSilent());
        self.polarPosition.x.setSilent(newValue: polarCoordinates.0);
        self.polarPosition.y.setSilent(newValue: polarCoordinates.1);
        self.calculateProperties();
        
        
    }
    
    func calculateProperties(){
        
        let dx = delta.x.get(id:nil);
        let dy = delta.y.get(id:nil);
        
        let ox = self.ox.getSilent();
        let oy = self.oy.getSilent();
        
        let x = self.x.get(id:nil);
        let y = self.y.get(id:nil);
        
        let r =  self.rotation.get(id:nil); //MathUtil.map(value: self.rotation.get(id:nil), low1: 0.0, high1: 100.0, low2: 0.0, high2: 360.0)
        
        let sx = self.scaling.x.get(id:nil)
        let sy = self.scaling.y.get(id:nil)
        
      
        let weight = self.weight.get(id:nil);
        
        
       /* let h =   MathUtil.map(value: self.hue.get(id:nil), low1: 0.0, high1: 100.0, low2: 0.0, high2: 1.0)
        
        let s = MathUtil.map(value: self.saturation.get(id:nil), low1: 0.0, high1: 100.0, low2: 0.0, high2: 1.0)
        
        let l = MathUtil.map(value: self.lightness.get(id:nil), low1: 0.0, high1: 100.0, low2: 0.0, high2: 1.0)
        let mapped_alpha = pow(1.054,self.alpha.get(id:nil))*0.54
        let a = MathUtil.map(value: mapped_alpha, low1: 0.0, high1: 100.0, low2: 0.0, high2: 1.0)*/
        
        let h =  self.hue.get(id:nil);
        let s = self.saturation.get(id:nil);
        let l = self.lightness.get(id:nil);
        let a = self.alpha.get(id:nil);
        
        let color = Color(h: h, s: s, l:l, a: 1)
        
        let dist = self.distance.get(id:nil);
        let xDist = self.xDistance.get(id:nil);
        let yDist = self.yDistance.get(id:nil);
        
       
        let pr = self.polarPosition.x.get(id: nil);
        let pt = self.polarPosition.y.get(id: nil);
        
        
        self.distance.set(newValue: dist + sqrt(pow(dx,2)+pow(dy,2)));
        self.xDistance.set(newValue: xDist + abs(dx));
        self.yDistance.set(newValue: yDist + abs(dy));
        self.time.set(newValue:self.time.get(id: nil)+1);
        
        let transformedCoords = self.calculateMatrixTransform(ox: ox,oy: oy,dx: dx,dy: dy,sx: sx,sy: sy,rotation: r);

        let cx = transformedCoords.0
        let cy = transformedCoords.1
        
        let data = ["dx":dx,"dy":dy,"pr":pr,"pt":pt,"ox":ox,"oy":oy,"rotation":r,"sx":sx,"sy":sy,"weight":weight,"hue":h,"saturation":s,"lightness":l,"alpha":a,"dist":dist,"xDist":xDist,"yDist":yDist,"x":x,"y":y,"cx":cx,"cy":cy,"time":self.time.getSilent(),"i":self.index.getSilent(),"sc":self.siblingcount.getSilent(),"lv":self.level.getSilent(),"parent": (self.parent != nil ? (self.parent!.behaviorDef?.name)! : "none"), "active":true] as [String : Any];
        self.params.updateAll(data: data);
        
        
        self.currentDrawing!.addSegmentToStroke(parentID: self.id, point:Point(x:cx,y:cy),weight:weight , color: color,alpha:a)
        self.unrendered = true;
        
        self.bPosition.x.setSilent(newValue: cx)
        self.bPosition.y.setSilent(newValue:cy)
        
        // self.distanceIntervalCheck();
        //self.intersectionCheck();
        
        self.signalEvent.raise(data: (self.behavior_id!,self.id,self.params));
        
        Debugger.generateBrushDebugData(brush: self, type: "DRAW_SEGMENT");

    }

    
    func calculateMatrixTransform(ox:Float,oy:Float,dx:Float,dy:Float,sx:Float,sy:Float,rotation:Float)->(Float,Float){
      
        let ox = self.origin.x.get(id:nil);
        let oy =  self.origin.y.get(id:nil);
        
        self.matrix.reset();
        if(self.parent != nil){
            self.matrix.prepend(mx: self.parent!.matrix)
        }
        
    
        self.matrix.scale(x: sx/100, y: sy/100, centerX: ox, centerY: oy);
        self.matrix.rotate(_angle: rotation, centerX: ox, centerY: oy)
        
        
        let _dx = self.position.x.get(id:nil) + dx;
        let _dy = self.position.y.get(id:nil) + dy;
        let transformedCoords = self.matrix.transformPoint(x: _dx, y: _dy)
        
        return transformedCoords;
        
    }
    
    func intersectionCheck(){
       // let bpx = bPosition.x.get(id: nil);
       // let bpy = bPosition.y.get(id: nil);
        
        
        if((keyStorage["INTERSECTION"]!.count)>0){
            if(self.parent != nil){
                let hit = self.currentDrawing!.parentHitTest(point: self.bPosition, threshold: 5, id:self.id, parentId:self.parent!.id);
            if(hit != nil){
                self.intersections.set(newValue: self.intersections.getSilent()+1);
                for key in keyStorage["INTERSECTION"]!
                {
                    if(key.1 != nil){
                        let condition = key.1;
                        let evaluation = condition?.evaluate();
                        if(evaluation == true){
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: key.0), object: self, userInfo: ["emitter":self,"key":key.2.id,"event":"INTERSECTION"])
                        }
                    }
                    else{
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: key.0), object: self, userInfo: ["emitter":self,"key":key.2.id,"event":"INTERSECTION"])
                    }
                    
                }
            }
         }
        }
    }
    
    func distanceIntervalCheck()
    {
        
        for key in keyStorage["DISTANCE_INTERVAL"]!
        {
            if(key.1 != nil){
                let condition = key.1;
                let evaluation = condition?.evaluate();
                if(evaluation == true){
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: key.0), object: self, userInfo: ["emitter":self,"key":key.2.id,"event":"DISTANCE_INTERVAL"])
                }
            }
            else{
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: key.0), object: self, userInfo: ["emitter":self,"key":key.2.id,"event":"DISTANCE_INTERVAL"])
            }
            
        }
        
    }
    
    
  
        
    func setOrigin(x:Float,y:Float){
        self.origin.set(x:x,y:y);
        let pol = MathUtil.cartToPolar(x1: 0, y1: 0, x2: x, y2: y)
        self.polarPosition.x.setSilent(newValue: pol.0);
        self.polarPosition.y.setSilent(newValue: pol.1);
        self.position.x.setSilent(newValue: self.origin.x.get(id: nil))
        self.position.y.setSilent(newValue: self.origin.y.get(id: nil))
        self.bPosition.x.setSilent(newValue: self.origin.x.get(id: nil))
        self.bPosition.y.setSilent(newValue: self.origin.y.get(id: nil))
        #if DEBUG
            //print("origin set =",stylus.x.get(id:nil),p.x.get(id: nil),p.y.get(id:nil));
        #endif
        
    }
    
    func stateTransitionHandler(data:(String),key:String){
        guard let stateTransition = validateTransitionMapping(key:key) else{
            return;
        }
        self.transitionToState(transition: stateTransition)

    }
    func validateTransitionMapping(key:String)->StateTransition?{
        let mapping = states[currentState]?.getTransitionMapping(key: key)
        if(mapping != nil){
            let stateTransition = mapping
            return stateTransition;
        }
        return nil
        
    }
    
    func transitionToState(transition:StateTransition){
        
        if(states[transition.toStateId]?.name == "die"){
            Debugger.generateBrushDebugData(brush:self, type:"STATE_DIE");
            self.die();
           
        }
      
         //#if DEBUG
        //print("transitioning from state:\(currentState) to state: \(transition.toStateId)");
       // #endif
        else{
        if(states[currentState] != nil){
            let constraint_mappings =  states[currentState]!.constraint_mappings
            for (_, value) in constraint_mappings{
                
         
                value.relativeProperty.constrained = false;
                
            }
        }
        self.prevState = self.currentState;
        self.currentState = transition.toStateId;
        if(states[currentState] != nil){
            
        //TODO: add methods to debug data
        self.executeTransitionMethods(methods: transition.methods)
        }
            self.prevTransition = transition.id;

      
        //execute methods
        //check constraints
     
            
            
        //trigger state complete after functions are executed
            if(transitionDelayTimer != nil){
                transitionDelayTimer.invalidate();
            }
       transitionDelayTimer  = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(Brush.completeCallback), userInfo: nil, repeats: false)
     
            
        }
        
        Debugger.generateBrushDebugData(brush:self, type:"STATE_TRANSITION");

        
    }
    

    @objc func completeCallback(){
        let constraint_mappings =  states[currentState]!.constraint_mappings
        for (_, value) in constraint_mappings{
            value.relativeProperty.constrained = true;
            self.setConstraint(constraint: value);

        }
        //TODO: This creates an endless loop on debug step. Need to address this.

       /* for (key,tTransition) in self.transitions{
            
            let validate = self.validateTransitionMapping(key:key)
            let evaluate =  tTransition.condition.evaluate()
            if validate != nil && evaluate == true {
                self.transitionToState(transition: tTransition)
                return;
                
            }
        }*/
    }
    
    
    
    func executeTransitionMethods(methods:[Method]){
        
        for i in 0..<methods.count{
            let method = methods[i];
            let methodName = method.fieldName;
            
            #if DEBUG
               // print("executing method:\(method.fieldName,self.id,self.name,method.arguments)");
            #endif
            switch (methodName){
            case "newStroke",
                 "setOrigin":
                let xArg = method.arguments[0];
                let yArg = method.arguments[1];
                let x = xArg.calculateValue();
                let y = yArg.calculateValue();
                if(x != nil && y != nil){
                    self.setOrigin(x:x!, y: y!)
                }
                if(methodName == "newStroke"){
                    self.newStroke();
                }
                break;
            case "startTimer":
                self.startInterval();
                break;
            case "stopTimer":
                self.stopInterval();
                break;
            case "destroy":
                self.destroy();
                break;
            case "spawn":
                let behaviorArg = method.arguments[0] as! DropdownExpression;
                let countArg = method.arguments[1];
                let arg_string = behaviorArg.getSelectedId();
                let behavior = BehaviorManager.getBehaviorById(id:arg_string);
                
                let count = countArg.calculateValue();
                if(count != nil){
                    self.spawn(behavior:behavior!,num:Int(count!));
                }
                
                break;
            default:
                break;
            }
        }
        
    }
    
    override func startInterval(){
        #if DEBUG
           // print("start interval")
        #endif
        self.stopInterval();

        intervalTimer  = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(Brush.timerIntervalCallback), userInfo: nil, repeats: true)
        
    }
    
    override func stopInterval() {
    
            #if DEBUG
                // print("stop interval")
            #endif
            
            if(intervalTimer != nil){
                #if DEBUG
                    // print("invalidate timer")
                #endif
                intervalTimer.invalidate();
            }
        timer = NSDate();
        self.time.set(newValue: 0);

        

    }
    
    @objc override func timerIntervalCallback()
    {
        
        let currentTime = NSDate();
        //TODO: Fix how this is calucated to deal with lag..
        let t = Float(currentTime.timeIntervalSince(timer as Date))
        self.time.set(newValue: t*1000);
        #if DEBUG
            //print("current time is",self.time.getSilent());
        #endif
        
        //todo: create persistent storage of values
        //var sendDs = params;
        //sendDs.time = self.time.get(id: nil);
        //self.signalEvent.raise(data: (self.behavior_id!,self.id,sendDs));
    }
    
    //sets canvas target to output geometry into
    func setDrawingTarget(drawing:Drawing){
        self.currentDrawing = drawing;
    }
    
    
    /* addConstraint
     //adds a property mapping constraint.
     //property mappings can take two forms, active and passive
     //active: when reference changes, relative is updated to reflect change. This is for properties which are updated manually by the artist
     //like the stylus properties, or properties with an internal interval, like a timed buffer
     //passive: this for constraints which are not actively modifed by an interval or an external change. This can include constants
     //or generators and buffers which will return a new value each time they are accessed
     */
    func addConstraint(id:String,reference:Observable<Float>, relative:Observable<Float>, stateId:String){
       
        /*#if DEBUG
            if let expref = reference as? TextExpression{
                for (_, val) in expref.operandList{
                print("reference,relative",val.printname,relative.printname)
                }
            }
        #endif*/
        let active = reference.isLive()
        let type:String
        if(active){
           type = "active"
            _ = reference.didChange.addHandler(target: self, handler:  Brush.setHandler, key:id)
        }
            
        else{
            type = "passive"
            relative.passiveConstrain(target: reference);
        }
        
        states[stateId]!.addConstraintMapping(key: id,reference:reference,relativeProperty: relative,type:type)
    }
    
    
    
    
    
    //setHandler: triggered when constraint is changed, evaluates if brush is in correct state to encact constraint
    func setHandler(data:(String,Float,Float),stateKey:String){
        // let reference = notification.userInfo?["emitter"] as! Emitter
        
        
        let mapping = states[currentState]?.getConstraintMapping(key: stateKey)
        
        if(mapping != nil){
            
            //let constraint = mapping as! Constraint
            self.setConstraint(constraint: mapping!)
        }
        
    }
    
    func childDieHandler(data:(String),key:String){
        let id = data;
        for c in children.reversed(){
            if c.id == id{
               // _ = self.removeChildAt(index: Int(c.index.get(id: nil)))
            }
        }
        for i in 0..<children.count{
            //self.children[i].index.set(newValue: Float(i));
        }
    }
    
    
    func setConstraint(constraint:Constraint){
        #if DEBUG
          // print("calling set constraint on",  constraint.relativeProperty.name,constraint.relativeProperty,constraint.reference.get(id: self.id))
        #endif
        constraint.relativeProperty.set(newValue: constraint.reference.get(id: self.id));
        
        
        
    }
    
    func addStateTransition(id:String, name:String, condition:Condition, fromStateId: String, toStateId:String){
        
        let transition:StateTransition
        let state = self.states[fromStateId]
        transition = state!.addStateTransitionMapping(id: id,name:name,condition: condition, toStateId:toStateId);
        self.transitions[id] = transition;
        let transitionEvent = transition.didTrigger.addHandler(target: self, handler: Brush.stateTransitionHandler, key: id);
        self.transitionEvents.append(transitionEvent);
    }
    
    func removeStateTransition(data:(Brush, String, Emitter),key:String){
        NotificationCenter.default.removeObserver(data.0, name: NSNotification.Name(rawValue: data.1), object: data.2)
        data.2.removeKey(key: data.1)
    }
    
    func addMethod(transitionId:String, methodId:String, fieldName:String, arguments:[Expression]){
        let transition = transitions[transitionId];

        if (transition != nil) {
            (transition!).addMethod(id: methodId, fieldName:fieldName, arguments:arguments)
        }
        
        
    }
    
    func getTransitionByName(name:String)->StateTransition?{
        for(_,transition) in self.transitions{
            if(transition.name == name){
                return transition;
            }
        }
        return nil
    }
    
    func getStateByName(name:String)->State?{
        for(_,state) in self.states{
            if(state.name == name){
                return state;
            }
        }
        return nil
    }
    
    
    func removeTransition(key:String){
        for (key,val) in states {
            if(val.hasTransitionKey(key: key)){
                let transition =  val.removeTransitionMapping(key: key)!
                transition.destroy();
                break
            }
        }
    }
    
    func resetDistance(){
        self.distance.set(newValue: 0);
        self.xDistance.set(newValue: 0);
        self.yDistance.set(newValue: 0)
        
      
    }
    
    
    
    //===============METHODS AVAILABLE TO USER===============//
    
    
    
    func newStroke(){
        self.currentDrawing!.retireCurrentStrokes(parentID: self.id)
        self.currentDrawing!.newStroke(parentID: self.id);
        self.resetDistance();
    }
    
    //creates number of clones specified by num and adds them as childre    n
    func spawn(behavior:BehaviorDefinition,num:Int) {

        if(num > 0){
            for _ in 0...num-1{
                let child = Brush(name:name, behaviorDef: behavior, parent:self, drawing:self.currentDrawing!)
                self.children.append(child);
              
                child.index.set(newValue: Float(self.children.count-1));
                #if DEBUG
                    print("spawn called, new index is:",child.index.get(id:nil),"of",(self.children.count))
                #endif
                child.level.set(newValue: Float(self.level.get(id: nil)+1));
               
                behavior.initBrushBehavior(targetBrush: child);
                _ = child.dieEvent.addHandler(target: self, handler: Brush.childDieHandler, key: childDieHandlerKey)
            }
            
            for c in children{
                c.siblingcount.set(newValue: Float(self.children.count))
            }
            
            
        }
    }
    
  
    
    //=============END METHODS AVAILABLE TO USER==================//
    
    
    
    
    //========= CLEANUP METHODS ==================//
    //removes child at an index and returns it
    // removes listener on child, but does not destroy it
    func removeChildAt(index:Int)->Brush{
        let child = self.children.remove(at: index)
        return child
    }
    
    
    func die(){
        self.dieEvent.raise(data:(self.id));
        self.destroy();
    }
    
    
    func destroyChildren(){
        for child in self.children as [Brush] {
            child.destroy();
            
        }
        self.children.removeAll();
    }
    
    func clearBehavior(){
        for (_,state) in self.states{
            let removedTransitions = state.removeAllTransitions();
            for i in 0..<removedTransitions.count{
                let transition = removedTransitions[i]
                transition.destroy();
            }
            
            state.removeAllConstraintMappings(brush:self);
        }
        self.transitions.removeAll();
        self.states.removeAll();
    }
    
    
    func clearAllEventHandlers(){
        self.signalEvent.removeAllHandlers();
        self.dieEvent.removeAllHandlers()
        for t in transitionEvents{
            t.dispose();
        }
    }
    
    override func destroy() {
        self.stopInterval();
        self.params.update(key:"active",value:false);
        if(transitionDelayTimer != nil){
            transitionDelayTimer.invalidate();
        }
        #if DEBUG
            print("destroying brush: \(self.id)");
        #endif
        currentDrawing!.retireCurrentStrokes(parentID: self.id)
        self.clearBehavior();
        self.clearAllEventHandlers();
        super.destroy();
    }
    //========= END CLEANUP METHODS ==================//
    
}


// MARK: Equatable
func ==(lhs:Brush, rhs:Brush) -> Bool {
    return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
}


