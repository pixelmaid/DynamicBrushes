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
    internal let _time:Observable<Float>
    
    override init(){
        
        //==BEGIN OBSERVABLES==//
        self._time = Observable<Float>(0)
        _time.name = "time";

        //==END OBSERVABLES==//

        
        timer = NSDate()
        super.init()
        
        //==BEGIN APPEND OBSERVABLES==//
        observables.append(_time);
        //==END APPEND OBSERVABLES==//

        self.events =  ["TIME_INTERVAL"]
        self.createKeyStorage();
        
        
    }
    
    func getTimeElapsed()->Float{
        let currentTime = NSDate();
        let t = currentTime.timeIntervalSince(timer as Date)
        return Float(t);
    }
    
    func startInterval(){
        #if DEBUG
            print("start interval")
        #endif
        intervalTimer  = Timer.scheduledTimer(timeInterval: 0.0001, target: self, selector: #selector(TimeSeries.timerIntervalCallback), userInfo: nil, repeats: true)
        
        
        
    }
    
    func stopInterval(){
        #if DEBUG
            print("stop interval")
        #endif

        if(intervalTimer != nil){
            #if DEBUG
                print("invalidate timer")
            #endif
         intervalTimer.invalidate();
        }
        
    }

    
    override func destroy(){
        self.stopInterval();
        super.destroy();
    }
    
    @objc func timerIntervalCallback()
    {
        
        let currentTime = NSDate();
        //TODO: Fix how this is calucated to deal with lag..
        let t = Float(currentTime.timeIntervalSince(timer as Date))
        self._time.set(newValue: t)
        for key in keyStorage["TIME_INTERVAL"]!
        {
 
            if(key.1 != nil){
                let condition = key.1;
                let evaluation = condition?.evaluate();
                if(evaluation == true){
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: key.0), object: self, userInfo: ["emitter":self,"key":key.2.id,"event":"TIME_INTERVAL"])
                }
            }
            else{
                
               NotificationCenter.default.post(name: NSNotification.Name(rawValue: key.0), object: self, userInfo: ["emitter":self,"key":key.2.id,"event":"TIME_INTERVAL"])
            }
            
            
            
        }
        
        
    }
    
    
    
}


