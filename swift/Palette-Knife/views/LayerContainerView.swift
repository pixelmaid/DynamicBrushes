//
//  LayerContainerView.swift
//  DynamicBrushes
//
//  Created by JENNIFER MARY JACOBS on 5/18/17.
//  Copyright © 2017 pixelmaid. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON

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
    
    func save()->(JSON,[String:String]){
        var imageList = [String:String]();
        var drawingJSON:JSON = [:]
        var jsonLayerArray = [JSON]();
        for i in 0..<layers.count{
            var json:JSON = [:]
            let id = layers[i].id;
            json["id"] = JSON(id);
            let name = layers[i].name;
            json["name"] = JSON(name!);
            let isHidden = layers[i].isHidden;
            json["isHidden"] = JSON(isHidden);
            let isActive = (activeLayer == layers[i])
            json["isActive"] = JSON(isActive);
            
            let imageData = layers[i].exportPNG();
            if(imageData != nil){
                imageList[id] = imageData
                json["hasImageData"] = JSON(true)
            }
            else{
                 imageList[id] = "no_image";
                json["hasImageData"] = JSON(false)

            }
            jsonLayerArray.append(json)

            
        }
        drawingJSON["layers"] = JSON(jsonLayerArray);
        return(drawingJSON,imageList)
    }
    
    func loadFromData(fileData:JSON)->[(String,String,Bool,Bool)]{
        self.deleteAllLayers();
        print("fileData =",fileData);
        var jsonLayerArray = fileData["layers"].arrayValue;
        var newLayers = [(String,String,Bool,Bool)]()
        for i in 0..<jsonLayerArray.count{
            let layerData = jsonLayerArray[i];
            let id = layerData["id"].stringValue;
            let name = layerData["name"].stringValue;
            let isHidden = layerData["isHidden"].boolValue;
            let isActive = layerData["isActive"].boolValue;
            _ = self.newLayer(name: name, id: id);
            self.layers.last?.isHidden = isHidden;
            if(isActive){
                self.activeLayer = self.layers.last
            }
            
            newLayers.append((id,name,isActive,isHidden))

        }
        
        print("loaded layers=",self.layers)
        return newLayers
        
    }
    
    func loadImageIntoLayer(id:String, path:String){
        for l in layers{
            if l.id == id {
                l.loadImage(path:path);
            }
            
        }
    }
    
    func setDrawActive(val:Bool){
        drawActive = val
        self.activeLayer?.drawActive = drawActive;
    }
    
    
    func newLayer(name:String,id:String?)->String{
        let size = self.frame.size;
        activeLayer = ModifiedCanvasView(name:name,frame: CGRect(origin:CGPoint(x:0,y:0), size:size))
        activeLayer?.center = CGPoint(x:size.width/2,y:size.height / 2);
        self.layers.append(activeLayer!)
        self.addSubview(activeLayer!);
        activeLayer?.drawActive = self.drawActive;
        if(id != nil){
            activeLayer!.id = id!;
        }
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
    
    
    func deleteAllLayers(){
        for l in layers.reversed(){
            _ = self.deleteLayer(id: l.id)
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
