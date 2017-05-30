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
    var jotView:JotView!
    //JotView params
    var jotViewStateInkPath: String!
    var jotViewStatePlistPath: String!
    var numberOfTouches:Int = 0
    var lastLoc:CGPoint!
    var lastDate:NSDate!
    var velocity = 0;
    var strokes = [String:JotStroke]();
    var exportEvent = Event<(String,UIImage?)>();
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
        
        super.init(coder: aDecoder)
        let size = self.frame.size
        jotView = JotView(frame:CGRect(x:0,y:0,width:size.width,height:size.height));
    }
    
    func beginStroke(id:String){
        if(!self.isHidden){
            autoreleasepool {
                if(jotView.state == nil){
                    #if DEBUG
                        print("state is nil")
                    #endif
                    return;
                }
                let newStroke = JotStroke(texture: self.textureForStroke(), andBufferManager: jotView.state.bufferManager());
                newStroke!.delegate = jotView as JotStrokeDelegate;
                
                strokes[id] = newStroke!;
            }
            JotGLContext.validateEmptyStack()
        }
    }
    
    func renderStroke(currentStrokeId:String,toPoint:CGPoint,toWidth:CGFloat,toColor:UIColor!){
        #if DEBUG
            //print("draw interval render stroke",toPoint)
        #endif
        if(!self.isHidden){
            let currentStroke = strokes[currentStrokeId]
            currentStroke?.lock();
            
            jotView.state.currentStroke = currentStroke
            autoreleasepool {
                
                //self.willMoveStroke(withCoalescedTouch: coalescedTouch, from: touch)
                //var shouldSkipSegment = false;
                
                if(currentStroke != nil){
                    jotView.addLine(toAndRenderStroke: currentStroke, to: toPoint, toWidth: toWidth*4, to: toColor, andSmoothness: self.getSmoothness(), withStepWidth: self.stepWidthForStroke())
                    
                }
            }
            
            currentStroke?.unlock();
        }
    }
    
    func validateEmptyStack(){
        JotGLContext.validateEmptyStack();
    }
    
    func endAllStrokes(){
        for (_, value) in self.strokes{
            self.endStroke(currentStroke: value)
        }
        self.strokes.removeAll();
    }
    
    func endStrokes(idList:[String]){
        #if DEBUG
            
            print("total number of jot view strokes",id, strokes.count,strokes);
            
        #endif
        for id in idList{
            let stroke =  strokes.removeValue(forKey: id)
            if(stroke != nil){
                endStroke(currentStroke: stroke!)
            }
        }
        
    }
    
    func endStroke(currentStroke:JotStroke){
        autoreleasepool {
            currentStroke.lock();
            jotView.state.currentStroke =  currentStroke;
            jotView.state.finishCurrentStroke();
            
            //if currentStroke.segments.count == 1 && (((currentStroke.segments.first as? MoveToPathElement) != nil)) {
            //currentStroke.empty()
            //}
            
            
            
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
        else {
            self.beginStroke(id:"eraseStroke")
        }
    }
    
    /*
     - (IBAction)saveImage {
     [jotView exportImageTo:[self jotViewStateInkPath] andThumbnailTo:[self jotViewStateThumbPath] andStateTo:[self jotViewStatePlistPath] withThumbnailScale:1.0 onComplete:^(UIImage* ink, UIImage* thumb, JotViewImmutableState* state) {
     UIImageWriteToSavedPhotosAlbum(thumb, nil, nil, nil);
     dispatch_async(dispatch_get_main_queue(), ^{
     UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Saved" message:@"The JotView's state has been saved to disk, and a full resolution image has been saved to the photo album." preferredStyle:UIAlertControllerStyleAlert];
     [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil]];
     [self presentViewController:alert animated:YES completion:nil];
     });
     }];
     }*/
    
    func statePlistPath() -> String {
        return URL(fileURLWithPath: documentsDir()).appendingPathComponent("state.plist").absoluteString
    }
    
    func documentsDir() -> String {
        let userDocumentsPaths: [String] = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        return userDocumentsPaths[0]
    }
    
    func exportUIImage(){
        self.endAllStrokes();
        let fileManager = FileManager.default
        let path = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent("\(id).png")
        let thumb_path = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent("\(id)_thumb.png")
        
        let image: ((UIImage?) -> Void)! = imageExportComplete
        jotView.exportToImage(onComplete: image, withScale: 2)
    }
    
    func exportPNGAsFile()->String?{
        
        /*let image = self.image
         
         if(image != nil){
         let fileManager = FileManager.default
         let path = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent("\(id).png")
         let imageData = UIImagePNGRepresentation(image!)
         UIImagePNGRepresentation(UIImage())
         fileManager.createFile(atPath: path as String, contents: imageData, attributes: nil)
         return path;
         }*/
        return nil
        
    }
    func imageExportComplete(image: UIImage?) {
        print("image: \(image)")
        self.exportEvent.raise(data: ("COMPLETE",image!));
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
        if let coalescedTouches = event?.coalescedTouches(for: touch) {
            touches = coalescedTouches
        } else {
            touches.append(touch)
        }
        #if DEBUG
            //print("number of coalesced touches \(touches.count)");
        #endif
        // if touch.type == .stylus {
        if(drawActive){
            
            for touch in touches {
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
            let location = touch.location(in: self)
            let width = CGFloat(uiInput.diameter.get(id: nil));
            
            
            self.renderStroke(currentStrokeId: "eraseStroke", toPoint: location, toWidth: width, toColor: nil)
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
        if drawActive == false {
            self.endStrokes(idList: ["eraseStroke"])
        }
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
