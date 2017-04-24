//
//  Drawing.swift
//  PaletteKnife
//
//  Created by JENNIFER MARY JACOBS on 6/24/16.
//  Copyright © 2016 pixelmaid. All rights reserved.
//

import Foundation

//Drawing
//stores geometry

class Drawing: TimeSeries, WebTransmitter, Hashable{
    var id = NSUUID().uuidString;
    var activeStrokes = [String:[Stroke]]();
    var allStrokes = [String:[Stroke]]();
    var bakeQueue = [String:[Stroke]]();
    var bakedStrokes = [String:[Stroke]]();
    var drawnStrokes  = [String:[Stroke]]();
    // var geometry = [Geometry]();
    var transmitEvent = Event<(String)>()
    var initEvent = Event<(WebTransmitter,String)>()

    let gCodeGenerator = GCodeGenerator();
    let svgGenerator = SVGGenerator();

    var geometryModified = Event<(Geometry,String,String)>()
    
    override init(){
        super.init();
        gCodeGenerator.startDrawing();
        self.name = "drawing"
    }
    
    //TODO: fix getGcode function
    func getGcode()->String{
       /* var source = gCodeGenerator.source;
        for list in self.allStrokes{
            
            for i in 0..<list.1.count{
                source+=list.1[i].gCodeGenerator.source;
                source+=gCodeGenerator.endSegment(list.1[i].segments[list.1[i].segments.count-1]);
            }
        }
        source += gCodeGenerator.end();(
        return source*/
        return ""
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
        if (self.bakeQueue[parentID] == nil){
            self.bakeQueue[parentID] = [Stroke]()
            
        }
        if (self.bakedStrokes[parentID] == nil){
            self.bakedStrokes[parentID] = [Stroke]()
            
        }

        self.allStrokes[parentID]!.append(stroke);
        self.bakeQueue[parentID]!.append(stroke)
        //self.geometry.append(self.currentStroke!)
        var data = "\"drawing_id\":\""+self.id+"\","
        data += "\"stroke_id\":\""+stroke.id+"\","
        data += "\"time\":\""+String(self.getTimeElapsed())+"\","
        
        data += "\"type\":\"new_stroke\""
        //self.transmitEvent.raise((data))
        
        //TODO: START HERE TOMORROW- don't know position of new stroke here, need to adjust gcode generator to match
        return stroke;
    }
    
    func addSegmentToStroke(parentID:String, point:Point, weight:Float, color:Color, alpha:Float){
        if (self.activeStrokes[parentID] == nil){
            return
        }
        for i in 0..<self.activeStrokes[parentID]!.count{
            let currentStroke = self.activeStrokes[parentID]![i]
            var seg = currentStroke.addSegment(point: point,d:weight)
            if(seg != nil){
            seg!.color = color;
            seg!.alpha = alpha;
            var data = "\"drawing_id\":\""+self.id+"\","
            data += "\"stroke_id\":\""+currentStroke.id+"\","
            data += "\"type\":\"stroke_data\","
            data += "\"strokeData\":{"
            data += "\"segments\":"+seg!.toJSON()+",";
            data += "\"lengths\":{\"length\":"+String(currentStroke.getLength())+",\"time\":"
            data += String(self .getTimeElapsed())
            data += "}}"
            //self.transmitEvent.raise((data))
            self.geometryModified.raise(data: (seg!,"SEGMENT","DRAW"))
            }
        }
    }
    
    
    func bake(parentID:String){
        var source_string = "[";
        if(bakeQueue[parentID] != nil){
        var bq = bakeQueue[parentID]!
        for i in 0..<bq.count{
            var source = bq[i].gCodeGenerator.source;
            for j in 0..<source.count{
                if(j>0){
                    source_string += ","
                }
                source_string += "\""+source[j]+"\""
            }
            
            //source_string += "]"
            source_string += ",\""+gCodeGenerator.endSegment(segment: bakeQueue[parentID]![i].segments[bakeQueue[parentID]![i].segments.count-1])+"\"]"
            bakedStrokes[parentID]!.append(bq[i]);
        }
        bakeQueue[parentID]?.removeAll();
        var data = "\"drawing_id\":\""+self.id+"\","
        data += "\"type\":\"gcode\","
        data += "\"data\":"+source_string
        self.transmitEvent.raise(data: (data));
        print("source",data);
        }
    }
    
    
    func checkBake(x:Float,y:Float,z:Float){
        for strokeList in bakedStrokes{
            for stroke in strokeList.1{
                let hit = stroke.hitTest(testPoint: Point(x:x,y:y), threshold: 5)
                if(hit != nil){
                    self.geometryModified.raise(data: (hit!,"SEGMENT","BAKE_DRAW"))
                    return;
                }
            }
        }
    }
    
    func jogAndBake(parentID:String){
        
        var source_string = "[";
        var bq = bakeQueue[parentID]!
        for i in 0..<bq.count{
            var source = bq[i].gCodeGenerator.source;
             var segments = bq[i].segments;
            print("segments=\(segments)");
            let _x = Numerical.map(value: segments[0].point.x.get(id: nil), istart:GCodeGenerator.pX, istop: 0, ostart: GCodeGenerator.inX, ostop: 0)
            
            let _y = Numerical.map(value: segments[0].point.y.get(id: nil), istart:0, istop:GCodeGenerator.pY, ostart:  GCodeGenerator.inY, ostop: 0 )
            
            source_string += "\""+bq[i].gCodeGenerator.jog3(x: _x,y:_y,z: GCodeGenerator.retractHeight)+"\"";
            for j in 0..<source.count{
          
                source_string += ",\""+source[j]+"\""
            }
           
            source_string+=",\""+gCodeGenerator.endSegment(segment: segments[segments.count-1])+"\"]"
            bakedStrokes[parentID]!.append(bq[i]);
        }
        bakeQueue[parentID]?.removeAll();
        var data = "\"drawing_id\":\""+self.id+"\","
        data += "\"type\":\"gcode\","
        data += "\"data\":"+source_string
        self.transmitEvent.raise(data: (data));
        print("source",data);

    }
    
    func transmitJogEvent(data:String){
        var source_string = "[";
        source_string+=data+"]"
       var data = "\"drawing_id\":\""+self.id+"\","
        data += "\"type\":\"gcode\","
        data += "\"data\":"+source_string
        print("jog data to transmit = \(data)");
        self.transmitEvent.raise(data: (data));
    }
    
}


// MARK: Equatable
func ==(lhs:Drawing, rhs:Drawing) -> Bool {
    return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
}


