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
    let recordImgEventKey = NSUUID().uuidString

    @IBOutlet weak var exportButton: UIButton!
    @IBOutlet weak var loopRecording: UIButton!
    @IBOutlet weak var playbackSpeed: UISlider!
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var recordImg: UIImageView!
    var isLooping = false
    
    public let loopEvent = Event<(String)>();

    override func viewDidLoad() {
        loopRecording.addTarget(self, action: #selector(RecordingToolbarVC.loop), for: .touchUpInside)
        exportButton.addTarget(self, action: #selector(RecordingToolbarVC.showExportDialog), for: .touchUpInside)

        _ = StylusManager.visualizationEvent.addHandler(target: self, handler: RecordingToolbarVC.recordImgOn, key: recordImgEventKey)

    }
    
    func recordImgOn(data:String, key:String){
        if data == "RECORD_IMG_ON" {
            recordImg.image = UIImage(named: "record_on2x") //set when full loop finishes
        }
    }
   
    @IBAction func sliderChanged(_ sender: UISlider) {
        let val = Int(sender.value);
        let speed = playbackSpeeds[val];
        sender.setValue(Float(val), animated: false)
        print("^^ playback speed set to ", speed)
        speedLabel.text = "\(speed)x"
        
        //TODO hook this up to the playback speed now
        StylusManager.setPlaybackRate(v: speed);

    }
    
    
    func loop() {
        if (!isLooping) {
            loopRecording.setImage(UIImage(named: "loop_button_on2x"), for: .normal)
            recordImg.image = UIImage(named: "record_off2x")
            isLooping = true
        } else {
            loopRecording.setImage(UIImage(named: "loop_button_off2x"), for: .normal)
            isLooping = false
            
        }
        loopEvent.raise(data: ("LOOP"));
    }
    
    func showExportDialog() {
        //Creating UIAlertController and
        //Setting title and message for the alert dialog
        let alertController = UIAlertController(title: "Export Recording", message: "Name your recording", preferredStyle: .alert)
        
        //the confirm action taking the inputs
        let confirmAction = UIAlertAction(title: "Confirm", style: .default) { (_) in
              //getting the input values from user
            let name = alertController.textFields?[0].text
            //now actually export it
        }
        
        //the cancel action doing nothing
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        
        //adding textfields to our dialog box
        alertController.addTextField { (textField) in
            textField.placeholder = "Enter Name"
        }
        
        //adding the action to dialogbox
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        //finally presenting the dialog box
        self.present(alertController, animated: true, completion: nil)
    }
    

}
