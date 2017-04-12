//
//  Expression.swift
//  PaletteKnife
//
//  Created by JENNIFER MARY JACOBS on 7/22/16.
//  Copyright © 2016 pixelmaid. All rights reserved.
//

import Foundation


class Expression: Observable<Float>{
    var operand1:Observable<Float>
    var operand2:Observable<Float>
    var operand1Key = NSUUID().uuidString;
    var operand2Key = NSUUID().uuidString;
    var id = NSUUID().uuidString;
    
   required init(operand1:Observable<Float>,operand2:Observable<Float>){
        self.operand1 = operand1;
        self.operand2 = operand2;
        super.init(0)
        
        
      //  operand1.didChange.addHandler(self, handler: Expression.setHandler,key:operand1Key)
       // operand2.didChange.addHandler(self, handler: Expression.setHandler, key:operand2Key)
        operand1.subscribe(id: self.id);
        operand2.subscribe(id: self.id);

        //initial set after intialize
        //TODO: check if this causes errors...
        self.setHandler(data: (name,0,0),key:"_")

    }
    
    
    
   //placeholder sethandler does nothing
    func setHandler(data:(String,Float,Float),key:String){
       
    }

    
    
}

class TextExpression:Observable<Float>{
    var operandList:[String:Observable<Float>];
    var text:String;
    var id: String;

    init(id:String,operandList:[String:Observable<Float>],text:String){
        self.id = id;
        self.text = text;
        self.operandList = operandList;
        super.init(0);

        for (key,value) in self.operandList{
            print("subscribing to \(key,value)");
           value.subscribe(id: self.id);
            let operandKey = NSUUID().uuidString;
           value.didChange.addHandler(target: self, handler: TextExpression.setHandler,key:operandKey)
        }
        
    }
    
    override func get(id:String?) -> Float {
        invalidated = false;
        if(isPassive){
            return calculateValue();
        }
        return super.get(id:id);
    }
    
    func calculateValue()->Float{
        var valueString = "";

        let stringArr = text.characters.split{$0 == "%"}.map(String.init);
        print ("stringArr =\(stringArr,self.operandList)");
        //xprint(NSThread.callStackSymbols())

        var currentVals = [String: Float]();
        
        
        for (key,value) in self.operandList{
            currentVals[key] = value.get(id:self.id);
            print("operand value at = \(key, currentVals[key])");
            
        }
        
        for i in 0..<stringArr.count{
            let s = stringArr[i];
            if let val = currentVals[s] {
                valueString +=  "\(val)";
            }
            else{
                valueString += s;
            }
            
        }
        print("text expression string to evaluate = \(valueString)");
        var result:Float = 0;
        let exception = tryBlock {
        let exp: NSExpression = NSExpression(format: valueString)
           result  = exp.expressionValue(with: nil, context: nil) as! Float// 25.0
        
        print("result of text expression = \(result)");
        }
        print("exception: \(exception)")

        return result;

    }
  
    func setHandler(data:(String,Float,Float),key:String){
        let result = self.calculateValue();
        self.set(newValue: result)
    }
    

}


class AddExpression:Expression{
    
    override func setHandler(data:(String,Float,Float),key:String){
       self.set(newValue: operand1.get(id:nil) + operand2.get(id:nil))
    }
    
}

class SubExpression:Expression{
    
    override func setHandler(data:(String,Float,Float),key:String){
    
        self.set(newValue: operand1.get(id:nil) - operand2.get(id:nil))
    }
    
}

class MultExpression:Expression{
    
    override func setHandler(data:(String,Float,Float),key:String){
        let a = operand1.get(id:self.id);
        let b = operand2.get(id:self.id);
        let c = a*b
        self.set(newValue: c)
    }
    
    //TODO: need to fix this- expressions should either be push or pull but not both...
    override func get(id:String?)->Float{
        let a = operand1.get(id:self.id);
        let b = operand2.get(id:self.id);
        let c = a*b
        return c;
    }
    
    
    
 
}

class LogExpression:Expression{
    
    override func setHandler(data:(String,Float,Float),key:String){
     self.set(newValue: log(operand1.get(id:nil)+1)/20 + operand2.get(id:nil));
    }
    
}

class ExpExpression:Expression{
    
    override func setHandler(data:(String,Float,Float),key:String){
        self.set(newValue: pow(operand1.get(id:nil),2)/10 + operand2.get(id:nil));
    }
    
}

class LogiGrowthExpression:Expression{
    
    override func setHandler(data:(String,Float,Float),key:String){
        let a = Float(3);
        let b = Float(10000);
        let k = Float(-3.8);
        let x = operand1.get(id:nil)
        let val = a/(1+b*pow(2.7182818284590451,x*k))
        self.set(newValue: val + operand2.get(id:nil));
    }
    
    
    
}




