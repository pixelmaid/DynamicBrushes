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
    
    func activeStrokesToJSON()->JSON{
        var strokeJSON:JSON = [:];
        for (behaviorId,brushStrokeList) in activeStrokes{
            var brushStrokeJSON:JSON = [:]
            for(brushId,strokes) in brushStrokeList{
                var strokeJSON = [JSON]();
                for stroke in strokes{
                    strokeJSON.append(stroke.toJSON());
                }
                brushStrokeJSON[brushId] = JSON(strokeJSON);
                
            }
            strokeJSON[behaviorId] = brushStrokeJSON;
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
            if(allStrokes[i].parentID == parentId){
                parentStroke = allStrokes[i];
            }
            if(allStrokes[i].parentID == id){
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
    
    func hitTest(point:Point,threshold:Float,behaviorId:String,brushId:String)->Stroke?{
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
       
        let stroke = Stroke(parentID:brushId);
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
    
    func addSegmentToStroke(behaviorId:String,brushId:String, point:Point, weight:Float, color:Color, alpha:Float){
        if (self.activeStrokes[behaviorId] == nil){
            return
        }
        if (self.activeStrokes[behaviorId]![brushId] == nil){
            return
        }
        self.unrendered = true;

        for i in 0..<self.activeStrokes[behaviorId]![brushId]!.count{
            let currentStroke = self.activeStrokes[behaviorId]![brushId]![i]

            _ = currentStroke.addSegment(brushId: brushId, point: point,d:weight,color:color,alpha:alpha)

        }
    }
    
    
    
}


// MARK: Equatable
func ==(lhs:Drawing, rhs:Drawing) -> Bool {
    return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
}


