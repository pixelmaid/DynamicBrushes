//
//  Drawing.swift
//  PaletteKnife
//
//  Created by JENNIFER MARY JACOBS on 6/24/16.
//  Copyright © 2016 pixelmaid. All rights reserved.
//

import Foundation
import UIKit
//Drawing
//stores geometry

class Drawing: TimeSeries, WebTransmitter, Hashable{
    //check for if segments need drawing;
    var dirty = false
    
    private var activeStrokes = [String:[Stroke]]();
    var allStrokes = [Stroke]();
    var transmitEvent = Event<(String)>()
    var initEvent = Event<(WebTransmitter,String)>()
    let strokeGeneratedEvent = Event<(String)>();
    let strokeRemovedEvent = Event<([String])>();
    let svgGenerator = SVGGenerator();
    
    var geometryModified = Event<(Geometry,String,String)>()
    override init(){
        super.init();
        self.name = "drawing"
    }
    
    func drawSegment(context:ModifiedCanvasView){
        
        for i in 0..<allStrokes.count{
            if(allStrokes[i].dirty){
                allStrokes[i].drawSegment(context:context);
                
            }
        }
        self.dirty = false
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
        print("parent stroke=\(parentStroke,id)");
        if(stroke != nil && stroke!.segments.count>15       ){
            
        }
        else{
            return nil;
        }
        if(parentStroke != nil){
            let seg = parentStroke?.hitTest(testPoint: point,threshold:threshold,sameStroke: false);
            if(seg != nil){
                print("parent stroke hit");

                return parentStroke;
            }
        }
        
        return nil;
    }
    
    func hitTest(point:Point,threshold:Float,id:String)->Stroke?{
        var targetStroke:Stroke! = nil
        let targetActiveStrokes = self.activeStrokes[id];
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
    
    func retireCurrentStrokes(parentID:String){
        print("retire strokes for \(parentID, activeStrokes[parentID])");
        if (self.activeStrokes[parentID] != nil){
            var toRemove = [String]();
            for s in self.activeStrokes[parentID]!{
                toRemove.append(s.id);
                //s.segments.removeAll();
                
                s.dirtySegments.removeAll()
                //s.destroy();
            }
            self.activeStrokes[parentID]!.removeAll();

            //self.allStrokes = allStrokes.filter({ $0.parentID != parentID })
            #if DEBUG
            print("strokes to remove",toRemove)
            #endif
           self.strokeRemovedEvent.raise(data: toRemove);
        }
        #if DEBUG
            //print("current number of strokes",self.allStrokes.count)
        #endif
    }
    
    func newStroke(parentID:String)->Stroke{
       
        let stroke = Stroke(parentID:parentID);
        if (self.activeStrokes[parentID] == nil){
            self.activeStrokes[parentID] = [Stroke]()
        }
        self.activeStrokes[parentID]!.append(stroke);
        
        self.allStrokes.append(stroke);
        self.strokeGeneratedEvent.raise(data: stroke.id)

        return stroke;
    }
    
    func addSegmentToStroke(parentID:String, point:Point, weight:Float, color:Color, alpha:Float){
        if (self.activeStrokes[parentID] == nil){
            return
        }
        self.dirty = true;

        for i in 0..<self.activeStrokes[parentID]!.count{
            let currentStroke = self.activeStrokes[parentID]![i]

            _ = currentStroke.addSegment(brushId: parentID, point: point,d:weight,color:color,alpha:alpha)

        }
    }
    
    
    
}


// MARK: Equatable
func ==(lhs:Drawing, rhs:Drawing) -> Bool {
    return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
}


