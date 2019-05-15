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

class MovingAverage:Generator{
    var queue = [Float]()
    var index = 0;
    let alpha = Float(0.009)
    var val = Float(0)
    var averageCount = 20
    override func set(newValue: Float) {
        self.queue.append(newValue)
    }
    
    func hardReset(val:Float){
        self.val = val;
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

class Interval:Generator{
    var val = [Float]();
    var index = 1;
    let inc:Float
    
    
    init(inc:Float,times:Int?){
        self.inc = inc;
        super.init();

    }
    
    func incrementIndex(){
        index += 1;
        
    }
    
    func reset(){
        self.index = 0;
        self.incrementIndex();
    }
    
    override func get(id:String?) -> Float {
        let v = Float(self.index)*self.inc
        return v;
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
        #if DEBUG
            print("ease val: \(self.val,self.x,a,b,k)");
        #endif
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

//TODO: need to remove these eventually when system is refactored so that these are brush props, not generators
class Index:Generator{
    var val:Observable<Float>
    init (val:Observable<Float>){
        self.val = val;
    }
    override func get(id:String?) -> Float {
        return self.val.get(id: nil);
    }
}

class SiblingCount:Generator{
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
        let v =  sin(self.index.get(id: nil)*freq+phase)*amp/2+amp/2;
        self.incrementIndex();
        return v;
    }

    
}

class Triangle:Generator{
    var freq:Float
    var min:Float
    var max:Float
    
    var index = Observable<Float>(0);
    
    init(min:Float, max:Float, freq:Float){
        self.freq = freq;
        self.min = min;
        self.max = max;
    }
    
    func incrementIndex(){
        index.set(newValue: index.get(id: nil)+freq);
        
    }
    override func get(id:String?) -> Float {
        let ti = 2.0 * Float.pi * (880 / 44100);
        let theta = ti * self.index.get(id: nil)
        let _v = 1.0 - abs(Float(theta.truncatingRemainder(dividingBy: 4)-2));
        let v = MathUtil.map(value: _v, low1: -1, high1: 1, low2: min, high2: max)
        self.incrementIndex();
        #if DEBUG
            print("triangle wave val",v,index.get(id: nil))
        #endif
        return v;
    }
    
    
}

class Square:Generator{
    var freq:Float
    var min:Float
    var max:Float
    var currentVal:Float
    
    var index = Observable<Float>(0);
    
    init(min:Float, max:Float, freq:Float){
        self.freq = freq;
        self.min = min;
        self.max = max;
        self.currentVal = min;
    }
    
    func incrementIndex(){
        index.set(newValue: index.get(id: nil)+1);
        if(index.get(id: nil) > freq){
            index.set(newValue: 0.0)
        }
        
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
