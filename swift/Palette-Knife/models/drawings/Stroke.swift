//
//  Stroke.swift
//  Palette-Knife
//
//  Created by JENNIFER MARY JACOBS on 5/5/16.
//  Copyright © 2016 pixelmaid. All rights reserved.
//
import Foundation

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
    var time = Float(0);
    
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
    
    
    func getTimeDelta()->Float{
        let prevSeg = self.getPreviousSegment();
        if(prevSeg == nil){
            return 0;
        }
        
        let currentTime = self.time;
        let prevTime = prevSeg!.time;
        return currentTime-prevTime;
    }
    
   
    func hitTest(testPoint:Point,threshold:Float)->Bool{
        let dist = self.point.dist(point: testPoint);
        if dist <= threshold {
            return true
        }
        return false;
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


/*class Arc:Geometry {
    var center:Point
    var radius:Float
    var startAngle:Float
    var endAngle:Float
    
    
    init(center:Point,startAngle:Float,endAngle:Float, radius:Float)    {
        self.center=center
        self.startAngle = startAngle
        self.endAngle = endAngle
        self.radius = radius
 
    }
    
    convenience init(point:Point,length:Float,angle:Float, radius:Float)    {
        
        let p2 = point.pointAtDistance(length, a: angle);
        let p3 = Line(p:point,v:p2,asVector: false).getMidpoint()
        let centerX =  p3.x + sqrt(pow(radius,2)-pow((length/2),2))*(point.y-p2.y)/length
        let centerY = p3.y + sqrt(pow(radius,2)-pow((length/2),2))*(p2.x-point.x)/length
        let center = Point(x: centerX, y: centerY)
        let startAngle = atan2(point.y - center.y, point.x - center.x);
        let endAngle = atan2(p2.y - center.y, p2.x - center.x);
        self.init(center:center,startAngle:startAngle,endAngle:endAngle,radius:radius)
        
    }
    
    convenience init(x1:Float,y1:Float,x2:Float,y2:Float,x3:Float,y3:Float){
        
        let r = Line(px:x1,py: y1,vx: x2,vy: y2,asVector: false)
        let t = Line(px: x2,py: y2,vx: x3,vy: y3,asVector: false)
        let rM = r.getSlope();
        //let rB = r.getYIntercept();
        let tM = t.getSlope();
        //let tB = t.getYIntercept();
        
        
        let r_midpoint = r.getMidpoint();
        //let t_midpoint = t.getMidpoint();
        let rpM = 0-(1/rM)
        //let tpM = 0-(1/tM)
        let rpB = -rpM*r_midpoint.x+r_midpoint.y;
        
        let centerX = (rM*tM*(y3-y1)+rM*(x2+x3)-tM*(x1+x2))/(2*(rM-tM))
        let centerY = rpM*centerX + rpB
        let center = Point(x:centerX,y:centerY)
        let radius = center.dist(Point(x:x1,y:y1));
        let startAngle = atan2(y1 - center.y, x1 - center.x);
        let endAngle = atan2(y3 - center.y, x3 - center.x);
        
        
       self.init(center:center,startAngle:startAngle,endAngle:endAngle,radius:radius)
    }
    func toJSON()->String{
        let string = "\"center\":{\"x\":"+String(self.point.x)+",\"y\":"+String(self.point.y)+"\""
        return string
    }



}*/


// Stroke: Model for storing a stroke object in multiple representations
// as a series of segments
// as a series of vectors over time
class Stroke:TimeSeries, Geometry {
    var segments = [Segment]();
    var xBuffer = CircularBuffer();
    var yBuffer = CircularBuffer();
    var weightBuffer = CircularBuffer();
    let id = NSUUID().uuidString;
    let gCodeGenerator = GCodeGenerator();
    var parentID: String;
    var selected = false;
    
    init(parentID:String){
        self.parentID = parentID;
        super.init();
        gCodeGenerator.startNewStroke();
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
    
    
    func addSegment(_segment:Segment)->Segment?{
        var segment = _segment;
        segment.parent = self
        segment.index = self.segments.count;
        segment.time = Float(0-timer.timeIntervalSinceNow);
        
        if(segments.count>0){
            let prevSeg = segments[segments.count-1];
            let dist = segment.point.dist(point: prevSeg.point)
            
            if(dist < 10){
                return nil;
            }
            xBuffer.push(v: segment.point.x.get(id: nil)-prevSeg.point.x.get(id: nil))
            yBuffer.push(v: segment.point.y.get(id: nil)-prevSeg.point.y.get(id: nil))

        }
        else{
            xBuffer.push(v: 0);
            yBuffer.push(v: 0)
        }
        segments.append(segment)

        gCodeGenerator.drawSegment(segment: segment)
        
        return segment
    }
    
    func addSegment(point:Point)->Segment?{
        let segment = Segment(point:point)
        return self.addSegment(_segment:segment)
    }
    
    func addSegment(point:Point, d:Float)->Segment?{
        var segment = Segment(point:point)
        segment.diameter = d
        weightBuffer.push(v: d);
        return self.addSegment(_segment:segment)
    }
    
    
    func addSegment(segments:[Segment])->[Segment]{
        for i in 0...segments.count-1{
            self.addSegment(_segment:segments[i])
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
        self.addSegment(_segment:seg);
    }
    
    
   
    
    
}


        

