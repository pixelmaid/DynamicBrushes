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
    var allStrokes = [String:[Stroke]]();
    var drawnStrokes  = [String:[Stroke]]();
    var transmitEvent = Event<(String)>()
    var initEvent = Event<(WebTransmitter,String)>()
    
    let svgGenerator = SVGGenerator();
    
    var geometryModified = Event<(Geometry,String,String)>()
    
    override init(){
        super.init();
        self.name = "drawing"
    }
    
    func drawSegment(context:CGContext){
        for (_,strokes) in allStrokes{
            for i in 0..<strokes.count{
                // print("strokes \(i,strokes[i].dirty)");
                
                if(strokes[i].dirty){
                    strokes[i].drawSegment(context:context);
                }
            }
        }
        self.dirty = false
    }
    
    func getSVG()->String{
        var orderedStrokes = [Stroke]()
        for list in self.allStrokes{
            for i in 0..<list.1.count{
                orderedStrokes.append(list.1[i])
            }
        }
        return svgGenerator.generate(strokes: orderedStrokes)
        
    }
    
    func hitTest(point:Point,threshold:Float)->Stroke?{
        for list in allStrokes {
            for stroke in list.1{
                let seg = stroke.hitTest(testPoint: point,threshold:threshold);
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
        
        if (self.allStrokes[parentID] == nil){
            self.allStrokes[parentID] = [Stroke]()
            
        }
       
        
        self.allStrokes[parentID]!.append(stroke);
       
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


