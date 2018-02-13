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
    
    override func viewDidLoad() {

        loopRecording.addTarget(self, action: #selector(RecordingViewController.loopInitialized), for: .touchUpInside)
    }
    

}
