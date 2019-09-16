//
//  ModifiedCanvasView.swift
//  DynamicBrushes
//
//  Created by JENNIFER MARY JACOBS on 4/29/17.
//  Copyright © 2017 pixelmaid. All rights reserved.
//

import Foundation
import UIKit

let pi = Float.pi

class ModifiedCanvasView: UIView, JotViewDelegate,JotViewStateProxyDelegate {
    //TODO: these are extraneous, should remove them
    var jotViewStateInkPath: String!
    var jotViewStatePlistPath:String!
    
    var id = NSUUID().uuidString;
    let name:String?
    var drawActive = true;
    var drawMode = "PEN"
    var jotView:JotView!
    //JotView params
   
    var numberOfTouches:Int = 0
    var lastLoc:CGPoint!
    var lastDate:NSDate!
    var velocity = 0;
    var activeStrokes = [String:JotStroke]();
    var allStrokes = [JotStroke]();
    var saveEvent = Event<(String,String,UIImage?,UIImage?,JotViewImmutableState?)>();
    //end JotView params
    
    init(name:String,frame:CGRect){
        self.name = name
        jotView = JotView(frame:frame);
        super.init(frame:frame)
        jotView.backgroundColor = UIColor.clear
        jotView.delegate = self
        _ = self.jotViewStateInkPathFunc();
        _ = self.jotViewStatePlistPathFunc();
        _ = self.jotViewStateThumbPathFunc();
        #if DEBUG
            print("jot view size and scale",jotView.bounds.size.width,jotView.bounds.size.height,jotView.scale)
        #endif
        let paperState = JotViewStateProxy(delegate: self)
        paperState?.loadJotStateAsynchronously(false, with: jotView.bounds.size, andScale: jotView.scale, andContext: jotView.context, andBufferManager: JotBufferManager.sharedInstance())
        jotView.loadState(paperState)
        self.addSubview(jotView)
        
    }
    
    
    deinit{
        self.removeAllStrokes();
        #if DEBUG
        print("dealocated layer \(self.id)")
        #endif

    }
    
   
    
    required init?(coder aDecoder: NSCoder) {
        self.name = "noname";
       
        super.init(coder: aDecoder)
        let size = self.frame.size
        jotView = JotView(frame:CGRect(x:0,y:0,width:size.width,height:size.height));
    }
    
    func isReadyToExport()->Bool{
        if(jotView.state != nil){
            return jotView.state.isReadyToExport()
        }
        else{
            return false;
        }
    }
    
    func beginStroke(id:String){
        if(!self.isHidden){
           print("~~~ begin strokes called")
            autoreleasepool {
                if(jotView.state == nil){
                    #if DEBUG
                        print("state is nil")
                    #endif
                    print("~~~ state is nil")
                    return;
                }
                let texture: JotBrushTexture
                if(self.drawMode == "PEN"){
                    print("setting texture to pen")
                   // JotDefaultBrushTexture.sharedInstance().unbind();
                    texture = JotSquareBrushTexture.sharedInstance()
                }
                else{
                    print("setting texture to brush")
                    //JotSquareBrushTexture.sharedInstance().unbind();
                    texture = JotDefaultBrushTexture.sharedInstance()
                }
                let newStroke = JotStroke(texture: texture, andBufferManager: jotView.state.bufferManager());
                 newStroke!.setId(id)
                newStroke!.delegate = jotView as JotStrokeDelegate;
                
                    activeStrokes[id] = newStroke!;
                    print("~~~ added ", id, " to active Strokes")
                    allStrokes.append(newStroke!)
                
            }
            JotGLContext.validateEmptyStack()
        }
    }
    
    func undoById(strokeIds:[String]){
        self.endAllStrokes();
        for id in strokeIds{
            self.jotView.undo(byId: id);
        }

    }
    
    func removeAllStrokes(){
        for value in allStrokes{
            value.lock();
            value.empty();
            value.unlock();

        }
        /*if self is VisualizationView {
            print ("@@ activeStrokes are ", self.activeStrokes)
        }*/
        
        self.allStrokes.removeAll();
        self.activeStrokes.removeAll();
        JotGLContext.validateEmptyStack();
    }
    
    func renderStrokeById(currentStrokeId: String, toPoint:CGPoint,toWidth:CGFloat,toColor:UIColor!){
        guard let currentStroke:JotStroke = activeStrokes[currentStrokeId] else {
            print(activeStrokes, activeStrokes.count)
            print("no stroke by id",currentStrokeId);
            return;
            
        }
        let color:UIColor!
        if(drawActive){
            color = toColor
        }
        else{
            color = nil
        }
        //if(inBounds(point:toPoint)){
        if(currentStrokeId  == "vstrokeG"){
            print("rendering green stroke");
        }
        self.renderStroke(currentStroke: currentStroke, toPoint: toPoint, toWidth: toWidth, toColor: color)
        /*}
        else{
            self.endStrokes(idList: [currentStrokeId]);
 
        }*/
    }
    
    func renderStroke(currentStroke:JotStroke,toPoint:CGPoint,toWidth:CGFloat,toColor:UIColor!){
        #if DEBUG
            //print("draw interval render stroke",toPoint)
        #endif
        if(!self.isHidden){
           
                if(jotView.state == nil){
                    #if DEBUG
                        print("state is nil")
                    #endif
                    return;
                }
            
            currentStroke.lock();
             autoreleasepool {
                var finalWidth = toWidth * 4;
                if(finalWidth < 1){
                    finalWidth = 1;
                }
                if(finalWidth > 300){
                    finalWidth = 300;
                }
                   _ = jotView.addLine(toAndRenderStroke: currentStroke, to: toPoint, toWidth: finalWidth, to: toColor, andSmoothness: self.getSmoothness(), withStepWidth: self.stepWidthForStroke())
                    
                
            
            }
            currentStroke.unlock();
                JotGLContext.validateEmptyStack();
            

            
        }
    }
    
    
    func inBounds(point:CGPoint)->Bool{
        var inb = true
        if(point.x<0 || point.y<0){
            inb = false
        }
        if(point.x>jotView.bounds.width || point.y>jotView.bounds.height){
            inb = false
        }
        
        
        return inb
        
    }
    
    func endAllStrokes(){
         #if DEBUG
            
        print("ending all strokes",self.activeStrokes,self.activeStrokes.count)
            #endif
        
        
        
        for (id, value) in self.activeStrokes{
            if(value.segments.count > 0){
                if(value.segments.count > 0){
                    endStroke(currentStroke: value)
                }
                activeStrokes.removeValue(forKey: id)
            }
        }
        #if DEBUG
            print("strokes remaining",self.activeStrokes,self.activeStrokes.count)
        #endif
       

    }
    
    func endStrokes(idList:[String]){
        #if DEBUG
            
            print("total number of active jot view strokes",id, activeStrokes.count,activeStrokes);
            
        #endif
        for id in idList{
            #if DEBUG
            print("ending strokes",id,activeStrokes[id]);
            #endif
            let stroke =  activeStrokes[id]
            if(stroke != nil){
                if((stroke?.segments.count)! > 0){
                    endStroke(currentStroke: stroke!)
                }
                activeStrokes.removeValue(forKey: id)
            }
        }
        
    }
    
    func endStroke(currentStroke:JotStroke){
        autoreleasepool {
            currentStroke.lock();
            jotView.state.currentStroke =  currentStroke;
            jotView.state.addUndoLevelAndFinishStroke();
            currentStroke.unlock();
        }
        JotGLContext.validateEmptyStack();
    }
    
    
   
    
    
    
    func saveUIImageAndState(){
        self.endAllStrokes();
        let stateImage: ((UIImage?, UIImage?, JotViewImmutableState?) -> Void)! = imageStateSaveComplete
        jotView.exportImage(to: self.jotViewStateInkPathFunc(), andThumbnailTo:self.jotViewStateThumbPathFunc(), andStateTo: self.jotViewStatePlistPathFunc(), withThumbnailScale:2.0, onComplete: stateImage)
    }

    
    //handler called when state is saved
    func imageStateSaveComplete(ink:UIImage?, thumb:UIImage?, state:JotViewImmutableState?){
        if(thumb != nil && ink != nil && state != nil){
        self.saveEvent.raise(data: ("COMPLETE",self.id,thumb!,ink!,state!));
        }
        else{
            self.saveEvent.raise(data: ("INCOMPLETE",self.id,nil,nil,nil));

        }
    }
    
    
    //returns a list of all saved strokes in the state
    func getSavedStrokes()->[String]{
        var strokeList = [String]();

        for value in allStrokes{
            if value.uuid() != "1" {
            strokeList.append(value.uuid());
            }
        }
      
        return [String]();
    }

    
    
    func loadNewState() {
        self.removeAllStrokes();
        _ = jotViewStateInkPathFunc();
        _ = jotViewStatePlistPathFunc();
        _ = jotViewStateThumbPathFunc();
        print("load new state called",self.jotViewStatePlistPath,self.jotViewStateInkPath)
        jotView.state.isForgetful = true
        let state = JotViewStateProxy(delegate:self);
        state?.loadJotStateAsynchronously(false, with: jotView.bounds.size, andScale: 1.0, andContext: jotView.context, andBufferManager: JotBufferManager.sharedInstance())
        jotView.loadState(state)
        
        let v_strokes = state?.everyVisibleStroke();
        #if DEBUG
        print("visible strokes",v_strokes as Any);
        #endif
        
        for s in v_strokes!{
            guard let stroke = s as? JotStroke else { return }
           
            self.allStrokes.append(stroke)
            
        }
        
        print("strokes after load = ",self.allStrokes);
        
    }

    
    func pushContext()->ModifiedCanvasView{
        return self;
    }
    
    
    func recieveTouch(touch:UITouch, state:GestureRecognizer.State, predicted:Bool){
        let location = touch.location(in: self)
        let x = Float(location.x);
        let y = Float(location.y);
        let force = Float(touch.force);
        let angle = Float(touch.azimuthAngle(in: self))
        //let mappedAngle = MathUtil.map(value: angle, low1: 0, high1: 2*Float.pi, low2: 0, high2: 1);
        
        switch(state){
        case .changed:
            stylusManager.onStylusMove(x: x, y: y, force: force, angle: angle)
            break;
        case .ended:
            stylusManager.onStylusUp(x: x, y: y, force: force, angle: angle)
            break;
        case .began:
              stylusManager.onStylusDown(x: x, y: y, force: force, angle: angle);
        break
        default:
            
            break
        }
    }
    
    func eraseCanvas(context:CGContext, start:CGPoint,end:CGPoint,force:CGFloat){
        
        context.setStrokeColor(UIColor.red.cgColor)
        //TODO: will need to fine tune this
        context.setLineWidth(20)
        context.setLineCap(.round)
        context.setAlpha(CGFloat(1));
        context.setBlendMode(CGBlendMode.clear)
        
        context.move(to: start)
        
        context.addLine(to:end)
        context.strokePath()
    }
    
    
    
    func eraseAll() {
        jotView.clear(true)
        // self.image = nil
        
    }
    
    
    // #pragma mark - JotViewDelegate
    
    func textureForStroke()->JotBrushTexture {
        #if DEBUG
            print("current draw mode",self.drawMode)
        #endif
        if(self.drawMode == "PEN"){
            print("setting texture to pen")
            return JotSquareBrushTexture.sharedInstance()
        }
        else{
            print("setting texture to brush")

           return JotDefaultBrushTexture.sharedInstance()
        }
    }
    
    func stepWidthForStroke()->CGFloat {
        return CGFloat(2);
    }
    
    func supportsRotation()->Bool {
        return false
    }
    
    
    func willAddElements(_ elements: [Any]!, to stroke: JotStroke!, fromPreviousElement previousElement: AbstractBezierPathElement!) -> [Any]! {
        return elements
    }
    
    func willBeginStroke(withCoalescedTouch coalescedTouch: UITouch!, from touch: UITouch!) -> Bool {
        
        return true;
    }
    func willMoveStroke(withCoalescedTouch coalescedTouch: UITouch!, from touch: UITouch!) {
        
    }
    
    
    func willEndStroke(withCoalescedTouch coalescedTouch: UITouch!, from touch: UITouch!, shortStrokeEnding: Bool) {
        
    }
    
    func didEndStroke(withCoalescedTouch coalescedTouch: UITouch!, from touch: UITouch!) {
        
    }
    func willCancel(_ stroke: JotStroke!, withCoalescedTouch coalescedTouch: UITouch!, from touch: UITouch!) {
        
    }
    func didCancel(_ stroke: JotStroke!, withCoalescedTouch coalescedTouch: UITouch!, from touch: UITouch!) {
        
    }
    
    func color(forCoalescedTouch coalescedTouch: UITouch!, from touch: UITouch!) -> UIColor! {
        return UIColor.black
        
    }
    
    
    func width(forCoalescedTouch coalescedTouch: UITouch!, from touch: UITouch!) -> CGFloat {
        return 6
        
    }
    
    func smoothness(forCoalescedTouch coalescedTouch: UITouch!, from touch: UITouch!) -> CGFloat {
        return 0.75;
        
    }
    
    func getSmoothness()->CGFloat{
        return 0.75;
    }
    
    //#pragma mark - JotViewStateProxyDelegate
    
    func didLoadState(_ state: JotViewStateProxy!) {
        
    }
    
    func didUnloadState(_ state: JotViewStateProxy!) {
        
    }
    
    
    func jotViewStateInkPathFunc() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray
        let documentDirectory = paths[0] as! String
        let path = documentDirectory.appending("/ink_"+id+".png")
        print("ink",path)
        self.jotViewStateInkPath = path;
        return path

    }
    
    func jotViewStateThumbPathFunc() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray
        let documentDirectory = paths[0] as! String
        let path = documentDirectory.appending("/thumb_"+id+".png")
        print("thumb",path)
        return path

    }
    
    func jotViewStatePlistPathFunc() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true) as NSArray
        let documentDirectory = paths[0] as! String
        let path = documentDirectory.appending("/state_"+id+".plist")
        print("plist",path)
        self.jotViewStatePlistPath = path;

        return path
    }

   


}
