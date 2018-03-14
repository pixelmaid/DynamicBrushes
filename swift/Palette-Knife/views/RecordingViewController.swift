//
//  RecordingViewController.swift
//  DynamicBrushes
//
//  Created by Jingyi Li on 2/5/18.
//  Copyright © 2018 pixelmaid. All rights reserved.
//

import Foundation
import UIKit

class GestureRecording {
    var id:String;
    var x:Recording;
    var y:Recording;

    init(id:String,x:Recording,y:Recording) {
        self.id = id;
        self.x = x;
        self.y = y;
    }
}


//for random color
extension CGFloat {
    static var random: CGFloat {
        return CGFloat(arc4random()) / CGFloat(UInt32.max)
    }
}

extension UIColor {
    static var random: UIColor {
        return UIColor(red: .random, green: .random, blue: .random, alpha: 1.0)
    }
}

class RecordingViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    //data source
    public static var gestures = [GestureRecording]()
    //selection handling
    public static var recording_start = Int.max
    public static var recording_end = -1
    public static var currKeyframeOffset = 0
    var firstLoopCompleted = false
    
    var isRecordingLoop = false
    var anyCellsSelected = true
    var scrolledToCell = 0
    var scrolledToColor = UIColor.white.cgColor
    
    
    let divisor:Float = 6.83 //canvas size / divisor = thumbnail size; 1366 / 6.83 = 200
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        return true
    }
    func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let indexPath = NSIndexPath(item:0, section:0)
        let attrib = collectionView?.layoutAttributesForItem(at: indexPath as IndexPath)
        return [attrib!]
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.collectionView.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let recordingKey = NSUUID().uuidString
        let keyframeKey = NSUUID().uuidString
        collectionView?.allowsMultipleSelection = true
        collectionView?.isPrefetchingEnabled = true
        collectionView?.dataSource = self
        collectionView?.delegate = self
//        collectionView?.prefetchDataSource = self
        _ = StylusManager.recordEvent.addHandler(target:self, handler: RecordingViewController.recordingCreatedHandler, key: recordingKey)
        collectionView?.register(RecordingFrameCell.self, forCellWithReuseIdentifier: "cell")
        _ = StylusManager.visualizationEvent.addHandler(target: self, handler: RecordingViewController.highlightCellForPlayback, key: keyframeKey)
        _ = StylusManager.visualizationEvent.addHandler(target: self, handler: RecordingViewController.deselectLastKeyframe, key: keyframeKey)

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        print("^^^^^^^^ end scroll")
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        print("^^^^^ scrolled to ", scrolledToCell)
        let visibleCells = collectionView?.indexPathsForVisibleItems
//        print("^^^^ visible cells ", visibleCells)
        let indexPath = NSIndexPath(item: scrolledToCell, section:0)
        let cell = collectionView?.cellForItem(at: indexPath as IndexPath)
//        print("^^^^^ scrolled to cell is ", cell)
        if isRecordingLoop {
            cell?.layer.borderColor = scrolledToColor
//            print("^^^^ set color ", scrolledToColor)
            
            let indexPath2 = NSIndexPath(item: scrolledToCell+1, section:0)
            let cell2 = collectionView?.cellForItem(at: indexPath2 as IndexPath)
            cell2?.layer.borderColor = UIColor.orange.cgColor
            print("^^^^^ orange cell is ", cell2)

        } else {
            for indexPath in visibleCells! {
                let cell = collectionView?.cellForItem(at: indexPath as IndexPath)
                    if !anyCellsSelected {
                        cell?.layer.borderColor = UIColor.white.cgColor
//                        print("^^^^ set color white")
                    } else if scrolledToCell >= RecordingViewController.recording_start && scrolledToCell <= RecordingViewController.recording_end {
                        cell?.layer.borderColor = UIColor.green.cgColor
                        print("^^^^ set color green")
                    }
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return RecordingViewController.gestures.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RecordingFrameCell", for: indexPath) as! RecordingFrameCell
        let idx = indexPath.item
        print ("^^ cellforItemAt called for item ", idx)

        //draw thumbnail
        let lastGesture = RecordingViewController.gestures[idx]
        let x = lastGesture.x
        let y = lastGesture.y
        let xstrokes = x.getTimeOrderedList()
        let ystrokes = y.getTimeOrderedList()
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 200, height: 150))
        imageView.backgroundColor = UIColor.white
        imageView.contentMode = UIViewContentMode.scaleAspectFit
        cell.contentView.addSubview(imageView)
        drawThumbnail(xStrokes: xstrokes, yStrokes: ystrokes, image: imageView, onion: false)
        //draw onionskin
        if indexPath.item >= 1 {
            let xstrokes1 = RecordingViewController.gestures[idx-1].x.getTimeOrderedList()
            let ystrokes1 = RecordingViewController.gestures[idx-1].y.getTimeOrderedList()
            drawThumbnail(xStrokes: xstrokes1, yStrokes: ystrokes1, image: imageView, onion: true, alpha: 0.3)
            if indexPath.item >= 2 {
                let xstrokes2 = RecordingViewController.gestures[idx-2].x.getTimeOrderedList()
                let ystrokes2 = RecordingViewController.gestures[idx-2].y.getTimeOrderedList()
                drawThumbnail(xStrokes: xstrokes2, yStrokes: ystrokes2, image: imageView, onion: true, alpha: 0.2)
                if indexPath.item >= 3 {
                    
                    let upToStrokes = RecordingViewController.gestures.count - 3
                    for i in 0 ..< upToStrokes {
                        let xstrokes3 = RecordingViewController.gestures[i].x.getTimeOrderedList()
                        let ystrokes3 = RecordingViewController.gestures[i].y.getTimeOrderedList()
                        drawThumbnail(xStrokes: xstrokes3, yStrokes: ystrokes3, image: imageView, onion: true, alpha: 0.1)
                    }
                }
            }
        }
        //selected by default but only the first time...
        if !firstLoopCompleted {
            if idx < RecordingViewController.recording_start {
                RecordingViewController.recording_start = idx
            }
            if idx > RecordingViewController.recording_end {
                RecordingViewController.recording_end = idx
            }
            highlightCells()
            cell.layer.borderWidth = 4.0
            cell.layer.borderColor = UIColor.green.cgColor
        }
        
        if !anyCellsSelected {
            cell.layer.borderColor = UIColor.white.cgColor
            cell.layer.borderWidth = 0
        }

        return cell
    }

    func drawThumbnail(xStrokes:[Float],yStrokes:[Float],image:UIImageView, onion:Bool, alpha: CGFloat = 1.0) {
        //assert xStrokes.count == yStrokes.count
        for idx in stride(from:0, to:xStrokes.count, by:1) {
            let c1x = xStrokes[idx] / divisor
            let c1y = yStrokes[idx] / divisor
            var idx2 = idx + 1
            if idx == xStrokes.count - 1 { idx2 = idx }
            let c2x = xStrokes[idx2] / divisor
            let c2y = yStrokes[idx2] / divisor
            let p1 = CGPoint(x:Int(c1x), y:Int(c1y))
            let p2 = CGPoint(x:Int(c2x), y:Int(c2y))
            
            if !onion {
                //draw first point in green, draw last point in red, draw everything else in blue
                if idx == 0 {
                    drawLine(from:p1, to:p2, image:image, r:0.0, g:1.0, b:0.0, a:alpha, width:3.0)
                } else if idx == xStrokes.count - 1 {
                    drawLine(from:p1, to:p2, image:image, r:1.0, g:0.0, b:0.0, a:alpha, width:3.0)
                } else {
                    drawLine(from:p1, to:p2, image:image, r:0.0, g:0.0, b:1.0, a:alpha, width:1.0)
                }
            } else {
                //draw onionskin lines at alpha
                drawLine(from:p1, to:p2, image:image, r:0.0, g:0.0, b:1.0, a:alpha, width:1.0)
            }
        }
    }
    
    // ====== selection handling ======
    //select start and end ranges
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let idx = indexPath[1]
        //set starting point
        if idx < RecordingViewController.recording_start {
            RecordingViewController.recording_start = idx
        }
        if idx > RecordingViewController.recording_end {
            RecordingViewController.recording_end = idx
        }
        highlightCells()
    }
    
    
    //if click on any cell in range, deselect range
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        resetSelection()
    }
    
    func mod(_ a: Int, _ n: Int) -> Int {
        precondition(n > 0, "modulus must be positive")
        let r = a % n
        return r >= 0 ? r : r + n
    }
    
    func highlightCellForPlayback(data:String, key:String) {
        if data == "ADVANCE_KEYFRAME" {
//            inHighlightingKeyframes = true
            print ("^^ H start and end offset are " , RecordingViewController.recording_start, RecordingViewController.recording_end, RecordingViewController.currKeyframeOffset)

            let totalFrames:Int = RecordingViewController.recording_end - RecordingViewController.recording_start + 1
            let index = mod(RecordingViewController.currKeyframeOffset, totalFrames) + RecordingViewController.recording_start
            let prev = mod((index - RecordingViewController.recording_start - 1), totalFrames) + RecordingViewController.recording_start
//            if prev == -1 {
//                highlightKeyframe(i: RecordingViewController.recording_end, isYellow: false)
//            } //IDK WHY THIS HAPPENS cuz mod math should never be -???
            print ("^^ H index is " , index)
            print ("^^ H prev is " , prev)

            if (prev != -1) {
                highlightKeyframe(i: prev, isYellow: false)
            }

            highlightKeyframe(i: index, isYellow: true)

            RecordingViewController.currKeyframeOffset += 1
            if RecordingViewController.currKeyframeOffset > RecordingViewController.recording_end {
                RecordingViewController.currKeyframeOffset = 0
            }

        }
    }
    
    func highlightKeyframe(i:Int, isYellow:Bool) {
        print("^^ higlighting " , i, " is yellow? ", isYellow)
        var sp = UICollectionViewScrollPosition.right
        if i == RecordingViewController.recording_start { sp = UICollectionViewScrollPosition.left }

        let indexPath = NSIndexPath(item:i, section:0)
        if i < RecordingViewController.gestures.count - 1 {
            let nextIndexPath = NSIndexPath(item:i+1, section:0)
            collectionView?.scrollToItem(at: nextIndexPath as IndexPath, at: UICollectionViewScrollPosition.right, animated: false)
        } else {
            collectionView?.scrollToItem(at: indexPath as IndexPath, at: sp, animated: false)
        }
       
//        let layout = collectionView?.layoutAttributesForItem(at: indexPath as IndexPath)
//        let x = layout!.center.x - 500
//        let offset = CGPoint(x: x, y: 0)
//        collectionView?.setContentOffset(offset, animated: false)
        
        scrolledToCell = i
        
        

            let cell = self.collectionView?.cellForItem(at: indexPath as IndexPath)
////            print("^^ cell is ", cell)
            cell?.layer.borderWidth = 4.0
            if isYellow {
                scrolledToColor = UIColor.orange.cgColor
                cell?.layer.borderColor = UIColor.orange.cgColor
            } else {
                scrolledToColor = UIColor.green.cgColor
                cell?.layer.borderColor = UIColor.green.cgColor
            }
        
    }

    
    func deselectLastKeyframe(data:String, key:String){
        if data == "DESELECT_LAST" { //recording has finished looping one last time
            highlightKeyframe(i: RecordingViewController.recording_end, isYellow: false)
            RecordingViewController.currKeyframeOffset = 0
            isRecordingLoop = false
        }
    }
    
    func highlightCells() {
        anyCellsSelected = true
        print("^^ highlighting from", RecordingViewController.recording_start, " to ", RecordingViewController.recording_end)
        for i in stride(from:RecordingViewController.recording_start, to:RecordingViewController.recording_end+1, by:1) {
            let indexPath = NSIndexPath(item:i, section:0)
            let cell = collectionView?.cellForItem(at: indexPath as IndexPath)
            cell?.layer.borderWidth = 4.0
            cell?.layer.borderColor = UIColor.green.cgColor
            collectionView?.selectItem(at: indexPath as IndexPath, animated: false, scrollPosition: [])
            scrolledToCell = i
        }
    }
    
    func resetSelection() {
        anyCellsSelected = false
        print ("^^ reseting selection which was originally from ", RecordingViewController.recording_start, " to ", RecordingViewController.recording_end+1)
        for i in stride(from:RecordingViewController.recording_start, to:RecordingViewController.recording_end+1, by:1) {
            let indexPath = NSIndexPath(item:i, section:0)
            collectionView?.deselectItem(at: indexPath as IndexPath, animated: false)
            let cell = collectionView?.cellForItem(at: indexPath as IndexPath)
            cell?.layer.borderWidth = 0.0
            cell?.layer.borderColor = UIColor.white.cgColor
        }
        RecordingViewController.recording_start = Int.max
        RecordingViewController.recording_end = -1
        firstLoopCompleted = true //if they deselect, should only manually select
    }

    //from an index, go to a gesture stringid
    func getGestureId(index:Int) -> String {
        return RecordingViewController.gestures[index].id
    }
    
    func loopInitialized() {
        print (RecordingViewController.recording_start, RecordingViewController.recording_end)
        if (RecordingViewController.recording_start >= 0 && RecordingViewController.recording_end >= RecordingViewController.recording_start) {
            print ("^^ going to loop from ", RecordingViewController.recording_start, " to ", RecordingViewController.recording_end)
            let start_id = getGestureId(index: RecordingViewController.recording_start)
            let end_id = getGestureId(index: RecordingViewController.recording_end)
            if (StylusManager.liveStatus()) {
                isRecordingLoop = true
                StylusManager.setToRecording(idStart: start_id, idEnd: end_id)
                //erase strokes associated with the recording
                StylusManager.eraseStrokesForLooping(idStart:start_id, idEnd:end_id)
                
            } else { //stop recording
                StylusManager.setToLive()
                firstLoopCompleted = true
            }
        }
    }
    
    func recordingCreatedHandler (data:(String, StylusRecordingPackage), key:String) {
        let stylusdata = data.1
        RecordingViewController.gestures.append(GestureRecording(id: stylusdata.id, x:stylusdata.x, y:stylusdata.y))
        let IndexPath = NSIndexPath(item: RecordingViewController.gestures.count-1, section:0)
        collectionView?.insertItems(at: [IndexPath as IndexPath])
        collectionView?.scrollToItem(at: IndexPath as IndexPath, at: UICollectionViewScrollPosition.right, animated: false)
    }

    func drawLine(from fromPoint: CGPoint, to toPoint: CGPoint, image imageView:UIImageView, r red:CGFloat, g green:CGFloat, b blue:CGFloat, a alpha:CGFloat, width brushWidth:CGFloat) {

        UIGraphicsBeginImageContextWithOptions(imageView.frame.size, false, 0)
        
        imageView.image?.draw(in: imageView.frame)
        
        let context = UIGraphicsGetCurrentContext()
        
        context?.move(to: fromPoint)
        context?.addLine(to: toPoint)
        
        context?.setLineCap(CGLineCap.round)
        context?.setLineWidth(brushWidth)
        context?.setStrokeColor(red: red, green: green, blue: blue, alpha: alpha)
        context?.setBlendMode(CGBlendMode.normal)
        context?.strokePath()
        
        imageView.image = UIGraphicsGetImageFromCurrentImageContext()
        imageView.alpha = 1.0
        UIGraphicsEndImageContext()
    }
    
}

