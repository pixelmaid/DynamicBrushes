//
//  InspectorViewController.swift
//  DynamicBrushes
//
//  Created by Jingyi Li on 9/5/19.
//  Copyright © 2019 pixelmaid. All rights reserved.
//

import Foundation

import UIKit
import SwiftyJSON


class InspectorViewController: UIViewController {

    
    
    //switches
    
    @IBOutlet weak var inputGfx: UISwitch!
    @IBOutlet weak var inputLabel: UISwitch!
    @IBOutlet weak var brushGfx: UISwitch!
    @IBOutlet weak var brushLabel: UISwitch!
    @IBOutlet weak var outputGfx: UISwitch!
    @IBOutlet weak var outputLabel: UISwitch!
    
    var switchEvent = Event<(String,String,Bool)>();

    
    override func viewDidLoad() {
        super.viewDidLoad()
        inputGfx.addTarget(self, action: #selector(InspectorViewController.gfxChanged), for: UIControl.Event.valueChanged)
        brushGfx.addTarget(self, action: #selector(InspectorViewController.gfxChanged), for: UIControl.Event.valueChanged)
        outputGfx.addTarget(self, action: #selector(InspectorViewController.gfxChanged), for: UIControl.Event.valueChanged)

        inputLabel.addTarget(self, action: #selector(InspectorViewController.labelChanged), for: UIControl.Event.valueChanged)
        brushLabel.addTarget(self, action: #selector(InspectorViewController.labelChanged), for: UIControl.Event.valueChanged)
        outputLabel.addTarget(self, action: #selector(InspectorViewController.labelChanged), for: UIControl.Event.valueChanged)

    }
    
    @objc func gfxChanged(sender: AnyObject){
        let target = (sender as! UISwitch);
        if(target == inputGfx){
            self.switchEvent.raise(data: ("gfx","input",target.isOn));
        }
        else if(target == brushGfx){
            self.switchEvent.raise(data: ("gfx","brush",target.isOn));
        }
        else if(target == outputGfx){
            self.switchEvent.raise(data: ("gfx","output",target.isOn));

        }
    }
    
    @objc func labelChanged(sender: AnyObject){
        let target = (sender as! UISwitch);
        if(target == inputLabel){
            self.switchEvent.raise(data: ("label","input",target.isOn));
        }
        else if(target == brushLabel){
            self.switchEvent.raise(data: ("label","brush",target.isOn));
        }
        else if(target == outputLabel){
            self.switchEvent.raise(data: ("label","output",target.isOn));
        }
    }
}

