//
//  MapFunctions.swift
//  DynamicBrushes
//
//  Created by JENNIFER MARY JACOBS on 11/14/17.
//  Copyright © 2017 pixelmaid. All rights reserved.
//

import Foundation


class Mapper:Observable<Float>{
    let low1:Float;
    let low2:Float;
    let high1:Float;
    let high2:Float;
    var input:Observable<Float>
    
    init(input:Observable<Float>,low1:Float,high1:Float,low2:Float,high2:Float){
        
        self.input = input
        self.low1 = low1
        self.low2 = low2
        self.high1 = high1
        self.high2 = high2
        super.init(0)

    }
    
    override func get(id:String?)->Float{
        let inputVal = self.input.get(id: id);

        let val = MathUtil.map(value: inputVal, low1: self.low1, high1: self.high1, low2: self.low2, high2: self.high2)
        #if DEBUG
            print("mapping results",inputVal,self.high1,self.high2,val);
       #endif
        return val;
    }
    
    
    
    
}

class CanvasYPositionMapper:Mapper{
    
    init(input:Observable<Float>,low:Float,high:Float){
        let low2 = Float(0)
        let high2 = Float(1366)
        super.init(input: input,low1:low,high1:high,low2:low2,high2:high2);
    }
    
}

class CanvasXPositionMapper:Mapper{
    
    init(input:Observable<Float>,low:Float,high:Float){
        let low2 = Float(0)
        let high2 = Float(1024)
        super.init(input: input,low1:low,high1:high,low2:low2,high2:high2);
    }
    
}
