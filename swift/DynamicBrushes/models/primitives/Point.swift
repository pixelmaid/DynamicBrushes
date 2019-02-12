//
//  Point.swift
//  Palette-Knife
//
//  Created by JENNIFER MARY JACOBS on 5/5/16.
//  Copyright © 2016 pixelmaid. All rights reserved.
//

import Foundation
import UIKit

class Point:Observable<(Float,Float)>,Geometry{
  
    let x:Observable<Float>
    let y:Observable<Float>
    var prevX = Float(0);
    var prevY = Float(0);
    var angle = Float(0);
    let xKey = NSUUID().uuidString;
    let yKey = NSUUID().uuidString;
    var storedValue = Float(0);
    
    
    init(x:Float,y:Float) {
        //==BEGIN OBSERVABLES==//
        self.x = Observable<Float>(0);
        self.y = Observable<Float>(0);
        //==END OBSERVABLES==//

        super.init((x, y))
        self.x.set(newValue: x);
        self.y.set(newValue: y);
        self.angle = atan2(y, x) * Float(180 / Float.pi);

        //==BEGIN APPEND OBSERVABLES==//
        observables.append(self.x);
        observables.append(self.y)
        //==END APPEND OBSERVABLES==//

        self.x.name = "x"
        self.y.name = "y"
     
    }
    
    func toJSON()->String{
        let string = "\"x\":"+String(self.x.get(id: nil))+",\"y\":"+String(self.y.get(id: nil))
        return string;
    }
    
    override func destroy(){
        x.destroy();
        y.destroy();
        super.destroy();
    }
    
    
     func set(val:Point){
        let point = val 
        self.set(x:point.x.get(id: nil),y:point.y.get(id: nil))
    }
    
    func set(x:Float,y:Float){
        self.x.set(newValue: x);
        self.y.set(newValue: y);
    }
    
    override func setSilent(newValue: (Float, Float)) {
        self.x.setSilent(newValue: newValue.0);
        self.y.setSilent(newValue: newValue.1);

    }
    
    override func get(id:String?)->(Float,Float){
        return (self.x.get(id: nil),self.y.get(id: nil))
    }

    /*override func getSilent()->(Float,Float){
        return (self.x.getSilent(),self.y.getSilent())
    }*/
    
    func clone()->Point{
        return Point(x:self.x.get(id: nil),y:self.y.get(id: nil))
    }
    
    func add(point:Point)->Point{
        return Point(x:self.x.get(id: nil)+point.x.get(id: nil),y:self.y.get(id: nil)+point.y.get(id: nil));
    }
    
    func sub(point:Point)->Point {
        let v = MathUtil.sub(x1:self.x.get(id: nil),y1:self.y.get(id: nil),x2:point.x.get(id: nil),y2:point.y.get(id: nil));
        return Point(x:v.0,y:v.1);
    }
    
    func div(val:Float) ->Point{
        return Point(x: self.x.get(id: nil) / val, y: self.y.get(id: nil) / val);
    }
    
    func mul(val:Float)->Point {
        return Point(x: self.x.get(id: nil) * val, y: self.y.get(id: nil) * val);
    }
    
    func div(point:Point) ->Point{
        return Point(x:self.x.get(id: nil) / point.x.get(id: nil), y: self.y.get(id: nil) / point.y.get(id: nil));
    }
    
    func mul(point:Point) ->Point{
        return Point(x:self.x.get(id: nil) * point.x.get(id: nil), y:self.y.get(id: nil) * point.y.get(id: nil));
    }
    
    func dist(point:Point)->Float{
        return sqrtf(distanceSqrd(p1: self,p2: point));
        
    }
    
    func distanceSqrd(p1:Point, p2:Point)->Float{
        return powf((p1.x.get(id: nil)-p2.x.get(id: nil)), 2.0)+powf((p1.y.get(id: nil)-p2.y.get(id: nil)), 2.0)
    }
    
    static func isCollinear(x1:Float, y1:Float, x2:Float, y2:Float)->Bool{

        return abs(x1 * y2 - y1 * x2) <= sqrt((x1 * x1 + y1 * y1) * (x2 * x2 + y2 * y2)) * Numerical.TRIGONOMETRIC_EPSILON;
        

    }
    
    static func isOrthoganal(x1:Float, y1:Float, x2:Float, y2:Float)->Bool{
        
        return abs(x1 * x2 + y1 * y2) <= sqrt((x1 * x1 + y1 * y1) * (x2 * x2 + y2 * y2)) * Numerical.TRIGONOMETRIC_EPSILON;
        
    }

    
    //Returns the length of a vector sqaured. Faster than Length(), but only marginally
    static func lengthSqrd(vec:Point)->Float {
    return pow(vec.x.get(id: nil), 2) + pow(vec.y.get(id: nil), 2);
    }
    
    //Returns the length of vector'
    func length()->Float {
    return sqrtf(Point.lengthSqrd(vec: self));
    }
    
    //Returns a new vector that has the same direction as vec, but has a length of one.
    static func normalize(vec:Point)->Point {
    if (vec.x.get(id: nil) == 0 && vec.y.get(id: nil) == 0) {
        return vec;
    }
    
        return vec.div(val:vec.length());
    }
    
    
    static func normalize(vec:Point,length:Float)->Point{
        let current = vec.length()
        var scale:Float;
        if(current == 0){
            scale = 0;
        }
        else{
            scale = length/current;
        }
        let point =  Point(x:vec.x.get(id: nil) * scale, y:vec.y.get(id: nil) * scale);
        // Preserve angle.
        if (scale >= 0){
            point.angle = vec.angle;
        }
        return point;
    }
    
    //Computes the dot product of a and b'
    func dot(b:Point)->Float {
    return (self.x.get(id: nil) * b.x.get(id: nil)) + (self.y.get(id: nil) * b.y.get(id: nil));
    }
    
    func cross(point:Point)->Float {
        return self.x.get(id: nil) * point.y.get(id: nil) - self.y.get(id: nil) * point.x.get(id: nil);
    }
    
    static func projectOnto(v:Point, w:Point)->Point{
    //'Projects w onto v.'
        return v.mul(val:w.dot(b: v) / Point.lengthSqrd(vec: v));
    }
    
    
    func pointAtDistance(d:Float,a:Float)->Point{
        let x = self.x.get(id: nil) + (d * cos(a*Float(Float.pi/180)))
        let y = self.y.get(id: nil) + (d * sin(a*Float.pi/180))
        return Point(x: x,y: y)
    }
    
    //returns new rotated point, original point is unaffected
    func rotate(angle:Float, origin:Point)->Point{
        let a = angle * Float.pi/180;
        let centerX = origin.x.get(id: nil);
        let centerY = origin.y.get(id: nil);
        let x = self.x.get(id: nil);
        let y = self.y.get(id: nil);
        let newX = centerX + (x-centerX)*cos(a) - (y-centerY)*sin(a);
        
        let newY = centerY + (x-centerX)*sin(a) + (y-centerY)*cos(a);
        return Point(x:newX,y:newY)
    }
    

    
    
     
     func getDirectedAngle(point:Point)->Float {
     return atan2(self.cross(point: point), self.dot(b: point)) * 180 / Float.pi;
     }
     
     
    
    func toCGPoint()->CGPoint{
        return CGPoint(x:CGFloat(self.x.get(id: nil)),y:CGFloat(self.y.get(id: nil)))
    }
    
    
    
    
}

//point with an internal listener
//be careful when using. will cause memory leaks if not destroyed
//should never be initialized inside a function.

class LinkedPoint:Point{
    override init(x: Float, y: Float) {
        super.init(x: x, y: y);
        self.name = "linked_point"
         _ = self.x.didChange.addHandler(target: self, handler: LinkedPoint.coordinateChange,key:xKey)
         _ = self.y.didChange.addHandler(target: self, handler: LinkedPoint.coordinateChange,key:yKey)

    }
    
    //coordinateChange
    //handler that only triggers when both x and y have been updated (assuming they're both constrained)
    func coordinateChange(data:(String, Float,Float),key:String){
        let name = data.0;
        #if DEBUG
            // print("change for \(self.name)",x.constrainedAndActive(),y.constrainedAndActive(),name);
        #endif

        let oldValue = data.1;
        _ = data.2;
        if(!x.constrained && !y.constrained){
            return;
        }
        else if(x.constrainedAndPassive() && y.constrainedAndPassive()){
            if(self.x.invalidated && self.y.invalidated){
                if(name == "x"){
                    didChange.raise(data: (name, (oldValue,storedValue),(self.x.get(id: nil),self.y.get(id: nil))));
                    #if DEBUG
                       // print("raise change",self.name)
                    #endif
                }
                else if(name == "y"){
                    didChange.raise(data: (name, (storedValue,oldValue),(self.x.get(id: nil),self.y.get(id: nil))));
                    #if DEBUG
                        //print("raise change",self.name)
                    #endif
                }
                
            }
            else{
                storedValue = oldValue;
            }
            
        }
        else if(x.constrainedAndActive() && !y.constrainedAndActive() && name == "x" || x.constrainedAndPassive() && !y.constrainedAndPassive() && name == "x"){
            didChange.raise(data: (name, (oldValue,self.y.get(id: nil)), (self.x.get(id: nil),self.y.get(id: nil))))
            #if DEBUG
               // print("raise change",self.name)
            #endif
        }
        else if(!x.constrainedAndActive() && y.constrainedAndActive() && name == "y" || !x.constrainedAndPassive() && y.constrainedAndPassive() && name == "y"){
            didChange.raise(data: (name, (self.x.get(id: nil),oldValue), (self.x.get(id: nil),self.y.get(id: nil))))
            #if DEBUG
                //print("raise change",self.name)
            #endif
        }
        else{
            
            if(self.x.invalidated && self.y.invalidated){
                if(name == "x"){
                    didChange.raise(data: (name, (oldValue,storedValue),(self.x.get(id: nil),self.y.get(id: nil))));
                    #if DEBUG
                        //print("raise change",self.name)
                    #endif
                }
                else if(name == "y"){
                    didChange.raise(data: (name, (storedValue,oldValue),(self.x.get(id: nil),self.y.get(id: nil))));
                    #if DEBUG
                        //print("raise change",self.name)
                    #endif
                }
                
            }
            else{
                storedValue = oldValue;
            }
        }
    }

}

func ==(lhs: Point, rhs: Point) -> Bool {
    return lhs.x.get(id: nil) == rhs.x.get(id: nil) && lhs.y.get(id: nil) == rhs.y.get(id: nil)
}





