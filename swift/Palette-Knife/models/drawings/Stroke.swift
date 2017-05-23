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

// Segment: line segement described as two points
struct Segment:Geometry, Equatable {
    
    var point:Point;
    var handleIn: Point;
    var handleOut: Point;
    var parent:Stroke?;
    var index:Int?
    var diameter = Float(1);
    var color = Color(r:0,g:0,b:0,a:1);
    var alpha = Float(0.5);
    let id = NSUUID().uuidString;
    
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
        if dist <= threshold {
            print("hit achieved",threshold,dist)
            return true
        }
        return false;
    }
    
    func drawIntoContext(context:CGContext?) {
         if(self.getPreviousSegment() != nil){
        
        self.color.toUIColor().setStroke();
        context?.setLineWidth(CGFloat(self.diameter))
        context?.setLineCap(.round)
        context?.setAlpha(CGFloat(self.alpha));
        
        context?.move(to: self.point.toCGPoint())
       
        context?.addLine(to:(self.getPreviousSegment()?.point.toCGPoint())!)
        context?.strokePath()
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
class Stroke:TimeSeries, Geometry {
    //check for if segments need drawing;
    var dirty = false
    var dirtySegments = [Segment]()
    var toDrawSegments = [Segment]()
    var segments = [Segment]();
    var xBuffer = CircularBuffer();
    var yBuffer = CircularBuffer();
    var weightBuffer = CircularBuffer();
    let id = NSUUID().uuidString;
    var parentID: String;
    var selected = false;
    
    init(parentID:String){
        self.parentID = parentID;
        super.init();
    }
    
    func hitTest(testPoint:Point,threshold:Float)->Segment?{
        for seg in self.segments{
            let hit = seg.hitTest(testPoint: testPoint, threshold: threshold);
            if hit{
                return seg
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
    
    func drawSegment(context:CGContext){
        self.toDrawSegments.append(contentsOf: self.dirtySegments)
        self.dirtySegments.removeAll();
        for i in 0..<toDrawSegments.count{
           toDrawSegments[i].drawIntoContext(context: context);
        }
        self.toDrawSegments.removeAll();
        self.dirty = false;
    }
    
    
    func addSegment(_segment:Segment)->Segment?{
        self.dirty = true;
        
        var segment = _segment;
        segment.parent = self
        segment.index = self.segments.count;
        //segment.time = Float(0-timer.timeIntervalSinceNow);
        
        if(segments.count>0){
            let prevSeg = segments[segments.count-1];
           // let dist = segment.point.dist(point: prevSeg.point)
            
            //if(dist < 10){
              //  return nil;
            //}
            xBuffer.push(v: segment.point.x.get(id: nil)-prevSeg.point.x.get(id: nil))
            yBuffer.push(v: segment.point.y.get(id: nil)-prevSeg.point.y.get(id: nil))

        }
        else{
            xBuffer.push(v: 0);
            yBuffer.push(v: 0)
        }
        segments.append(segment)
        dirtySegments.append(segment);
        return segment
    }
    
    func addSegment(point:Point)->Segment?{
        let segment = Segment(point:point)
        return self.addSegment(_segment:segment)
    }
    
    func addSegment(point:Point, d:Float, color:Color, alpha:Float)->Segment?{
        var segment = Segment(point:point)
        segment.diameter = d
        segment.color = color;
        segment.alpha = alpha;
        weightBuffer.push(v: d);
        return self.addSegment(_segment:segment)
    }
    
    
    func addSegment(segments:[Segment])->[Segment]{
        for i in 0...segments.count-1{
            _ = self.addSegment(_segment:segments[i])
        }
        
        return segments
    }
    
    
    func getLength()->Float{
        var l = Float(0.0);
        if(segments.count>1){
        for i in 1...segments.count-1{
            l +=  segments[i-1].point.dist(point: segments[i].point)
            }}
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
    
    /*init(fromPoint:Point,angle:Float,length:Float){
        self.fromPoint = fromPoint;
        self.toPoint = fromPoint.pointAtDistance(length,a:angle)
    }
    
    init(center:Point,radius:Float,startAngle:Float,endAngle:Float,clockwise:Bool){
        self.center = center
        self.radius = radius
        self.startAngle = startAngle
        self.endAngle = endAngle
        self.clockwise = clockwise
    }*/
    
   func lineTo(to:Point) {
        // Let's not be picky about calling moveTo() first:
        let seg = Segment(point:to)
       _ = self.addSegment(_segment:seg);
    }
    
    
   
    
    
}


        

