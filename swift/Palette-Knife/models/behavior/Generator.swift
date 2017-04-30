//
//  Variable.swift
//  PaletteKnife
//
//  Created by JENNIFER MARY JACOBS on 7/28/16.
//  Copyright © 2016 pixelmaid. All rights reserved.
//

import Foundation


class Generator:Observable<Float>{
    
    init(){
        super.init(0)
    }
    
}

class Interval:Generator{
    var val = [Float]();
    var index = 0;
    var infinite = false;
    let inc:Float
    
    
    init(inc:Float,times:Int?){
        self.inc = inc;
        super.init();
        if(times != nil){
            for i in 1..<times!{
                val.append(Float(i)*self.inc)
            }
        }
        else{
            infinite = true;
            self.incrementIndex();
            
        }
    }
    
    func incrementIndex(){
        index += 1;
        
    }
    
    override func get(id:String?) -> Float {
        if(infinite){
            let inf = Float(self.index)*self.inc
            print("interval val \(inf,inc)");
            return inf;
        }
        if(index < val.count){
            let v = val[index]
            
            return v;
        }
        return -1;
    }
    
    
}

class Buffer:Generator{
    var val = [Float]();
    var index = 0;
    
    func push(v: Float){
        val.append(v)
    }
    
    func incrementIndex(){
        if(index<val.count-1){
            index += 1;
        }
    }
    
    override func get(id:String?) -> Float {
        let v = val[index]
        self.incrementIndex();
        return v;
    }
    
}

class CircularBuffer:Generator{
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

class Range:Generator{
    var val = [Float]();
    var index = Observable<Float>(0);
    init(min:Int,max:Int,start:Float,stop:Float){
        let increment = (stop-start)/Float(max-min)
        for i in min...max-1{
            val.append(start+increment*Float(i))
        }
    }
    
    func incrementIndex(){
        index.set(newValue: Float(index.get(id: nil) + 1));
        if(index.get(id: nil)>=Float(val.count)){
            index.set(newValue: 0);
        }
    }
    override func get(id:String?) -> Float {
        let v = val[Int(index.get(id: nil))]
        self.incrementIndex();
        return v;
    }
    
    
    
}



class Ease: Generator{
    let a:Float;
    let b:Float;
    let k:Float;
    var x:Float;
    var val = Float(0);
    
    init(a:Float,b:Float, k:Float){
        self.a = a;
        self.b = b;
        self.k = k;
        self.x = 0;
    }
        
    override func get(id:String?) -> Float {
        self.val = a/(1+pow(2.7182818284590451,(x-b)*k))
        print("ease val: \(self.val,self.x,a,b,k)");

        self.x += 1;
        return self.val
    }

}

//returns an incremental value updating to infinity;
class Increment:Generator{
    var inc:Observable<Float>
    var start:Observable<Float>
    var index = Observable<Int>(0)
    
    init(inc:Observable<Float>, start:Observable<Float>){
        self.inc = Observable<Float>(inc.get(id: nil));
        self.start = start;
    }
    
    func incrementIndex(){
        index.set(newValue: index.get(id: nil)+1);
        
    }
    override func get(id:String?) -> Float {
        let v = ((Float(index.get(id: nil))*inc.get(id: nil)) + start.get(id: nil));
        self.incrementIndex();
        return v;
    }
    
    
    
    
}

class Index:Generator{
    var val:Observable<Float>
    init (val:Observable<Float>){
        self.val = val;
    }
    override func get(id:String?) -> Float {
        return self.val.get(id: nil);
    }
}

class Sine:Generator{
    var freq:Float
    var phase:Float
    var amp:Float
    
    var index = Observable<Float>(0);
    
    init(freq:Float, amp:Float, phase:Float){
        self.freq = freq;
        self.phase = phase;
        self.amp = amp;
    }
    
    func incrementIndex(){
        index.set(newValue: index.get(id: nil)+1);
        
    }
    override func get(id:String?) -> Float {
        let v =  sin(self.index.get(id: nil)*freq+phase)*amp+amp;
        self.incrementIndex();
        return v;
    }

    
}



class RandomGenerator: Generator{
    let start:Float
    let end:Float
    var val:Float;
    init(start:Float,end:Float){
        self.start = start;
        self.end = end;
        val = Float(arc4random()) / Float(UINT32_MAX) * abs(self.start - self.end) + min(self.start, self.end)
        
    }
    
    override func get(id:String?) -> Float {
        val = Float(arc4random()) / Float(UINT32_MAX) * abs(self.start - self.end) + min(self.start, self.end)
        return val
    }
}


class easeInOut:Generator{
    var start:Observable<Float>
    var stop:Observable<Float>
    var max:Observable<Float>
    var range:Observable<Float>
    var index = Observable<Float>(0)
    
    
    init(start:Observable<Float>,stop:Observable<Float>,max:Observable<Float>){
        self.start = Observable<Float>(start.get(id: nil));
        self.stop = Observable<Float>(stop.get(id: nil));
        self.max = Observable<Float>(max.get(id: nil));
        self.range = Observable<Float>(stop.get(id: nil)-start.get(id: nil));
    }
    
    func incrementIndex(){
        index.set(newValue: index.get(id: nil)+1);
        
    }
    /*override func get() -> Float {
     let v = ((Float(index.get(nil))*inc.get(nil)) + start.get(nil));
     self.incrementIndex();
     return v;
     }*/
    
}


class Alternate:Generator{
    var val = [Float]();
    var index = 0;
    
    init(values:[Float]){
        val = values;
    }
    
    func incrementIndex(){
        index += 1;
        if(index>=val.count){
            index=0;
        }
    }
    override func get(id:String?) -> Float {
        let v = val[index]
        self.incrementIndex();
        return v;
    }
    
    
    
}
