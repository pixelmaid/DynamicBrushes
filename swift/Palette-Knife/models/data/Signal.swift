//
//  Variable.swift
//  PaletteKnife
//
//  Created by JENNIFER MARY JACOBS on 7/28/16.
//  Copyright © 2016 pixelmaid. All rights reserved.
//

import Foundation



class Signal:Observable<Float>{
    private var index:Float = -1;
    internal var signalBuffer = [Float:Float]();
    
    internal var position:Int = 0;
    internal let fieldName:String!
    internal let displayName:String!
    internal let collectionId:String!;
    public let groupId:String?
    
    
    var dataSubscribers = [String:Observable<Float>]();
    var id:String
    //    var param = Observable<Float>(1.0);
    required init(id:String,fieldName:String, displayName:String, collectionId:String, groupId:String?){
        self.id = id;
        self.fieldName = fieldName;
        self.collectionId = collectionId
        self.groupId = groupId;
        
        super.init(0)
        RequestHandler.registerObservable(observableId: id, observable: self)
    }
    
    override func get(id:String?) -> Float {
        
        let v:Float;
        
        v = signalBuffer[index]!;
        
        self.setSilent(newValue: v);
        return super.get(id: id);
        
    }
    
    
    override func getSilent()->Float{
        return signalBuffer[index]!
    }
    
    
    
    func setHash(h:Float){
        self.index = h;
    }
    
    func setSignal(s:[Float]){
        self.signalBuffer.removeAll();
        for i in 0..<s.count{
            signalBuffer[Float(i)] = s[i];
        }
    }
    
    
    func addValue(h:Float,v:Float){
        signalBuffer[h] = v;
        self.setHash(h:h);
    }
    
    func incrementIndex(){
        index = index+1.0;
    }
    
    func clearSignal(){
        signalBuffer.removeAll();
    }
}


class LiveSignal:Signal{
    
}


class Recording:Signal{
    private var next:Recording?
    private var prev:Recording?
    private var lastSample:Float = 0;
    
    
    func getNext()->Recording?{
        if(next != nil){
            return next!;
        }
        return nil;
    }
    
    func getPrev()->Recording?{
        if(prev != nil){
            return prev!;
        }
        return nil;
    }
    
    func setNext(r:Recording){
        next = r;
    }
    
    func setPrev(r:Recording){
        prev = r;
    }
    
    override func addValue(h:Float,v:Float){
        super.addValue(h: h, v: v);
        self.lastSample = h;
    }
    
    func getTimeOrderedList()->[Float]{
        var orderedList = [Float]();
        var hashValue = Float(0);
        while(hashValue <= self.lastSample){
            if(self.signalBuffer[hashValue] != nil){
                orderedList.append(signalBuffer[hashValue]!);
            }
            hashValue+=1.0;
        }
        
        return orderedList;
    }
}


class EventRecording:Signal{
    
}

class StylusEventRecording:EventRecording{
    let stylusUp = 0.0;
    let stylusMove = 1.0;
    let stylusDown = 2.0;
}

class Sine:Signal{
    var freq:Float
    var phase:Float
    var amp:Float
    
    var index = Observable<Float>(0);
    
    
    init(id:String, freq:Float, amp:Float, phase:Float){
        self.freq = freq;
        self.phase = phase;
        self.amp = amp;
        super.init(id:id,fieldName: "sine",collectionId: "generator");
    }
    
    
    override func get(id:String?) -> Float {
        let v =  sin(self.index.get(id: nil)*freq+phase)*amp/2+amp/2;
        return v;
    }
    
    
}


class MovingAverage:Signal{
    var queue = [Float]()
    var index = 0;
    let alpha = Float(0.009)
    var val = Float(0)
    var averageCount = 20
    override func set(newValue: Float) {
        self.queue.append(newValue)
    }
    
    
    func hardReset(val:Float){
        self.queue.removeAll();
    }
    
    override func get(id:String?)->Float{
        #if DEBUG
        #endif
        if(queue.count>averageCount){
            var sum = Float(0.0)
            for i in 0..<averageCount{
                sum += queue[i];
            }
            let avg = sum/Float(averageCount)
            //let _val = last_val*alpha + (1.0-alpha)*Float(index)
            self.val = avg
            self.queue.removeFirst();
        }
        print("moving average",self.val);
        
        return self.val;
    }
}




class Interval:Signal{
    var val = [Float]();
    var index = 0;
    var infinite = false;
    let inc:Float
    
    
    init(id:String,inc:Float,times:Int?){
        self.inc = inc;
        super.init(id:id, fieldName: "interval", collectionId: "generator");
        if(times != nil){
            for i in 1..<times!{
                val.append(Float(i)*self.inc)
            }
        }
        else{
            infinite = true;
        }
    }
    
    func reset(){
        self.index = 0;
    }
    
    override func get(id:String?) -> Float {
        if(infinite){
            let inf = Float(self.index)*self.inc
            return inf;
        }
        if(index < val.count){
            let v = val[index]
            
            return v;
        }
        return -1;
    }
    
    
}

class Buffer:Signal{
    var val = [Float]();
    var index = 0;
    
    func push(v: Float){
        val.append(v)
    }
    
    
    override func get(id:String?) -> Float {
        let v = val[index]
        self.incrementIndex();
        return v;
    }
    
}

class CircularBuffer:Signal{
    var val = [Float]();
    var bufferEvent = Event<(String)>()
    func push(v: Float){
        val.append(v)
        
    }
    
    func incrementIndex(id:String){
        var index = subscribers[id]!
        if(index<val.count-1){
            index += 1;
        }
        else{
            index = 0;
            // bufferEvent.raise("BUFFER_LIMIT_REACHED");
        }
        subscribers[id] = index;
    }
    
    override func get(id:String?) -> Float {
        let index = subscribers[id!]!
        let v = val[index]
        self.incrementIndex(id: id!);
        return v;
    }
    
    
    
}

class Sawtooth:Signal{
    var val = [Float]();
    var index = Observable<Float>(0);
    init(id:String,min:Int,max:Int,start:Float,stop:Float){
        super.init(id:id,fieldName: "range", collectionId: "generator")
        let increment = (stop-start)/Float(max-min)
        for i in min...max-1{
            val.append(start+increment*Float(i))
        }
    }
    
    override func get(id:String?) -> Float {
        let v = val[Int(index.get(id: nil))]
        self.incrementIndex();
        return v;
    }
    
    
    
}



class Ease: Signal{
    let a:Float;
    let b:Float;
    let k:Float;
    var x:Float;
    var val = Float(0);
    
    init(id:String,a:Float,b:Float, k:Float){
        
        
        self.a = a;
        self.b = b;
        self.k = k;
        self.x = 0;
        super.init(id:id, fieldName: "ease", collectionId: "generator")
    }
    
    override func get(id:String?) -> Float {
        self.val = a/(1+pow(2.7182818284590451,(x-b)*k))
        #if DEBUG
            print("ease val: \(self.val,self.x,a,b,k)");
        #endif
        self.x += 1;
        return self.val
    }
    
}


//TODO: need to remove these eventually when system is refactored so that these are brush props, not generators
class Index:Signal{
    var val:Observable<Float>
    init (id:String, val:Observable<Float>){
        self.val = val;
        super.init(id:id, fieldName: "index", collectionId: "generator")
    }
    override func get(id:String?) -> Float {
        return self.val.get(id: nil);
    }
}

class SiblingCount:Signal{
    var val:Observable<Float>
    init (id:String,val:Observable<Float>){
        self.val = val;
        super.init(id:id, fieldName: "siblingcount", collectionId: "generator")
    }
    override func get(id:String?) -> Float {
        return self.val.get(id: nil);
    }
}


class Triangle:Signal{
    var freq:Float
    var min:Float
    var max:Float
    
    var index = Observable<Float>(0);
    
    init(id:String, min:Float, max:Float, freq:Float){
        self.freq = freq;
        self.min = min;
        self.max = max;
        super.init(id:id, fieldName: "triangle", collectionId: "generator")
    }
    
    
    override func get(id:String?) -> Float {
        let ti = 2.0 * Float.pi * (880 / 44100);
        let theta = ti * self.index.get(id: nil)
        let _v = 1.0 - Float.abs(Float(theta.truncatingRemainder(dividingBy: 4)-2));
        let v = MathUtil.map(value: _v, low1: -1, high1: 1, low2: min, high2: max)
        self.incrementIndex();
        #if DEBUG
            print("triangle wave val",v,index.get(id: nil))
        #endif
        return v;
    }
    
    
}

class Square:Signal{
    var freq:Float
    var min:Float
    var max:Float
    var currentVal:Float
    
    var index = Observable<Float>(0);
    
    init(id:String, min:Float, max:Float, freq:Float){
        self.freq = freq;
        self.min = min;
        self.max = max;
        self.currentVal = min;
        super.init(id:id, fieldName: "square", collectionId: "generator")
    }
    
    override func get(id:String?) -> Float {
        let v:Float;
        self.incrementIndex();
        
        if(index.get(id: nil) == 0.0){
            if(currentVal == min){
                currentVal = max;
            }
            else{
                currentVal = min;
            }
        }
        
        return currentVal;
        
    }
    
    
}



class Random: Signal{
    let start:Float
    let end:Float
    var val:Float;
    init(id:String,start:Float,end:Float){
        self.start = start;
        self.end = end;
        val = Float(arc4random()) / Float(UINT32_MAX) * abs(self.start - self.end) + min(self.start, self.end)
        super.init(id:id, fieldName: "random", collectionId: "generator")
        
    }
    
    override func get(id:String?) -> Float {
        val = Float(arc4random()) / Float(UINT32_MAX) * abs(self.start - self.end) + min(self.start, self.end)
        return val
    }
}


class easeInOut:Signal{
    var start:Observable<Float>
    var stop:Observable<Float>
    var max:Observable<Float>
    var range:Observable<Float>
    var index = Observable<Float>(0)
    
    
    init(id:String, start:Observable<Float>,stop:Observable<Float>,max:Observable<Float>){
        self.start = Observable<Float>(start.get(id: nil));
        self.stop = Observable<Float>(stop.get(id: nil));
        self.max = Observable<Float>(max.get(id: nil));
        self.range = Observable<Float>(stop.get(id: nil)-start.get(id: nil));
        super.init(id:id, fieldName: "easeInOut", collectionId: "generator")
    }
    
    
    /*override func get() -> Float {
     let v = ((Float(index.get(nil))*inc.get(nil)) + start.get(nil));
     self.incrementIndex();
     return v;
     }*/
    
}


class Alternate:Signal{
    var val = [Float]();
    var index = 0;
    
    init(id:String, values:[Float]){
        val = values;
        super.init(id:id, fieldName: "alternate", collectionId: "generator")
    }
    
    
    override func get(id:String?) -> Float {
        let v = val[index]
        self.incrementIndex();
        return v;
    }
    
    
    
}

