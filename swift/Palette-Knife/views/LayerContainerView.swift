//
//  LayerContainerView.swift
//  DynamicBrushes
//
//  Created by JENNIFER MARY JACOBS on 5/18/17.
//  Copyright © 2017 pixelmaid. All rights reserved.
//

import Foundation
import UIKit


class LayerContainerView: UIView{
    
    var activeLayer:ModifiedCanvasView?
    var layers = [ModifiedCanvasView]();
    
    
    init(width:Float,height:Float){
        let frame = CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height))
        super.init(frame: frame);
        self.backgroundColor = UIColor.white;
    }
    
    required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
    
    }
    
    func save(){
    
    }
    
    func loadFromData(){
    
    }
    
    func newLayer(){
            let screenSize = self.bounds
            let origin = self.frame.origin
            activeLayer = ModifiedCanvasView(frame: CGRect(x:origin.x, y:origin.y, width:screenSize.width, height:screenSize.height))
            self.layers.append(activeLayer!)
           self.addSubview(activeLayer!);
        
        
    }
    
    func eraseCurrentLayer(){
        if(activeLayer != nil){
            activeLayer!.erase();
        }
    }
    
    func drawIntoCurrentLayer(currentCanvas:Canvas){
        if(self.activeLayer != nil ){
            let context = self.activeLayer?.pushContext();
            currentCanvas.drawSegment(context:context!)
            self.activeLayer?.popContext();
        }

    }
    
    
}
