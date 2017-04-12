//
//  TimeSeries.swift
//  PaletteKnife
//
//  Created by JENNIFER MARY JACOBS on 6/28/16.
//  Copyright © 2016 pixelmaid. All rights reserved.
//

import Foundation

class TimeSeries: Emitter{
    
    var timer:NSDate!
    var intervalTimer:Timer!
    //TODO: this is duplication to facilitate KVC- should be removed/fixed
    var timerTime = Observable<Float>(0);
    
    override init(){
        timer = NSDate()

        super.init()
        self.events =  ["TICK"]
        self.createKeyStorage();
        timerTime.name = "time";
        
        
    }
    
    func getTimeElapsed()->Float{
        let currentTime = NSDate();
        let t = currentTime.timeIntervalSince(timer as Date)
        return Float(t);
    }
    
    func startInterval(){
       // if(intervalTimer == nil){
        intervalTimer  = Timer.scheduledTimer(timeInterval: 0.0001, target: self, selector: #selector(TimeSeries.timerIntervalCallback), userInfo: nil, repeats: true)
        //}
        
        
    }
    
    func stopInterval(){
         intervalTimer.invalidate();
        
    }

    
    override func destroy(){
        self.stopInterval();
        super.destroy();
    }
    
    @objc func timerIntervalCallback()
    {
        let currentTime = NSDate();
        let t = Float(currentTime.timeIntervalSince(timer as Date))
        self.timerTime.set(newValue: t)
        for key in keyStorage["TICK"]!
        {
            
            if(key.1 != nil){
                let condition = key.1;
                let evaluation = condition?.evaluate();
                if(evaluation)!{
                    
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: key.0), object: self, userInfo: ["emitter":self,"key":key.0,"event":"TICK"])
                }
            }
            else{
                
               NotificationCenter.default.post(name: NSNotification.Name(rawValue: key.0), object: self, userInfo: ["emitter":self,"key":key.0,"event":"TICK"])
            }
            
            
            
        }
        
        
    }
    
    
    
}
