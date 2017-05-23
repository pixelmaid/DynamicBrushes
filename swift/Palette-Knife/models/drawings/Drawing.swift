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
    
    var id = NSUUID().uuidString;
    var activeStrokes = [String:[Stroke]]();
    var allStrokes = [Stroke]();
    var transmitEvent = Event<(String)>()
    var initEvent = Event<(WebTransmitter,String)>()

    let svgGenerator = SVGGenerator();
    
    var geometryModified = Event<(Geometry,String,String)>()
    
    override init(){
        super.init();
        self.name = "drawing"
    }
    
    func drawSegment(context:CGContext){
       
            for i in 0..<allStrokes.count{
                // print("strokes \(i,strokes[i].dirty)");
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
    
    func hitTest(point:Point,threshold:Float,parentID:String)->Stroke?{
        for i in 0..<allStrokes.count{
            let stroke = allStrokes[i];
                let seg = stroke.hitTest(testPoint: point,threshold:threshold);
            
            
                if(seg != nil){
                    if(self.activeStrokes[parentID] != nil){
                        let activeStrokes = self.activeStrokes[parentID]
                        for s in activeStrokes!{
                            if s.containsSegment(segment:seg!) == true {
                                print("stroke contains segment");
                                return nil
                            }
                        }
                        return stroke;
                    }
                    else{
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
        if (self.activeStrokes[parentID] != nil){
            self.activeStrokes[parentID]!.removeAll();
        }
    }
    
    func newStroke(parentID:String)->Stroke{
        let stroke = Stroke(parentID:parentID);
        stroke.parentID = parentID;
        if (self.activeStrokes[parentID] == nil){
            self.activeStrokes[parentID] = [Stroke]()
        }
        self.activeStrokes[parentID]!.append(stroke);
        
       
       
        
        self.allStrokes.append(stroke);
       
        return stroke;
    }
    
    func addSegmentToStroke(parentID:String, point:Point, weight:Float, color:Color, alpha:Float){
        if (self.activeStrokes[parentID] == nil){
            return
        }
        self.dirty = true;
        for i in 0..<self.activeStrokes[parentID]!.count{
            let currentStroke = self.activeStrokes[parentID]![i]
            var seg = currentStroke.addSegment(point: point,d:weight,color:color,alpha:alpha)
            }
    }
    
    
    
}


// MARK: Equatable
func ==(lhs:Drawing, rhs:Drawing) -> Bool {
    return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
}


