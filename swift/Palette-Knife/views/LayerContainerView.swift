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

class LayerContainerView: UIView {
    
    var activeLayer:ModifiedCanvasView?
    var layers = [ModifiedCanvasView]();
    var drawActive = true;
    let exportKey = NSUUID().uuidString;
    let exportEvent = Event<(String,Data?)>()
    var exportHandlers = [Disposable]();
    var exportedImages = [UIImage]();
    var exportTarget = 0;
    init(width:Float,height:Float){
        let frame = CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height))
        super.init(frame: frame);
        self.backgroundColor = UIColor.white;
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
    }
    
    func exportPNG(){
        exportedImages.removeAll();
        exportTarget = layers.filter({ $0.isHidden == false }).count
        #if DEBUG
            print("export target =",exportTarget)
        #endif
        for l in layers{
            if l.isHidden == false{
               let handler = l.exportEvent.addHandler(target: self, handler: LayerContainerView.exportHandler, key: exportKey)
                exportHandlers.append(handler);
                l.exportUIImage();
            }
        }
      /*  UIGraphicsBeginImageContext(self.bounds.size);
        self.layer.render(in: UIGraphicsGetCurrentContext()!);
        let viewImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        let contentToShare = UIImagePNGRepresentation(viewImage!)
        return contentToShare;*/
    }
    
    func exportHandler(data:(String,UIImage?),key:String){
        if(data.0 == "COMPLETE" && data.1 != nil){
            #if DEBUG
            print("export complete",data.1,data.1?.size)
            #endif
            exportedImages.append(data.1!);
        }
        
        if(exportedImages.count == exportTarget){
            let masterImage = UIView(frame: self.frame);
            
            for i in exportedImages{
                let img = i
                masterImage.addSubview(UIImageView(image:img));
            }
            UIGraphicsBeginImageContext(masterImage.bounds.size);
            masterImage.layer.render(in: UIGraphicsGetCurrentContext()!);
            let viewImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            let contentToShare = UIImagePNGRepresentation(viewImage!)
            #if DEBUG
                print("export compilation complete",contentToShare,viewImage!.size)
                print("export images count",exportedImages.count)
            #endif
            for d in self.exportHandlers{
                d.dispose();
            }
            exportedImages.removeAll();
            self.exportEvent.raise(data:("COMPLETE",contentToShare));
            
        }
        
        
        
    }
    
    func exportPNGAsFile()->String?{
      /*  let fileManager = FileManager.default
       let path = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent("\"layer_container.png")
            let imageData = self.exportPNG()
        if(imageData != nil){
            fileManager.createFile(atPath: path as String, contents: imageData, attributes: nil)
            return path;
        }
        return nil*/
        return nil
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
            
            let imageData = layers[i].exportPNGAsFile();
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
        //self.activeLayer?.eraseAll();
    }
    
    
    func newLayer(name:String,id:String?)->String{
        let size = self.frame.size;
        let layer = ModifiedCanvasView(name:name,frame: CGRect(origin:CGPoint(x:0,y:0), size:size))
       layer.center = CGPoint(x:size.width/2,y:size.height / 2);
        self.layers.append(layer)
        self.addSubview(layer);
        if(id != nil){
            layer.id = id!;
        }
        self.enableLayer(layer: layer)
        return layer.id
        
    }
    
    func addStroke(id:String){
        if(self.activeLayer != nil){
            self.activeLayer?.beginStroke(id: id)
        }
    }
    
    func removeStroke(idList:[String]){
        if(self.activeLayer != nil){
            self.activeLayer?.endStrokes(idList:idList)
        }
    }
    
    func selectActiveLayer(id:String){
        for l in layers{
            if l.id == id {
                self.enableLayer(layer:l)
                return;
            }
        }
    }
    
    func enableLayer(layer:ModifiedCanvasView){
        if(self.activeLayer != nil){
            self.activeLayer?.endAllStrokes()
            self.activeLayer?.drawActive = false;
        }
        self.activeLayer = layer;
        activeLayer?.drawActive = self.drawActive;
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
           
        }
        
    }
    


    
    
}
