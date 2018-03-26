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
    
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var exportButton: UIButton!
    @IBOutlet weak var fileListButton: UIButton!
    
    @IBOutlet weak var colorPickerButton: UIButton!
    @IBOutlet weak var layerPanelButton: UIButton!
    @IBOutlet weak var behaviorPanelButton: UIButton!
    
    @IBOutlet weak var penButton: UIButton!
    @IBOutlet weak var eraseButton: UIButton!
    @IBOutlet weak var airbrushButton: UIButton!
    @IBOutlet weak var diameterSlider: UISlider!
    
    @IBOutlet weak var micButton: UIButton!
    @IBOutlet weak var alphaSlider: UISlider!
    
    @IBOutlet weak var backupLabel: UILabel!
    @IBOutlet weak var programViewToggle: UIButton!
    @IBOutlet weak var undoButton: UIButton!
    
    var toolEvent = Event<(String)>();
    var activePanel:String?
    var activeMode:String = "pen";
    var eraseActive:Bool = false;
    
    var micActive:Bool = false;

    var shapeLayer: CAShapeLayer?
    let eraseHighlight = UIImage(named: "erase_button_active2x")
    let eraseStandard = UIImage(named: "erase_button2x")
    
    let penHighlight = UIImage(named: "brush_button_active2x")
    let penStandard = UIImage(named: "brush_button2x")

    let airbrushHighlight = UIImage(named: "airbrush_button_active2x")
    let airbrushStandard = UIImage(named: "airbrush_button2x")

    let micOff = UIImage(named: "mic_off2x")
    let micOn = UIImage(named: "mic_on2x")

    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        backupLabel.isHidden = true
        toolEvent.raise(data: ("VIEW_LOADED"));
        
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: 20,y: 20), radius: CGFloat(12), startAngle: CGFloat(0), endAngle:CGFloat(Float.pi * 2), clockwise: true)
        
        shapeLayer = CAShapeLayer()
        shapeLayer?.path = circlePath.cgPath
        
        //change the fill color
        shapeLayer?.fillColor = UIColor.red.cgColor
        //you can change the stroke color
        shapeLayer?.strokeColor = UIColor(colorLiteralRed: 0.85, green: 0.85, blue: 0.85, alpha: 1).cgColor
        //you can change the line width
        shapeLayer?.lineWidth = 1.0

        colorPickerButton.layer.addSublayer(shapeLayer!)
          undoButton.addTarget(self, action: #selector(ToolbarViewController.undoToggled), for: .touchUpInside)
        eraseButton.addTarget(self, action: #selector(ToolbarViewController.eraseToggled), for: .touchUpInside)
        
        penButton.addTarget(self, action: #selector(ToolbarViewController.penToggled), for: .touchUpInside)
       
        airbrushButton.addTarget(self, action: #selector(ToolbarViewController.airbrushToggled), for: .touchUpInside)
        
        layerPanelButton.addTarget(self, action: #selector(ToolbarViewController.panelToggled), for: .touchUpInside)
         fileListButton.addTarget(self, action: #selector(ToolbarViewController.panelToggled), for: .touchUpInside)
        colorPickerButton.addTarget(self, action: #selector(ToolbarViewController.panelToggled), for: .touchUpInside)
        behaviorPanelButton.addTarget(self, action: #selector(ToolbarViewController.panelToggled), for: .touchUpInside)
        programViewToggle.addTarget(self, action: #selector(ToolbarViewController.panelToggled), for: .touchUpInside)

        micButton.addTarget(self, action: #selector(ToolbarViewController.micToggled), for: .touchUpInside)

        diameterSlider.addTarget(self, action: #selector(ToolbarViewController.diameterSliderChanged), for: .valueChanged)
          alphaSlider.addTarget(self, action: #selector(ToolbarViewController.alphaSliderChanged), for: .valueChanged)
        penToggled();
        
    }
    
    func setColor(color:UIColor){
        shapeLayer?.fillColor = color.cgColor;
    }
    
    func diameterSliderChanged(sender:UISlider!){
        toolEvent.raise(data:("DIAMETER_CHANGED"))
        
    }
    
    func alphaSliderChanged(sender:UISlider!){
        toolEvent.raise(data:("ALPHA_CHANGED"))
        
    }
    
    func disableSaveLoad(){
        saveButton.isEnabled = false;
        exportButton.isEnabled = false;
        fileListButton.isEnabled = false;
        backupLabel.isHidden = false;

        
    }
    
    func enableSaveLoad(){
        saveButton.isEnabled = true;
        exportButton.isEnabled = true;
        fileListButton.isEnabled = true;
        backupLabel.isHidden = true;

        
    }
    func panelToggled(sender: AnyObject){
        let target = (sender as! UIButton);
        if(target == layerPanelButton){
          toolEvent.raise(data: ("TOGGLE_LAYER_PANEL"));
        }
        else if(target == behaviorPanelButton){
            toolEvent.raise(data: ("TOGGLE_BEHAVIOR_PANEL"));
        }
        else if(target == colorPickerButton){
            toolEvent.raise(data: ("TOGGLE_COLOR_PANEL"));
        }
        else if(target == fileListButton){
            toolEvent.raise(data: ("TOGGLE_FILE_PANEL"));
        }
        else if(target == programViewToggle){
            toolEvent.raise(data: ("PROGRAMMING_VIEW_REQUEST"));
        }
    }
    
    func eraseToggled(){
        if(eraseActive){
            eraseButton.setImage(eraseStandard, for: UIControlState.normal)
            eraseActive = false;
        }
        else{
            eraseButton.setImage(eraseHighlight, for: UIControlState.normal)
            eraseActive = true;

        }
        
        toolEvent.raise(data: ("ERASE_MODE"));

        
        
    }
    
    func penToggled(){
       
            penButton.setImage(penHighlight, for: UIControlState.normal)
           airbrushButton.setImage(airbrushStandard, for: UIControlState.normal)

            activeMode = "pen"
            
            toolEvent.raise(data: ("PEN_MODE"));

            
        
        
        
        
    }
    
    func airbrushToggled(){
            penButton.setImage(penStandard, for: UIControlState.normal)
            airbrushButton.setImage(airbrushHighlight, for: UIControlState.normal)
            
            activeMode = "airbrush"
            
            toolEvent.raise(data: ("AIRBRUSH_MODE"));
            
            
        
    }
    
    func micToggled(){
        if !micActive {
            micButton.setImage(micOn, for: UIControlState.normal)
            print("@ mic turned on")
            micActive = true;
            toolEvent.raise(data: ("MIC_ON"));
        } else {
            micButton.setImage(micOff, for: UIControlState.normal)
            print("@ mic turned off")
            micActive = false;
            toolEvent.raise(data: ("MIC_OFF"));
        }
        
        
    }
    
    
    func undoToggled(){
  
        toolEvent.raise(data: ("UNDO"));
        
        
        
    }

}
