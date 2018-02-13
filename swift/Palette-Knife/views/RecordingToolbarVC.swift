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
    @IBOutlet weak var loopRecording: UIButton!
    
    public let loopEvent = Event<(String)>();

    override func viewDidLoad() {
        loopRecording.addTarget(self, action: #selector(RecordingToolbarVC.loop), for: .touchUpInside)
    }
    
    
    func loop() {
        print("inside toolbar loop ^^")
        loopEvent.raise(data: ("LOOP"));
    }
    

}
