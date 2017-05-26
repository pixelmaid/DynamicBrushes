//
//  Brush.swift
//  Palette-Knife
//
//  Created by JENNIFER MARY JACOBS on 5/5/16.
//  Copyright © 2016 pixelmaid. All rights reserved.
//
import Foundation

struct DeltaStorage{
    var dX = Float(0)
    var dY = Float(0)
    //var pX = Float(0)
    //var pY = Float(0)
    //var oX = Float(0)
    //var oY = Float(0)
    var r = Float(0)
    var sX = Float(0)
    var sY = Float(0)
    var rX = Float(0)
    var rY = Float(0)
    var d = Float(0)
    var h = Float(0)
    var s = Float(0)
    var l = Float(0)
    var a = Float(0)
    var dist = Float(0);
    var xDist = Float(0);
    var yDist = Float(0);
}

class Brush: TimeSeries, WebTransmitter, Hashable{
    
    //hierarcical data
    var children = [Brush]();
    var parent: Brush!
    
    //dictionary to store expressions for emitter->action handlers
    var states = [String:State]();
    var transitions = [String:StateTransition]();
    var currentState:String
    
    //geometric/stylistic properties
    let bPosition:Point //actual position
    
    let position:Point //settable positon
    let x:Observable<Float>
    let y:Observable<Float>
    
    let delta:Point
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
    let siblingcount:Observable<Float>
    
    let diameter:Observable<Float>
    let alpha:Observable<Float>
    let hue:Observable<Float>
    let lightness:Observable<Float>
    let saturation:Observable<Float>
    
    let xBuffer:CircularBuffer
    let yBuffer:CircularBuffer
    let weightBuffer:CircularBuffer
    let bufferLimitX:Observable<Float>
    let bufferLimitY:Observable<Float>
    
    //list of obeservables (for later disposal)
    
    var currentCanvas:Canvas?
    var currentStroke:Stroke?
   
    //Events
    var geometryModified = Event<(Geometry,String,String)>()
    var transmitEvent = Event<(String)>()
    var initEvent = Event<(WebTransmitter,String)>()
    var dieEvent = Event<(String)>()
    
    let removeMappingEvent = Event<(Brush,String,Observable<Float>)>()
    let removeTransitionEvent = Event<(Brush,String,Emitter)>()
    //Events
    
    
    var id = NSUUID().uuidString;
    var behavior_id:String?
    var behaviorDef:BehaviorDefinition?
    var matrix = Matrix();
    var deltaKey = NSUUID().uuidString;
    
    var drawKey = NSUUID().uuidString;
    var bufferKey = NSUUID().uuidString;
    let childDieHandlerKey = NSUUID().uuidString;
    var deltaChangeBuffer = [DeltaStorage]();
    var undergoing_transition = false;
   
    init(name:String, behaviorDef:BehaviorDefinition?, parent:Brush?, canvas:Canvas){
       
        //==BEGIN OBSERVABLES==//
        self.bPosition = Point(x:0,y:0)
         self.position = Point(x:0,y:0)
        self.x = self.position.x;
        self.y = self.position.y;
        self.position.name = "brush_position";
        
        self.delta = Point(x:0,y:0)
        self.dx = delta.x;
        self.dy = delta.y
        
        self.origin = Point(x:0,y:0)
        self.ox = origin.x;
        self.oy = origin.y;
        
        self.scaling = Point(x:1,y:1)
        self.sx = scaling.x;
        self.sy = scaling.y;
        
        self.reflectY = Observable<Float>(0)
        self.reflectX = Observable<Float>(0)
        self.rotation = Observable<Float>(0)
        
        self.distance = Observable<Float>(0)
        self.xDistance = Observable<Float>(0)
        self.yDistance = Observable<Float>(0)
        
        self.index = Observable<Float>(0)
        self.siblingcount = Observable<Float>(0)
        self.intersections = Observable<Float>(0)
        self.time = Observable<Float>(0)
        
        self.diameter = Observable<Float>(1)
        self.alpha = Observable<Float>(1)
        self.hue = Observable<Float>(0.5)
        self.lightness = Observable<Float>(0.25)
        self.saturation = Observable<Float>(1)
        
        self.xBuffer = CircularBuffer()
        self.yBuffer = CircularBuffer()
        self.weightBuffer = CircularBuffer()

        self.bufferLimitX = Observable<Float>(0)
        self.bufferLimitY = Observable<Float>(0)
        //==END OBSERVABLES==//


        self.currentState = "start";

       super.init()
        
        //TODO: this code is annoying because KVC assigment issues. Find a fix?
        self.time = _time
        //==BEGIN APPEND OBSERVABLES==//
        observables.append(bPosition)
        observables.append(delta)
        observables.append(position)

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

        
        observables.append(diameter)
        observables.append(alpha)
        observables.append(hue)
        observables.append(lightness)
        observables.append(saturation)

        observables.append(xBuffer);
        observables.append(yBuffer);
        observables.append(weightBuffer);
        
        observables.append(bufferLimitX)
        observables.append(bufferLimitY)
        //==END APPEND OBSERVABLES==//

        
        self.behavior_id = behaviorDef!.id;
        self.behaviorDef = behaviorDef;
        
        
        self.name = name;
        
        //setup events and create listener storage
        self.events =  ["SPAWN", "STATE_COMPLETE", "DELTA_BUFFER_LIMIT_REACHED", "DISTANCE_INTERVAL", "INTERSECTION"]
        self.createKeyStorage();
        
        
        //setup listener for delta observable
        _ = self.delta.didChange.addHandler(target: self, handler:Brush.deltaChange, key:deltaKey)
        _ = self.position.didChange.addHandler(target: self, handler:Brush.positionChange, key:deltaKey)

        _ = self.xBuffer.bufferEvent.addHandler(target: self, handler: Brush.deltaBufferLimitReached, key: bufferKey)
        
      
        self.setCanvasTarget(canvas: canvas)
        self.parent = parent
        
        //setup behavior
        if(behaviorDef != nil){
            behaviorDef?.addBrush(targetBrush: self)
        }
        self.delta.name = "delta_"+self.id;
    }
    
    
    //creates states and transitions for global actions and mappings
    func createGlobals(){
        let _ = self.createState(id: "global",name: "global");
        let globalEmitter = Emitter();
        self.addStateTransition(id: "globalTransition", name: "globalTransition", reference: globalEmitter, fromStateId: "global", toStateId: "global")

    }
    
    
    
    
    func setupTransition(){
        
        let setupTransition = self.getTransitionByName(name: "setup");
        if(setupTransition != nil){
            //print("setup transition called for \(self.id),\(self.index.get(id:nil))");

            self.transitionToState(transition: setupTransition!)
        }
        else{
            //print("no setup transition called for \(self.id),\(self.index.get(id:nil))");
        }
    }
    
    //MARK: - Hashable
    var hashValue : Int {
        get {
            return "\(self.id)".hashValue
        }
    }
    
    //Event handlers
    //chains communication between brushes and view controller
    func brushDrawHandler(data:(Geometry,String,String),key:String){
        self.geometryModified.raise(data: data)
    }
    
    func createState(id:String,name:String){
        states[id] = State(id:id,name:name);
    }
    
    
    func deltaBufferLimitReached(data:(String), key:String){
        bufferLimitX.set(newValue: 1)
    }
    
    func positionChange(data:(String,(Float,Float),(Float,Float)),key:String){
      if(!undergoing_transition){
        let delta = self.position.sub(point: self.bPosition)
        print("position changed",stylus.x.get(id:nil),self.position.x.get(id: nil),self.position.y.get(id:nil),self.bPosition.x.get(id: nil),self.bPosition.y.get(id:nil));
        //TODO: this is hacky- fix?
        self.delta.x.setSilent(newValue:delta.x.get(id: nil));
        self.delta.y.setSilent(newValue:delta.y.get(id: nil));
        self.delta.invalidate(oldValue: (0,0), newValue: (0,0))
        }
        
        
    }
    
    func deltaChange(data:(String,(Float,Float),(Float,Float)),key:String){
        if(!undergoing_transition){
        let dX = self.dx.get(id:nil)
        let dY = self.dy.get(id:nil)
        print("delta change",dX,dY)

        //let pX = self.position.x.get(id:nil);
        //let pY = self.position.y.get(id:nil);
        
        //let oX = self.origin.x.get(id:nil)
        //let oY = self.origin.y.get(id:nil)
        
        let r = self.rotation.get(id:nil)
        
        let sX = self.scaling.x.get(id:nil)
        let sY = self.scaling.y.get(id:nil)
        
        let rX = self.reflectX.get(id:nil)
        let rY = self.reflectY.get(id:nil)
        
        let d = self.diameter.get(id:nil)
        let h = self.hue.get(id:nil)
        let s = self.saturation.get(id:nil)
        let l = self.lightness.get(id:nil)
        let a = self.alpha.get(id:nil)

        let dist = self.distance.get(id:nil);
        let xDist = self.xDistance.get(id:nil);
        let yDist = self.yDistance.get(id:nil);
            
        let ds = DeltaStorage(dX:dX,dY:dY,r:r,sX:sX,sY:sY,rX:rX,rY:rY,d:d,h:h,s:s,l:l,a:a,dist:dist,xDist:xDist,yDist:yDist)
        
          objc_sync_enter(deltaChangeBuffer)
                self.deltaChangeBuffer.append(ds);
                self.processDeltaBuffer();
          objc_sync_exit(deltaChangeBuffer)
        }
        
    }
    
    func processDeltaBuffer(){
        objc_sync_enter(deltaChangeBuffer)
        var ds:DeltaStorage! = nil
        if(deltaChangeBuffer.count>0){
            ds = deltaChangeBuffer.remove(at: 0);
        }
        objc_sync_exit(deltaChangeBuffer)
        if(ds == nil){
            return;
        }
        //  print("angle\(self.angle.get(nil),self.index.get(nil)))")
        let centerX = self.origin.x.get(id:nil)
        let centerY =  self.origin.y.get(id:nil)
        
        self.matrix.reset();
        if(self.parent != nil){
            self.matrix.prepend(mx: self.parent!.matrix)
        }
        var xScale = ds.sX
        
        if(ds.rX == 1){
            
            xScale *= -1.0;
        }
        var yScale = ds.sY
        if(ds.rY == 1){
            yScale *= -1.0;
        }
        let r = ds.r
        self.matrix.scale(x: xScale, y: yScale, centerX: centerX, centerY: centerY);
        self.matrix.rotate(_angle: r, centerX: centerX, centerY: centerY)
       
        let xDelt = ds.dX
        let yDelt = ds.dY
        
        let _dx = self.bPosition.x.get(id:nil) + xDelt;
        let _dy = self.bPosition.y.get(id:nil) + yDelt;
        print("_dx, _dy",_dx,_dy)
        let transformedCoords = self.matrix.transformPoint(x: _dx, y: _dy)

        self.distance.set(newValue: ds.dist + sqrt(pow(xDelt,2)+pow(yDelt,2)));
        self.xDistance.set(newValue: ds.xDist + abs(xDelt));
        self.yDistance.set(newValue: ds.yDist + abs(yDelt));
        
        xBuffer.push(v: xDelt);
        yBuffer.push(v: yDelt);
        
        bufferLimitX.set(newValue: 0)
        bufferLimitY.set(newValue: 0)
        
        let cweight = ds.d;
        weightBuffer.push(v: cweight);
       
        let color = Color(h: ds.h, s: ds.s, l: ds.l, a: 1)
       
        self.currentCanvas!.addSegmentToStroke(parentID: self.id, point:Point(x:transformedCoords.0,y:transformedCoords.1),weight:cweight , color: color,alpha:ds.a)
        
        self.bPosition.x.setSilent(newValue: _dx)
        self.bPosition.y.setSilent(newValue:_dy)
        
        
        self.distanceIntervalCheck();
        self.intersectionCheck();
    }
    
    func intersectionCheck(){
        let bpx = bPosition.x.get(id: nil);
        let bpy = bPosition.y.get(id: nil);
        
        print("current position",bpx,bpy);

        if((keyStorage["INTERSECTION"]!.count)>0){
            let hit = self.currentCanvas!.hitTest(point: self.bPosition, threshold: 5, id:self.id);
            //print("hit=",hit,keyStorage["INTERSECTION"]);
            if(hit != nil){
                self.intersections.set(newValue: self.intersections.getSilent()+1);
                for key in keyStorage["INTERSECTION"]!
                {
                    if(key.1 != nil){
                        let condition = key.1;
                        let evaluation = condition?.evaluate();
                        if(evaluation == true){
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: key.0), object: self, userInfo: ["emitter":self,"key":key.0,"event":"INTERSECTION"])
                        }
                    }
                    else{
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: key.0), object: self, userInfo: ["emitter":self,"key":key.0,"event":"INTERSECTION"])
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
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: key.0), object: self, userInfo: ["emitter":self,"key":key.0,"event":"DISTANCE_INTERVAL"])
                }
            }
            else{
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: key.0), object: self, userInfo: ["emitter":self,"key":key.0,"event":"DISTANCE_INTERVAL"])
            }
            
        }
        
    }
    
    
    func setOrigin(p:Point){
            self.origin.set(val:p);
            self.position.x.setSilent(newValue: self.origin.x.get(id: nil))
            self.position.y.setSilent(newValue: self.origin.y.get(id: nil))
            self.bPosition.x.setSilent(newValue: self.origin.x.get(id: nil))
            self.bPosition.y.setSilent(newValue: self.origin.y.get(id: nil))
            print("origin set =",stylus.x.get(id:nil),p.x.get(id: nil),p.y.get(id:nil));

    }
    
    dynamic func stateTransitionHandler(notification: NSNotification){
        
       
            let key = notification.userInfo?["key"] as! String
            let mapping = states[currentState]?.getTransitionMapping(key: key)
            
            
            if(mapping != nil){
                let stateTransition = mapping
                
                self.raiseBehaviorEvent(d: stateTransition!.toJSON(), event: "transition")
                self.transitionToState(transition: stateTransition!)
                
            }
        
    }
    
    func transitionToState(transition:StateTransition){
        var constraint_mappings:[String:Constraint];
        
        if(states[currentState] != nil){
            constraint_mappings =  states[currentState]!.constraint_mappings
            for (_, value) in constraint_mappings{
                
                self.setConstraint(constraint: value)
                value.relativeProperty.constrained = false;
                
            }
        }
        self.currentState = transition.toStateId;
        self.raiseBehaviorEvent(d: states[currentState]!.toJSON(), event: "state")
        //print("transitioning to state \(states[currentState]?.name, self.name)")
        self.executeTransitionMethods(methods: transition.methods)
        
        constraint_mappings =  states[currentState]!.constraint_mappings
        for (_, value) in constraint_mappings{
            value.relativeProperty.constrained = true;
        }
        //execute methods
        //check constraints
        
        //trigger state complete after functions are executed
        
        _  = Timer.scheduledTimer(timeInterval: 0.00001, target: self, selector: #selector(Brush.completeCallback), userInfo: nil, repeats: false)
        
        if(states[currentState]?.name == "die"){
           // print("transitioning to die state!!!");
            self.die();
        }
    }
    
    func raiseBehaviorEvent(d:String, event:String){
        var data = "{\"brush_id\":\""+self.id+"\","
        data+="\"brush_name\":\""+self.name+"\","
        data+="\"behavior_id\":\""+self.behavior_id!+"\","
        data += "\"event\":\""+event+"\",";
        data += "\"type\":\"behavior_change\","
        data += "\"data\":"+d;
        data += "}"
        // if(self.name != "rootBehaviorBrush"){
        self.transmitEvent.raise(data: data);
        //}
    }
    
    @objc func completeCallback(){
        for key in self.keyStorage["STATE_COMPLETE"]!  {
            if(key.1 != nil){
                let condition = key.1;
                if(condition?.evaluate())!{
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: key.0), object: self, userInfo: ["emitter":self,"key":key.0,"event":"STATE_COMPLETE"])
                }
            }
            else{
                //print("key 0",key.0);
                 NotificationCenter.default.post(name: NSNotification.Name(rawValue: key.0), object: self, userInfo: ["emitter":self,"key":key.0,"event":"STATE_COMPLETE"])
            }
            
        }
    }
    
    
    
    func executeTransitionMethods(methods:[Method]){
        
        for i in 0..<methods.count{
            let method = methods[i];
            let methodName = method.name;
            print("executing method:\(method.name,self.id,self.name)");
            switch (methodName){
            case "newStroke":
                
                let arg = method.arguments![0];
                //print("set origin argument \(method.arguments![0])");
                if  let arg_string = arg as? String {
                    if(arg_string  == "parent_position"){
                        if(self.parent != nil){
                            self.setOrigin(p: self.parent!.bPosition)
                        }
                        else{
                            
                            print("cannot set origin, no parent position")
                        }
                    }
                    else if(arg_string  == "parent_origin"){
                        if(self.parent != nil){

                        self.setOrigin(p: self.parent!.origin)
                        }
                        else{
                            print("cannot set origin, no parent position")
  
                        }
                    }
                }else {
                    self.setOrigin(p: method.arguments![0] as! Point)
                }

                self.newStroke();
                break;
            case "startTimer":
                self.startInterval();
                break;
            case "stopTimer":
                self.stopInterval();
                break;
            case "setOrigin":
                let arg = method.arguments![0];
                //print("set origin argument \(method.arguments![0])");
                if  let arg_string = arg as? String {
                    if(arg_string  == "parent_position"){
                        self.setOrigin(p: self.parent!.bPosition)
                    }
                    else if(arg_string  == "parent_origin"){
                        self.setOrigin(p: self.parent!.origin)
                    }
                }else {
                    self.setOrigin(p: method.arguments![0] as! Point)
                }
            case "destroy":
                self.destroy();
                break;
            case "spawn":
                //print("spawning brush")
                let arg = method.arguments![0];
                var behaviorDef:BehaviorDefinition! = nil;
               let arg_string = arg as? String
                    if(arg_string == "parent"){
                        behaviorDef = self.parent!.behaviorDef!;
                    }
                    else if(arg_string == "self"){
                        behaviorDef = self.behaviorDef!;
                    }
                    else{
                        behaviorDef = BehaviorManager.getBehaviorById(id:arg_string!);
                    }
                if(behaviorDef != nil){
                    self.spawn(behavior:behaviorDef,num:(method.arguments![1] as! Int));
                }
                break;
            default:
                break;
            }
        }
        
    }
    
    //sets canvas target to output geometry into
    func setCanvasTarget(canvas:Canvas){
        self.currentCanvas = canvas;
    }
    
    
    /* addConstraint
     //adds a property mapping constraint.
     //property mappings can take two forms, active and passive
     //active: when reference changes, relative is updated to reflect change. This is for properties which are updated manually by the artist
     //like the stylus properties, or properties with an internal interval, like a timed buffer
     //passive: this for constraints which are not actively modifed by an interval or an external change. This can include constants
     //or generators and buffers which will return a new value each time they are accessed
     */
    func addConstraint(id:String,reference:Observable<Float>, relative:Observable<Float>, stateId:String, type:String){
        print("adding constraint \(type,reference,relative,stateId)")
        if(type == "active"){
            reference.subscribe(id: self.id);
           _ = reference.didChange.addHandler(target: self, handler:  Brush.setHandler, key:id)
        }
            
        else if(type == "passive"){
            relative.passiveConstrain(target: reference);
        }
        //print("target state = \(stateId)");
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
               _ = self.removeChildAt(index: Int(c.index.get(id: nil)))
            }
        }
        for i in 0..<children.count{
            self.children[i].index.set(newValue: Float(i));
        }
    }

    
    func setConstraint(constraint:Constraint){
        print("calling set constraint on",  constraint.relativeProperty.name,constraint.relativeProperty,constraint.reference.get(id: self.id))
        constraint.relativeProperty.set(newValue: constraint.reference.get(id: self.id));
        
        
        
    }
    
    func addStateTransition(id:String, name:String, reference:Emitter, fromStateId: String, toStateId:String){
        
        let transition:StateTransition
        
        let state = self.states[fromStateId]
        transition = state!.addStateTransitionMapping(id: id,name:name,reference: reference, toStateId:toStateId)
        self.transitions[id] = transition;
    }
    
    func removeStateTransition(data:(Brush, String, Emitter),key:String){
        //print("removing state transition \(key)");
        NotificationCenter.default.removeObserver(data.0, name: NSNotification.Name(rawValue: data.1), object: data.2)
        data.2.removeKey(key: data.1)
    }
    
    func addMethod(transitionId:String, methodId:String, methodName:String, arguments:[Any]?){
        //print("adding method \(methodId) for transition \(transitionId,transitions)");
        
        (transitions[transitionId]!).addMethod(id: methodId, name:methodName,arguments:arguments)
        
        
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
                let removal =  val.removeTransitionMapping(key: key)!
                let data = (self, key, removal.reference)
                removeTransitionEvent.raise(data: data)
                break
            }
        }
    }
    
    func resetDistance(){
        self.distance.set(newValue: 0);
        self.xDistance.set(newValue: 0);
        self.yDistance.set(newValue: 0)
        
        for key in keyStorage["DISTANCE_INTERVAL"]!{
            if(key.1 != nil){
                let eventCondition = key.1;
                eventCondition!.reset();
            }
        }
    }
    

    
    //===============METHODS AVAILABLE TO USER===============//
    
    
    
    func newStroke(){
        self.currentCanvas!.currentDrawing!.retireCurrentStrokes(parentID: self.id)
        self.currentStroke = self.currentCanvas!.currentDrawing!.newStroke(parentID: self.id);
        self.resetDistance();
    }
    
    //creates number of clones specified by num and adds them as children
    func spawn(behavior:BehaviorDefinition,num:Int) {
        print("spawn called")
        if(num > 0){
        for _ in 0...num-1{
            let child = Brush(name:name, behaviorDef: behavior, parent:self, canvas:self.currentCanvas!)
            self.children.append(child);
            child.index.set(newValue: Float(self.children.count-1));
            self.initEvent.raise(data: (child,"brush_init"));
            behavior.initBrushBehavior(targetBrush: child);
            _ = child.dieEvent.addHandler(target: self, handler: Brush.childDieHandler, key: childDieHandlerKey)
        }
        
        for c in children{
            c.siblingcount.set(newValue: Float(self.children.count))
        }
        
        //notify listeners of spawn event
        for key in keyStorage["SPAWN"]!  {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: key.0), object: self, userInfo: ["emitter":self,"key":key.0,"event":"SPAWN"])
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
                self.removeTransitionEvent.raise(data: (self,transition.id,transition.reference));
            }
            
            state.removeAllConstraintMappings(brush:self);
        }
        self.transitions.removeAll();
        self.states.removeAll();
    }
    
    
    func clearAllEventHandlers(){
    self.initEvent.removeAllHandlers()
    self.geometryModified.removeAllHandlers()
    self.transmitEvent.removeAllHandlers()
    self.removeMappingEvent.removeAllHandlers()
    self.removeTransitionEvent.removeAllHandlers()
    self.dieEvent.removeAllHandlers()
    }
    
    override func destroy() {
        currentCanvas!.currentDrawing!.retireCurrentStrokes(parentID: self.id)
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



