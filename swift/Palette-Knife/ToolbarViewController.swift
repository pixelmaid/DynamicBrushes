//
//  ToolbarViewController.swift
//  DynamicBrushes
//
//  Created by JENNIFER MARY JACOBS on 5/18/17.
//  Copyright © 2017 pixelmaid. All rights reserved.
//

import Foundation
import UIKit

class ToolbarViewController: UIViewController {
    @IBOutlet weak var addLayerButton: UIButton!
    @IBOutlet weak var eraseButton: UIButton!
    @IBOutlet weak var exportButton: UIButton!
    
    var toolEvent = Event<(String)>();
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        print("toolbar controller button after view load",self.eraseButton);
        
        toolEvent.raise(data: ("VIEW_LOADED"));

    }

}
