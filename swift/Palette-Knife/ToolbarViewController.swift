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
    
    @IBOutlet weak var eraseButton: UIButton!
    @IBOutlet weak var brushButton: UIButton!
    
    @IBOutlet weak var diameterSlider: UISlider!
    
    @IBOutlet weak var alphaSlider: UISlider!
    
    
    var toolEvent = Event<(String)>();
    var activePanel:String?
    var activeMode:String = "erase";
    var shapeLayer: CAShapeLayer?
    let eraseHighlight = UIImage(named: "erase_button_active2x")
    let eraseStandard = UIImage(named: "erase_button2x")
    
    let brushHighlight = UIImage(named: "brush_button_active2x")
    let brushStandard = UIImage(named: "brush_button2x")


    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        behaviorPanelButton.isHidden = true;
        toolEvent.raise(data: ("VIEW_LOADED"));
        
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: 20,y: 20), radius: CGFloat(12), startAngle: CGFloat(0), endAngle:CGFloat(M_PI * 2), clockwise: true)
        
        shapeLayer = CAShapeLayer()
        shapeLayer?.path = circlePath.cgPath
        
        //change the fill color
        shapeLayer?.fillColor = UIColor.red.cgColor
        //you can change the stroke color
        shapeLayer?.strokeColor = UIColor(colorLiteralRed: 0.85, green: 0.85, blue: 0.85, alpha: 1).cgColor
        //you can change the line width
        shapeLayer?.lineWidth = 1.0

        colorPickerButton.layer.addSublayer(shapeLayer!)
        
        eraseButton.addTarget(self, action: #selector(ToolbarViewController.eraseToggled), for: .touchUpInside)
        
        brushButton.addTarget(self, action: #selector(ToolbarViewController.brushToggled), for: .touchUpInside)
        
        layerPanelButton.addTarget(self, action: #selector(ToolbarViewController.panelToggled), for: .touchUpInside)
         fileListButton.addTarget(self, action: #selector(ToolbarViewController.panelToggled), for: .touchUpInside)
        colorPickerButton.addTarget(self, action: #selector(ToolbarViewController.panelToggled), for: .touchUpInside)
        behaviorPanelButton.addTarget(self, action: #selector(ToolbarViewController.panelToggled), for: .touchUpInside)

        diameterSlider.addTarget(self, action: #selector(ToolbarViewController.diameterSliderChanged), for: .valueChanged)
          alphaSlider.addTarget(self, action: #selector(ToolbarViewController.alphaSliderChanged), for: .valueChanged)
        
        brushToggled();
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
    }
    
    func eraseToggled(){
        if activeMode == "brush"{
            eraseButton.setImage(eraseHighlight, for: UIControlState.normal)
            brushButton.setImage(brushStandard, for: UIControlState.normal)
            activeMode = "erase"
            toolEvent.raise(data: ("ERASE_MODE"));

        }
        
    }
    
    func brushToggled(){
        if activeMode == "erase"{
            eraseButton.setImage(eraseStandard, for: UIControlState.normal)
            brushButton.setImage(brushHighlight, for: UIControlState.normal)
            activeMode = "brush"
            
            toolEvent.raise(data: ("BRUSH_MODE"));

            
        }
        
    }

}
