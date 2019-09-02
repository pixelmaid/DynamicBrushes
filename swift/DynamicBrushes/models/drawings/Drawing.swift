//
//  Drawing.swift
//  DynamicBrushes
//
//  Created by JENNIFER MARY JACOBS on 6/24/16.
//  Copyright © 2016 pixelmaid. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON
//Drawing
//stores geometry

class Drawing: TimeSeries, Hashable, Renderable{
    //check for if segments need drawing;
    var unrendered = false
    
    private var activeStrokes = [String:[String:[Stroke]]]();
    var allStrokes = [Stroke]();
    var initEvent = Event<(WebTransmitter,String)>()
    let strokeGeneratedEvent = Event<(String)>();
    let strokeRemovedEvent = Event<([String])>();
    let svgGenerator = SVGGenerator();
    
    var geometryModified = Event<(Geometry,String,String)>()
    override init(){
        super.init();
        self.name = "drawing"
    }
    
    func registerNewBrush(behaviorId:String,brushId:String){
       guard var brushList = self.activeStrokes[behaviorId] else {
            var brushList = [String:[Stroke]]();
            brushList[brushId] = [Stroke]();
            self.activeStrokes[behaviorId] = brushList;
            return;

        }
        
        brushList[brushId] = [Stroke]();
        
    }
    
    func destroyBrushRegistry(behaviorId:String,brushId:String){
        guard var brushList = self.activeStrokes[behaviorId] else {
            return;
        }
        guard let _ = brushList[brushId] else {
            return;
        }
        self.retireCurrentStrokes(behaviorId: behaviorId,brushId: brushId);
        brushList.removeValue(forKey: brushId);
    }
    
    func destroyBehaviorRegistry(behaviorId:String){
        guard let brushList = self.activeStrokes[behaviorId] else {
            return;
        }
        for (brushId,_) in  brushList{
            self.destroyBrushRegistry(behaviorId: behaviorId, brushId:  brushId);
        }
        self.activeStrokes.removeValue(forKey: behaviorId);

    }
    
    func activeStrokesToJSON()->JSON{
        var strokeJSON:JSON = [:];
        for (behaviorId,brushStrokeList) in activeStrokes{
            var brushStrokeJSON:JSON = [:]
            let behavior = BehaviorManager.behaviors[behaviorId];
            for(brushId,strokes) in brushStrokeList{
                let brush = behavior!.brushInstances.first{$0.id == brushId};
                var strokeJSON:JSON = [:];
                
                strokeJSON["i"] = JSON(brush!.params.i);
                //print(strokeJSON["i"].floatValue);
                strokeJSON["name"] = JSON(brush!.name);
                
                if(strokes.count < 1){
                    var emptyParams:JSON = [:]
                        emptyParams["pen"] = JSON("up")
                    emptyParams["x"] = 0;
                    emptyParams["y"] = 0;
                    emptyParams["h"] = 0;
                    emptyParams["s"] = 0;
                    emptyParams["l"] = 0;
                    emptyParams["a"] = 0;
                    strokeJSON["params"] = emptyParams;
                }
                
                else{
                    for stroke in strokes{
                        var singleStrokeJSON = stroke.toJSON();
                        singleStrokeJSON["pen"] = JSON("down");
                        strokeJSON["params"] = singleStrokeJSON;

                    }
                }
                brushStrokeJSON[brushId] = strokeJSON;
            }
            var behaviorJSON:JSON = [:]
            behaviorJSON["brushes"] = brushStrokeJSON;
            behaviorJSON["id"] = JSON(behaviorId)
            behaviorJSON["name"] = JSON(behavior!.name);
            strokeJSON[behaviorId] = behaviorJSON;
        }
        return strokeJSON;
    }
    
    func drawSegment(context:ModifiedCanvasView){
        
        for i in 0..<allStrokes.count{
            if(allStrokes[i].unrendered){
                allStrokes[i].drawSegment(context:context);
                
            }
        }
        self.unrendered = false
    }
    
    func getSVG()->String{
        var orderedStrokes = [Stroke]()
        for i in 0..<allStrokes.count{
            orderedStrokes.append(allStrokes[i])
        }
        
        return svgGenerator.generate(strokes: orderedStrokes)
        
    }
    
    func parentHitTest(point:Point,threshold:Float,id:String, parentId:String)->Stroke?{
       
        var parentStroke:Stroke? = nil
        var stroke:Stroke? = nil
        for i in 0..<allStrokes.count{
            if(allStrokes[i].brushId == parentId){
                parentStroke = allStrokes[i];
            }
            if(allStrokes[i].brushId == id){
                stroke = allStrokes[i];
            }        }
        if(stroke != nil && stroke!.segments.count>15 ){
            
        }
        else{
            return nil;
        }
        if(parentStroke != nil){
            let seg = parentStroke?.hitTest(testPoint: point,threshold:threshold,sameStroke: false);
            if(seg != nil){
                return parentStroke;
            }
        }
        
        return nil;
    }
    
    
    func hitTestByPoint(point:Point,threshold:Float)->Segment?{
        for i in 0..<allStrokes.count{
            let stroke = allStrokes[i];
            
                let seg = stroke.hitTest(testPoint: point,threshold:threshold,sameStroke: false);
                if(seg != nil){
                    return seg;
                }
        }
        return nil
    }
    
    func hitTestByBrush(point:Point,threshold:Float, behaviorId:String, brushId:String)->Stroke?{
        var targetStroke:Stroke! = nil
        let targetActiveStrokes = self.activeStrokes[behaviorId]![brushId];
        if(targetActiveStrokes != nil){
            if(targetActiveStrokes!.count>0){
                targetStroke = targetActiveStrokes!.last
            }
        }
        #if DEBUG
           // print("drawing hit test: \(allStrokes.count,self.activeStrokes.count,id)");
        #endif
        

        for i in 0..<allStrokes.count{
            let stroke = allStrokes[i];
            if(targetStroke != nil && targetStroke! == stroke){
                let seg = stroke.hitTest(testPoint: point,threshold:threshold,sameStroke: true);
                if(seg != nil){
                    
                    return stroke;
                }
            }
            else{

                let seg = stroke.hitTest(testPoint: point,threshold:threshold,sameStroke: false);
                if(seg != nil){
                    return stroke;
                }
            }
        }
        return nil
    }
    
    //MARK: - Hashable
    var hashValue : Int {
        get {
            return "\(self.id)".hashValue
        }
    }
    
    func retireCurrentStrokes(behaviorId:String,brushId:String){
        #if DEBUG
       // print("retire strokes for \(parentID, activeStrokes[behaviorId]![brushId)");
        #endif 
        if (self.activeStrokes[behaviorId]![brushId] != nil ){
            var toRemove = [String]();
            for s in self.activeStrokes[behaviorId]![brushId]!{
                toRemove.append(s.id);
                //s.segments.removeAll();
                
                s.unrenderedSegments.removeAll()
                //s.destroy();
            }
            self.activeStrokes[behaviorId]![brushId]!.removeAll();

            //self.allStrokes = allStrokes.filter({ $0.parentID != parentID })
            #if DEBUG
            //print("strokes to remove",toRemove)
            #endif
           self.strokeRemovedEvent.raise(data: toRemove);
        }
        #if DEBUG
            //print("current number of strokes",self.allStrokes.count)
        #endif
    }
    
    func newStroke(behaviorId:String, brushId:String)->Stroke{
       
        let stroke = Stroke(brushId:brushId,behaviorId:behaviorId);
        if (self.activeStrokes[behaviorId] == nil){
            self.activeStrokes[behaviorId] = [String:[Stroke]]();
            
            
        }
        if (self.activeStrokes[behaviorId]![brushId]==nil){
            self.activeStrokes[behaviorId]![brushId] = [Stroke]();
        }
         self.activeStrokes[behaviorId]![brushId]!.append(stroke);
        
        self.allStrokes.append(stroke);
        self.strokeGeneratedEvent.raise(data: stroke.id)

        return stroke;
    }
    
    func addSegmentToStroke(behaviorId:String,brushId:String, point:Point, weight:Float, color:Color, alpha:Float, time:Int){
        if (self.activeStrokes[behaviorId] == nil){
            return
        }
        if (self.activeStrokes[behaviorId]![brushId] == nil){
            return
        }
        self.unrendered = true;

        for i in 0..<self.activeStrokes[behaviorId]![brushId]!.count{
            let currentStroke = self.activeStrokes[behaviorId]![brushId]![i]

            _ = currentStroke.addSegment(brushId: brushId, point: point,d:weight,color:color,alpha:alpha,time:time)

        }
    }
    
    
    
}


// MARK: Equatable
func ==(lhs:Drawing, rhs:Drawing) -> Bool {
    return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
}


