//
//  RecordingToolbarVC.swift
//  DynamicBrushes
//
//  Created by Jingyi Li on 2/12/18.
//  Copyright © 2018 pixelmaid. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON

class GestureRecording {
    var id:String;
    var x:Recording;
    var y:Recording;
    
    init(id:String,x:Recording,y:Recording) {
        self.id = id;
        self.x = x;
        self.y = y;
    }
}


class RecordingToolbarVC: UIViewController, Requester {
  
    
    let recordImgEventKey = NSUUID().uuidString

    @IBOutlet weak var exportButton: UIButton!
    @IBOutlet weak var loopRecording: UIButton!
    @IBOutlet weak var playbackSpeed: UISlider!
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var recordImg: UIImageView!
    var isLooping = false
    
    public let loopEvent = Event<(String)>();
    public var gestures = [GestureRecording]()
    public var recording_start = 0
    public var recording_end = 0;
    var firstLoopCompleted = false
    
    var isRecordingLoop = false
    override func viewDidLoad() {
        super.viewDidLoad()

        loopRecording.addTarget(self, action: #selector(RecordingToolbarVC.loop), for: .touchUpInside)
       
        let recordingKey = NSUUID().uuidString

        _ = stylusManager.recordEvent.addHandler(target:self, handler: RecordingToolbarVC.recordingCreatedHandler, key: recordingKey)

        

    }
    
   
   
    @IBAction func sliderChanged(_ sender: UISlider) {
        let val = Int(sender.value);
        let speed =  Float(val)/100;// playbackSpeeds[val];
        sender.setValue(Float(val), animated: false)
        print("^^ playback speed set to ", speed)
        speedLabel.text = "\(speed)x"
        
        //TODO hook this up to the playback speed now
        stylusManager.setPlaybackRate(v: speed);

    }
    
    
    @objc func loop() {
        if(stylusManager.recordingAvailable()){
        if (!isLooping) {
            loopRecording.setImage(UIImage(named: "loop_button_on2x"), for: .normal)
//            recordImg.image = UIImage(named: "record_off2x")
            isLooping = true
        } else {
            loopRecording.setImage(UIImage(named: "loop_button_off2x"), for: .normal)
            isLooping = false
        }
        
        self.loopInitialized();
        }
    }
    
   
    
    //requester stubs
    func processRequest(data: (String, JSON?)) {
       
    }
    
    func processRequestHandler(data: (String, JSON?), key: String) {
        self.processRequest(data:data)

    }
    
    func disable(){
        playbackSpeed.isEnabled = false;
        loopRecording.isEnabled = false;
    }
    
    func enable(){
        playbackSpeed.isEnabled = true;
        loopRecording.isEnabled = true;
    }
    
    //Mark: Recording Event handlers
    
    //from an index, go to a gesture stringid
     func getGestureId(index:Int) -> String {
        return gestures[index].id
    }
    
    func loopInitialized() {
        if (self.recording_start >= 0 && self.recording_end >= self.recording_start) {
            let start_id:String;
            let end_id:String;
           if(self.gestures.count>1){
                start_id = self.getGestureId(index: self.gestures.count-2);

                 end_id = self.getGestureId(index: self.gestures.count-1);
            }
            else{
                start_id = self.getGestureId(index: self.gestures.count-1);
                
                end_id = self.getGestureId(index: self.gestures.count-1);
            }
            if (stylusManager.liveStatus()) {
                isRecordingLoop = true
                stylusManager.prepareDataToLoop(idStart: start_id, idEnd: end_id, startTimer: true);
                //erase strokes associated with the recording
                //                stylusManager.eraseStrokesForLooping(idStart:start_id, idEnd:end_id)
                
            } else { //stop recording
                
                stylusManager.terminateLoopAndResumeLive()
                //stylusManager.setToLive()
                firstLoopCompleted = true
            }
        }
    }
    
    func recordingCreatedHandler (data:(String, RecordingCollection), key:String) {
        let stylusData = data.1
        let xRecording = stylusData.protoSignals["x"];
        let yRecording = stylusData.protoSignals["y"];
        self.gestures.append(GestureRecording(id: stylusData.id, x:xRecording as! Recording, y:yRecording as! Recording))
        let IndexPath = NSIndexPath(item: self.gestures.count-1, section:0)
    }

}
