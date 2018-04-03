//
//  Expression.swift
//  PaletteKnife
//
//  Created by JENNIFER MARY JACOBS on 7/22/16.
//  Copyright © 2016 pixelmaid. All rights reserved.
//

import Foundation

class Expression:Observable<Float>{
    var observableList:[String:Observable<Float>];
    var text:String;
    var id: String;
    var eventHandlers = [Disposable]();
    let brushId:String;
    let behaviorId:String;
    static let within:String = "|";
    init(id:String,brushId:String,behaviorId:String,operandList:[String:Observable<Float>],text:String){
        self.id = id;
        self.text = text;
        self.observableList = operandList;
        self.brushId = brushId;
        self.behaviorId = behaviorId;
        super.init(0);
        var hasLive = false;
        for (_,value) in self.observableList{
            
            if(!hasLive){
                hasLive = value.isLive()
            }
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
    
        guard let v = calculateValue() else{
            return 0;
        }
        return v;
        
       
    }
    
    func calculateValue()->Float?{
        var valueString = "";
        if(text.isEmpty){
            print("==========WARNING, NO TEXT IN EXPRESSION TEXT FIELD================",self.id);
            
            return nil
        }
        let stringArr = text.split{$0 == "%"}.map(String.init);
        var currentVals = [String: Float]();
      
        
        for (key,value) in self.observableList{
            (value as! Signal).setBehaviorId(id: self.behaviorId);
            currentVals[key] = value.get(id:brushId);
            
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
        if(valueString.isEmpty){
            print("==========WARNING, NO TEXT IN EXPRESSION================",self.id);

            return nil
        }
       
        var targetValue:Float = 0;
        ExpressionCatch.try({ () -> Void in
            let expr = NSExpression(format: valueString)
            
            if let result = expr.expressionValue(with: nil, context: nil) as? Float {
                #if DEBUG
                    
                    // print("expression success",result)
                #endif
                targetValue = result;
                
            } else {
                #if DEBUG
                    
                    print("==========ERROR EXPRESSION FAILED================",self.id);
                #endif
                
                
            }
        }, catch: { (exception) -> Void in
            
            print("==========ERROR EXPRESSION INTERPRETATION FAILED================",self.id);
        }) { () -> Void in
            //close resources
        }
        
      
    
        
        return targetValue;


    }
  
    func setHandler(data:(String,Float,Float),key:String){
        let result = self.calculateValue();
        if(result != nil){
            self.set(newValue: result!)
        }
    }
    
    override func destroy(){
        for h in eventHandlers{
            h.dispose();
        }
        for (key,value) in self.observableList{
            value.removeRegisteredBrush(id:self.brushId);
        }
        self.observableList.removeAll();
        super.destroy();
    }
    
    
    static func parseForSignalAccessors(expressionString:String,observables:[String:Observable<Float>])->(newString:String,newObservables:[String:Observable<Float>]){
        var newObservables = [String:Observable<Float>]();
        var newString = "";
        var stringArr = expressionString.split{$0 == "%"}.map(String.init);
        var stringAnalysis = [String]();
        while stringArr.count > 0{
            let s = stringArr.removeFirst();
            if observables[s] != nil {
                stringAnalysis.append(s);
                if(stringAnalysis.count == 3){
                    let oId1 = stringAnalysis[0];
                    let oId2 = stringAnalysis[1];
                    let oId3 = stringAnalysis[2];
                    
                    let o1 = observables[oId1]!;
                    let o2 = observables[oId2]!;
                    let o3 = observables[oId3]!;
                    
                    if(o2.isSignalAccessor() && !o1.isSignalAccessor() && !o3.isSignalAccessor()){
                        (o2 as! SignalAccessor).setReferences(a:o1 as! Signal,b:o3 as! Signal)
                        newObservables[oId2] = o2;
                        newString.append("%"+oId2+"%");
                        stringAnalysis.removeAll();

                    }
                    else if(stringArr.count>0){
                        newString.append("%"+oId1+"%")
                         newObservables[oId1] = o1;
                        stringAnalysis.removeFirst();
                    }
                    else{
                        newString.append("%"+oId1+"%")
                        newObservables[oId1] = o1;
                        stringAnalysis.removeFirst();
                        
                        newString.append("%"+oId2+"%")
                        newObservables[oId2] = o2;
                        stringAnalysis.removeFirst();
                        break;
                    }
                }
                else if(stringArr.count == 0){
                    for j in 0..<stringAnalysis.count{
                        newString.append("%"+stringAnalysis[j]+"%")
                        newObservables[stringAnalysis[j]] = observables[stringAnalysis[j]]!
                    }
                    stringAnalysis.removeAll();
                    break;
                }
                
            }
            else{
                if(stringArr.count == 0){
                    for j in 0..<stringAnalysis.count{
                        newString.append("%"+stringAnalysis[j]+"%")
                        newObservables[stringAnalysis[j]] = observables[stringAnalysis[j]]!
                    }
                    stringAnalysis.removeAll();
                }
                newString.append(s);
            }
        }
        
        return (newString:newString,newObservables:newObservables);
    }

}

//TODO: POPULATE DROPDOWN EXPRESSION CLASS
class DropdownExpression:Expression{
 
    func getSelectedId()->String{
        return self.text;
    }
    
}


    
    





