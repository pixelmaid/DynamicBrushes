//
//  RecordingToolbarVC.swift
//  DynamicBrushes
//
//  Created by Jingyi Li on 2/12/18.
//  Copyright © 2018 pixelmaid. All rights reserved.
//

import Foundation
import UIKit


class RecordingToolbarVC: UIViewController {
    let playbackSpeeds: [Float] = [0.1, 0.25, 0.5, 0.75, 1, 1.5, 2, 4, 10] //real playback speeds
    
    @IBOutlet weak var loopRecording: UIButton!
    @IBOutlet weak var playbackSpeed: UISlider!
    @IBOutlet weak var speedLabel: UILabel!
    
    public let loopEvent = Event<(String)>();

    override func viewDidLoad() {
        loopRecording.addTarget(self, action: #selector(RecordingToolbarVC.loop), for: .touchUpInside)
    }
    
  
    @IBAction func sliderChanged(_ sender: UISlider) {
        let val = Int(sender.value);
        let speed = playbackSpeeds[val];
        sender.setValue(Float(val), animated: false)
        print("^^ playback speed set to ", speed)
        speedLabel.text = "\(speed)x"
        
        //TODO hook this up to the playback speed now

    }
    
    func loop() {
        print("inside toolbar loop ^^")
        loopEvent.raise(data: ("LOOP"));
    }
    

}
