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
    var drawActive = true;
    
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
    
    func setDrawActive(val:Bool){
        drawActive = val
        self.activeLayer?.drawActive = drawActive;
    }
    
    
    func newLayer()->String{
        let screenSize = self.bounds
        let size = self.frame.size;
        activeLayer = ModifiedCanvasView(frame: CGRect(origin:CGPoint(x:0,y:0), size:size))
        activeLayer?.center = CGPoint(x:size.width/2,y:size.height / 2);
            self.layers.append(activeLayer!)
           self.addSubview(activeLayer!);
        activeLayer?.drawActive = self.drawActive;
        return activeLayer!.id
        
    }
    
    func setActiveLayer(id:String){
        for l in layers{
            if l.id == id {
                self.activeLayer = l;
                 activeLayer?.drawActive = self.drawActive;
                return;
            }
        }
    }
    
    func showLayer(id:String){
        for l in layers{
            if l.id == id {
                l.isHidden = false;
                return;
            }
        }
    }
    
    func hideLayer(id:String){
        for l in layers{
            if l.id == id {
                l.isHidden = true;
                return;
            }
        }
    }
    
    
    func deleteLayer(id:String)->String?{
        var toRemove:ModifiedCanvasView? = nil;
        var targetIndex:Int? = nil
        for i in 0..<layers.count{
            print("checking layer ",i,layers[i].id,id)
            if layers[i].id == id {
                toRemove = layers[i];
                targetIndex = i;
                layers.remove(at: i)
                break
            }
        }
        if(toRemove != nil){
        toRemove?.removeFromSuperview();
                
        if(toRemove == activeLayer){
            if layers.count>0{
                if targetIndex == 0 {
                    activeLayer = layers[0]
                    }
                else{
                    activeLayer = layers[targetIndex! - 1]
                }
                
                return activeLayer?.id;
   
            }
        }
        }
        return nil
    }
    
    func eraseCurrentLayer(){
        if(activeLayer != nil){
            activeLayer!.eraseAll();
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
