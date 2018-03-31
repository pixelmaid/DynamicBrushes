//
//  Expression.swift
//  PaletteKnife
//
//  Created by JENNIFER MARY JACOBS on 7/22/16.
//  Copyright © 2016 pixelmaid. All rights reserved.
//

import Foundation

class Expression:Observable<Float>{
    var operandList:[String:Observable<Float>];
    var text:String;
    var id: String;
    var eventHandlers = [Disposable]();
    var brushIndex:Observable<Float>
    var subscriberId:String
    init(id:String,subscriberId:String,brushIndex:Observable<Float>,operandList:[String:Observable<Float>],text:String){
        self.id = id;
        self.text = text;
        self.operandList = operandList;
        self.brushIndex = brushIndex;
        self.subscriberId = subscriberId;
        super.init(0);
        var hasLive = false;
        for (_,value) in self.operandList{
            
            if(!hasLive){
                hasLive = value.isLive()
            }
            value.subscribe(id: self.id,brushId:subscriberId,brushIndex:brushIndex);
            let operandKey = NSUUID().uuidString;
            if(value.isLive() == true){
                let handler = value.didChange.addHandler(target: self, handler: Expression.setHandler,key:operandKey)
                eventHandlers.append(handler)

            }
        }
        self.setLiveStatus(status: hasLive);
    }
    
    override func get(id:String?) -> Float {
        invalidated = false;
    
        return calculateValue();
        
       
    }
    
    func calculateValue()->Float{
        var valueString = "";

        let stringArr = text.split{$0 == "%"}.map(String.init);
        var currentVals = [String: Float]();
        
        
        for (key,value) in self.operandList{
            
            currentVals[key] = value.get(id:subscriberId);
            
        }
        #if DEBUG
            //print("expression values",brushIndex.get(id:nil),currentVals);
        #endif
        
        for i in 0..<stringArr.count{
            let s = stringArr[i];
            if let val = currentVals[s] {
                valueString +=  "\(val)";
            }
            else{
                valueString += s;
            }
            
        }
        var result:Float = 0;
        let exception = tryBlock {
        let exp: NSExpression = NSExpression(format: valueString)
           result  = exp.expressionValue(with: nil, context: nil) as! Float// 25.0
        
        }
        #if DEBUG
            //print("exception: \(exception,result)")
        #endif

        return result;

    }
  
    func setHandler(data:(String,Float,Float),key:String){
        let result = self.calculateValue();
        self.set(newValue: result)
    }
    
    override func destroy(){
        for h in eventHandlers{
            h.dispose();
        }
        self.operandList.removeAll();
        super.destroy();
    }
    

}

//TODO: POPULATE DROPDOWN EXPRESSION CLASS
class DropdownExpression:Expression{
 
    func getSelectedId()->String{
        return "foo";
    }
    
}


    
    





