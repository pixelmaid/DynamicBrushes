//
//  ModifiedCanvasView.swift
//  PaletteKnife
//
//  Created by JENNIFER MARY JACOBS on 4/29/17.
//  Copyright © 2017 pixelmaid. All rights reserved.
//

import Foundation
import UIKit

let pi = Float.pi

class ModifiedCanvasView: UIView, JotViewDelegate,JotViewStateProxyDelegate {
    
    
    var id = NSUUID().uuidString;
    let name:String?
    var drawActive = true;
    var jotView:JotView
    //JotView params
    var jotViewStateInkPath: String!
    var jotViewStatePlistPath: String!
    var numberOfTouches:Int = 0
    var lastLoc:CGPoint!
    var lastDate:NSDate!
    var velocity = 0;
    var strokes = [String:JotStroke]();
    //end JotView params
    
    init(name:String,frame:CGRect){
        self.name = name
        jotView = JotView(frame:frame);
        super.init(frame:frame)
        jotView.delegate = self
       
        let paperState = JotViewStateProxy(delegate: self)
        paperState?.loadJotStateAsynchronously(false, with: jotView.bounds.size, andScale: jotView.scale, andContext: jotView.context, andBufferManager: JotBufferManager.sharedInstance())
        jotView.loadState(paperState)
        
        self.addSubview(jotView)

    }
    
    required init?(coder aDecoder: NSCoder) {
        self.name = "noname";
        jotView = JotView(frame:CGRect(x:0,y:0,width:1024,height:768));
       super.init(coder: aDecoder)
    }
    
    func beginStroke(id:String){
        autoreleasepool {
        if(jotView.state == nil){
            print("state is nil")

            return;
        }
        let newStroke = JotStroke(texture: self.textureForStroke(), andBufferManager: jotView.state.bufferManager());
        newStroke!.delegate = jotView as JotStrokeDelegate;
        strokes[id] = newStroke!;
        print("added stroke",id)
        }
        JotGLContext.validateEmptyStack()
    }
    
    func renderStroke(currentStrokeId:String,toPoint:CGPoint,toWidth:CGFloat,toColor:UIColor){
        let currentStroke = strokes[currentStrokeId]
        currentStroke?.lock();
        
        jotView.state.currentStroke = currentStroke
        autoreleasepool {

        //self.willMoveStroke(withCoalescedTouch: coalescedTouch, from: touch)
        var shouldSkipSegment = false;
       
        if(currentStroke != nil && !shouldSkipSegment){
            print("renderStroke",currentStroke)

           jotView.addLine(toAndRenderStroke: currentStroke, to: toPoint, toWidth: toWidth, to: toColor, andSmoothness: self.getSmoothness(), withStepWidth: self.stepWidthForStroke())
        }
        }

        currentStroke?.unlock();
        JotGLContext.validateEmptyStack();
    }
    
    func endStrokes(idList:[String]){
        for id in idList{
            let stroke =  strokes.removeValue(forKey: id)
            endStroke(currentStroke: stroke!)
            print("removed stroke",id)
        }
        print("total number of strokes",strokes.count);        
    }
    
    func endStroke(currentStroke:JotStroke){
         autoreleasepool {
        currentStroke.lock();
        
        
        if currentStroke.segments.count == 1 && (((currentStroke.segments.first as? MoveToPathElement) != nil)) {
            currentStroke.empty()
        }

        
        jotView.state.finishCurrentStroke();
        
        currentStroke.unlock();
        }
        JotGLContext.validateEmptyStack();
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if(drawActive){
        if let touch = touches.first  {
            let point = touch.location(in: self)
            let x = Float(point.x)
            let y = Float(point.y)
            let force = Float(touch.force);
            let angle = Float(touch.azimuthAngle(in: self))
            stylus.onStylusDown(x: x, y:y, force:force, angle:angle)
            }
        }
    }
    
    func exportPNGAsFile()->String?{
        /*let image = self.image
        
        if(image != nil){
        let fileManager = FileManager.default
            let path = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent("\(id).png")
            let imageData = UIImagePNGRepresentation(image!)
            UIImagePNGRepresentation(UIImage())
            fileManager.createFile(atPath: path as String, contents: imageData, attributes: nil)
            print("returning image",path);
            return path;
        }*/
        return nil
        
    }
    
    func loadImage(path:String){
       
        let image = UIImage(contentsOfFile: path)
        self.contentMode = .scaleAspectFit
      //  self.image = image
        
    }
    
    func pushContext()->ModifiedCanvasView{
        return self;
    }
    
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        var touches = [UITouch]()
        print("touches moved")
        if let coalescedTouches = event?.coalescedTouches(for: touch) {
            touches = coalescedTouches
        } else {
            touches.append(touch)
        }
       // if touch.type == .stylus {
        if(drawActive){

            for var i in 0..<touches.count {
                
                let location = touch.location(in: self)
                let x = Float(location.x);
                let y = Float(location.y);
                let force = Float(touch.force);
                let angle = Float(touch.azimuthAngle(in: self))
                //let mappedAngle = MathUtil.map(value: angle, low1: 0, high1: 2*Float.pi, low2: 0, high2: 1);
                stylus.onStylusMove(x: x, y:y, force:force, angle:angle);
                
            }
        }
            //Erase mode
        else {
            /*UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0.0)
            self.image?.draw(in: self.bounds)
            let context = UIGraphicsGetCurrentContext()

            for touch in touches {
                let location = touch.location(in: self)
                let previousLocation = touch.previousLocation(in: self)
                let force = touch.force
                eraseCanvas(context:context!, start:previousLocation,end:location,force:force);
            }
            self.image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()*/
        }
       // }
        
        
        
    }
    
    func eraseCanvas(context:CGContext, start:CGPoint,end:CGPoint,force:CGFloat){
 
        
        
        context.setStrokeColor(UIColor.red.cgColor)
        //TODO: will need to fine tune this
        context.setLineWidth(CGFloat(uiInput.diameter.get(id: nil)))
        context.setLineCap(.round)
        context.setAlpha(CGFloat(1));
        context.setBlendMode(CGBlendMode.clear)

        context.move(to: start)
        
        context.addLine(to:end)
        context.strokePath()
    }
    
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        stylus.onStylusUp()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        //image = drawingImage
    }
    
    func eraseAll() {
        jotView.clear(true)
       // self.image = nil
        
    }
    
    
    // #pragma mark - JotViewDelegate
    
    func textureForStroke()->JotBrushTexture {
        return JotDefaultBrushTexture.sharedInstance()
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
     /*   velocity = 1;
        lastDate = NSDate();
        numberOfTouches = 1;
        */
        return true;
    }
    func willMoveStroke(withCoalescedTouch coalescedTouch: UITouch!, from touch: UITouch!) {
/*        numberOfTouches += 1;
        if (numberOfTouches > 4){
            numberOfTouches = 4;
        }
        let dur = NSDate().timeIntervalSince(lastDate as Date)
        
        if(dur > 00.01){
            // require small duration, otherwise the pts/sec calculation can vary wildly
            /*if self.velocityForTouch(touch) {
             velocity = self.velocityForTouch
             }
             */
            lastDate = NSDate()
            lastLoc = touch.preciseLocation(in:nil);
        }*/
        
        
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
    
    /*- (NSString*)documentsDir {
     NSArray<NSString*>* userDocumentsPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
     return [userDocumentsPaths objectAtIndex:0];
     }
     
     
     - (NSString*)jotViewStateInkPath {
     return [[self documentsDir] stringByAppendingPathComponent:@"ink.png"];
     }
     
     - (NSString*)jotViewStateThumbPath {
     return [[self documentsDir] stringByAppendingPathComponent:@"thumb.png"];
     }
     
     - (NSString*)jotViewStatePlistPath {
     return [[self documentsDir] stringByAppendingPathComponent:@"state.plist"];
     }
     
     - (void)didLoadState:(JotViewStateProxy*)state {
     }
     
     - (void)didUnloadState:(JotViewStateProxy*)state {
     }*/
}
