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
    var drawMode = "n/a"
    let exportKey = NSUUID().uuidString;
    let saveKey = NSUUID().uuidString;

    let exportEvent = Event<(String,UIImage?)>()
    let saveEvent = Event<(JSON,[String:String],[String:String],[String:[String]])>()

    var exportHandlers = [Disposable]();
    var saveHandlers = [Disposable]();

    var exportedImages = [UIImage]();
    var savedImageList = [String:String]();
    var savedStateList = [String:String]();
    var savedStrokeList = [String:[String]]();
    var savedJSONList = [JSON]();
    var targetSize: CGSize;
    var exportTarget = 0;
    init(width:Float,height:Float){
        let frame = CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height))
        self.targetSize = CGSize(width: CGFloat(width), height: CGFloat(height))
        super.init(frame: frame);
        self.backgroundColor = UIColor.white;
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.targetSize = CGSize(width: 100, height: 100)
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
               let handler = l.saveEvent.addHandler(target: self, handler: LayerContainerView.exportHandler, key: exportKey)
                exportHandlers.append(handler);
                l.saveUIImageAndState();
            }
        }
    }
    
    func save(){
        savedJSONList.removeAll();
        savedImageList.removeAll();
        savedStateList.removeAll();
        savedStrokeList.removeAll();
        
        for l in layers{
            let h = l.saveEvent.addHandler(target: self, handler: LayerContainerView.saveHandler, key: saveKey)
            l.saveUIImageAndState();
            saveHandlers.append(h);
        }
    }
    
    func saveHandler(data:(String,String,UIImage?,UIImage?,JotViewImmutableState?),key:String){
        if(data.0 == "COMPLETE"){
        
        let layer_id =  data.1
            let layer = layers.filter({$0.id == layer_id})[0]
            let strokeData = layer.getSavedStrokes();
            var json:JSON = [:]
            
            json["id"] = JSON(layer.id);
            json["name"] = JSON(layer.name!);
            json["isHidden"] = JSON(layer.isHidden);
            let isActive = (activeLayer == layer)
            json["isActive"] = JSON(isActive);
            json["saved_strokes"] = JSON(strokeData);
            let imageData = layer.jotViewStateInkPathFunc();
            savedImageList[layer_id] = imageData
            json["hasImageData"] = JSON(true)
            
            
            savedStrokeList[layer_id] = strokeData
            
            let stateData = layer.jotViewStatePlistPathFunc();
            savedStateList[layer_id] = stateData
            
            savedJSONList.append(json)
            
            print("saved values",savedJSONList,savedImageList,savedStateList)
            
            if(savedJSONList.count == layers.count){
                for s in saveHandlers{
                    s.dispose()
                }
                saveHandlers.removeAll();
                var drawingJSON:JSON = [:]
                drawingJSON["layers"] = JSON(savedJSONList);
                self.saveEvent.raise(data:(drawingJSON,savedImageList,savedStateList,savedStrokeList))

            }
       
        }
    }
    
    func exportHandler(data:(String,String,UIImage?,UIImage?,JotViewImmutableState?),key:String){
        if(data.0 == "COMPLETE" && data.2 != nil){
            #if DEBUG
            print("export complete",data.2 as Any,data.2?.size as Any)
            #endif
            exportedImages.append(data.2!);
        }
        
        if(exportedImages.count == exportTarget){
            let masterImage = UIView(frame: CGRect(x:0,y:0,width:targetSize.width,height: targetSize.height))
            masterImage.backgroundColor = UIColor.clear;
            for i in exportedImages{
                let img = i
                let subview = UIImageView(image:img)
                subview.backgroundColor = UIColor.clear
                masterImage.addSubview(subview);
            }
            UIGraphicsBeginImageContext(masterImage.bounds.size);
            masterImage.layer.render(in: UIGraphicsGetCurrentContext()!);
            let viewImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
        
            #if DEBUG
                print("export compilation complete",viewImage!.size)
                print("export images count",exportedImages.count)
            #endif
            for d in self.exportHandlers{
                d.dispose();
            }
            exportedImages.removeAll();
            self.exportEvent.raise(data:("COMPLETE",viewImage));
            
        }
        
        
        
    }
    
    func exportPNGAsFile(image:Data)->String{
       let fileManager = FileManager.default
       let path = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent("\"layer_container.png")
            let imageData = image
       
            fileManager.createFile(atPath: path as String, contents: imageData, attributes: nil)
            return path;
       
    }
    

    
    func loadFromData(fileData:JSON,size:CGSize)->[(String,String,Bool,Bool)]{
        self.deleteAllLayers();
        var jsonLayerArray = fileData["layers"].arrayValue;
        var newLayers = [(String,String,Bool,Bool)]()
        for i in 0..<jsonLayerArray.count{
            let layerData = jsonLayerArray[i];
            let id = layerData["id"].stringValue;
            let name = layerData["name"].stringValue;
            let isHidden = layerData["isHidden"].boolValue;
            let isActive = layerData["isActive"].boolValue;
            _ = self.newLayer(name: name, id: id,size: size);
            self.layers.last?.isHidden = isHidden;
            if(isActive){
                self.activeLayer = self.layers.last
            }
            
            newLayers.append((id,name,isActive,isHidden))

        }
        return newLayers
        
    }
    
    func loadImageIntoLayer(id:String){
    print ("load image into layer",id,layers)
        for l in layers{
            if l.id == id {
                
                l.loadNewState()
                return;
            }
            
        }
        print ("layer not found",id)

    }
    
    
    func isReadyToExport()->Bool{
        if(activeLayer != nil){
        return activeLayer!.isReadyToExport()
        }
        return false;
    }
    
    func setDrawActive(val:Bool){
        drawActive = val
        drawMode = "n/a"
        self.activeLayer?.drawActive = drawActive;
        //self.activeLayer?.eraseAll();
    }
    
    func toggleDrawActive(){
        self.setDrawActive(val: !self.drawActive)
    }
    
    func setPenActive(){
        print("set pen active")
        drawMode = "PEN"
        self.activeLayer?.drawMode = drawMode;
    }
    
    func setAirbrushActive(){
        print("set airbrush active")
        drawMode = "AIRBRUSH"
        self.activeLayer?.drawMode = drawMode;
        
    }
    
    
    func newLayer(name:String,id:String?,size:CGSize)->String{
       
        let layer = ModifiedCanvasView(name:name,frame: CGRect(origin:CGPoint(x:0,y:0), size:(size)))
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
    
    func removeStrokesfromLayer(id:String, strokes:[String]){
        for i in 0..<layers.count{
            if layers[i].id == id {
                let layer = layers[i];
                //layer.removeStrokesById(strokes:strokes);
                break;
            }
        }
    }
    
    func removeStroke(idList:[String]){
        if(self.activeLayer != nil){
            self.activeLayer?.endStrokes(idList:idList)
        }
    }
    
    func removeAllStrokes(){
        if(self.activeLayer != nil){
            self.activeLayer?.endAllStrokes()
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
