//
//  Stroke.swift
//  Palette-Knife
//
//  Created by JENNIFER MARY JACOBS on 5/5/16.
//  Copyright © 2016 pixelmaid. All rights reserved.
//
import Foundation
import UIKit

enum DrawError: Error {
    case InvalidArc
    
}
protocol Geometry {
    func toJSON()->String
}

struct StoredDrawing:Geometry{
    var angle:Float
    var scaling:Point
    var position:Point
    
    init(position:Point,scaling:Point,angle:Float){
        self.angle = angle
        self.scaling = scaling
        self.position = position
    }
    
    //todo: create toJSON method
    func toJSON()->String{
        return "placeholder_string"
    }
}

class DeallocPrinter {
    deinit {
        #if DEBUG
        //print("dealocated")
        #endif
    }
}


// Segment: line segement described as two points
struct Segment:Geometry, Equatable {
    
    var point:Point;
    var handleIn: Point;
    var handleOut: Point;
    var parent:Stroke?;
    var index:Int?
    var weight = Float(1);
    var color = Color(h: 0, s: 0, l: 0, a: 1);
    var alpha = Float(0.5);
    let id = NSUUID().uuidString;
    //let printer = DeallocPrinter()
    init(x:Float,y:Float) {
        self.init(x:x,y:y,hi_x:0,hi_y:0,ho_x:0,ho_y:0)
    }
    
    init(point:Point){
        self.init(point:point,handleIn:Point(x: 0, y: 0),handleOut:Point(x: 0, y: 0))
    }
    
    init(x:Float,y:Float,hi_x:Float,hi_y:Float,ho_x:Float,ho_y:Float){
        let point = Point(x:x,y:y)
        let hI = Point(x: hi_x,y: hi_y)
        let hO = Point(x: ho_x,y: ho_y)
        self.init(point:point,handleIn:hI,handleOut:hO)
        
    }
    
    init(point:Point,handleIn:Point,handleOut:Point) {
        self.point = point
        self.handleIn = handleIn
        self.handleOut = handleOut
    }
    
    mutating func setHandleOut(point:Point){
    self.handleOut = point;
    }
    
    mutating func setHandleIn(point:Point){
        self.handleIn = point;
    }
    
    
    /* func getTimeDelta()->Float{
     let prevSeg = self.getPreviousSegment();
     if(prevSeg == nil){
     return 0;
     }
     
     let currentTime = self.time;
     let prevTime = prevSeg!.time;
     return currentTime-prevTime;
     }
     */
    
    func hitTest(testPoint:Point,threshold:Float)->Bool{
        let dist = self.point.dist(point: testPoint);
        
        if testPoint == self.point{
            return false
        }
        if dist <= threshold {
            #if DEBUG
            print("hit achieved")
            #endif
            return true
        }
        return false;
    }
    
    func drawIntoContext(id:String, context:ModifiedCanvasView) {

        if(self.getPreviousSegment() != nil){
            var a_color = self.color;
           a_color.alpha = self.alpha;
            if(a_color.alpha <= 0){
                a_color.alpha = 0.0001
            }
            if(a_color.alpha > 1){
                a_color.alpha = 1
            }
            if(a_color.hue>360){
                a_color.hue = 360;
            }
            
            let w = self.weight
            var mapped_weight = pow(1.03,w)*0.54

            if(mapped_weight < 1){
                mapped_weight = 1
            }
            if(mapped_weight >= 360){
                mapped_weight = 359
            }
        
            context.renderStrokeById(currentStrokeId: id, toPoint: self.point.toCGPoint(), toWidth: CGFloat(mapped_weight), toColor: a_color.toUIColor())
        }
    }
    
    
    func getPreviousSegment()->Segment?{
        if(self.parent != nil){
            if(self.index!>0){
                return parent!.segments[self.index!-1]
            }
        }
        return nil
    }
    
    func toJSON()->String{
        var string = "{\"point\":{"+self.point.toJSON()+"},"
        string += "\"time\":"+String(parent!.getTimeElapsed())+"}"
        return string
    }
    
}

func ==(lhs: Segment, rhs: Segment) -> Bool {
    return lhs.point == rhs.point
}



// Stroke: Model for storing a stroke object in multiple representations
// as a series of segments
// as a series of vectors over time
class Stroke:TimeSeries, Geometry, Renderable {
    //check for if segments need drawing;
    internal var unrendered = false
    var unrenderedSegments = [Segment]()
    var toDrawSegments = [Segment]()
    var segments = [Segment]();
   /* var xBuffer = CircularBuffer();
    var yBuffer = CircularBuffer();
    var weightBuffer = CircularBuffer();*/
    var parentID: String;
    var selected = false;
    
    init(parentID:String){
        self.parentID = parentID;
        super.init();
    }
    
    deinit{
        #if DEBUG
        //print ("stroke \(self.id) dealocated")
        #endif
    }
    
    func hitTest(testPoint:Point,threshold:Float,sameStroke:Bool)->Segment?{
        if(self.segments.count>4){
        if(sameStroke){
            #if DEBUG
                //print ("stroke hit test same stroke\(self.segments.count)")
                #endif
            if self.segments.count>15{
                for i in 0..<self.segments.count-15{
                    let seg = self.segments[i]
                    let hit = seg.hitTest(testPoint: testPoint, threshold: threshold);
                    if hit{
                        return seg
                    }
                }
            }
        }
        else{
            #if DEBUG

            //print ("stroke hit test different stroke\(self.segments.count)")
                #endif
            for seg in self.segments{
                let hit = seg.hitTest(testPoint: testPoint, threshold: threshold);
                if hit{
                    return seg
                }
            }
        }
        }
        return nil;
        
    }
    
    
    func containsSegment(segment:Segment)->Bool{
        for seg in self.segments{
            if seg.id == segment.id{
                return true
            }
        }
        return false
    }
    
    func drawSegment(context:ModifiedCanvasView){
        
        self.toDrawSegments.append(contentsOf: self.unrenderedSegments)
        self.unrenderedSegments.removeAll();
        for i in 0..<toDrawSegments.count{
           toDrawSegments[i].drawIntoContext(id:self.id, context: context);
        }
        
        self.toDrawSegments.removeAll();
        //self.segments.removeAll();
        self.unrendered = false;
    }
    
    
    func addSegment(brushId:String, point:Point, d:Float, color:Color, alpha:Float)->Segment?{
        self.unrendered = true;

        var segment = Segment(point:point)
        segment.weight = d
        segment.color = color;
        segment.alpha = alpha;
        segment.parent = self
        segment.index = self.segments.count;
        segments.append(segment)
        unrenderedSegments.append(segment);

        return segment
    }
    
    
    
    func getLength()->Float{
        var l = Float(0.0);
        if(segments.count>1){
            for i in 1...segments.count-1{
                l += segments[i-1].point.dist(point: segments[i].point)
            }
        }
        return l;
    }
    
    
    
    func toJSON()->String{
        var string = "segments:["
        for i in 0...segments.count-1{
            
            string += "{"+segments[i].toJSON()+"}"
            if(i<segments.count-1){
                string+=","
            }
        }
        string += "],"
        return string
        
    }
    
    
    
}




