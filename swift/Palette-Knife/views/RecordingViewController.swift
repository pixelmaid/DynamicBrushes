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
    override func viewDidLoad() {
        super.viewDidLoad()
        let recordingKey = NSUUID().uuidString
        collectionView?.allowsMultipleSelection = true
        collectionView?.isPrefetchingEnabled = true
        _ = StylusManager.recordEvent.addHandler(target:self, handler: RecordingViewController.recordingCreatedHandler, key: recordingKey)
        collectionView?.register(RecordingFrameCell.self, forCellWithReuseIdentifier: "cell")
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return RecordingViewController.gestures.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RecordingFrameCell", for: indexPath) as! RecordingFrameCell
        print ("^^ calling cell for itemat at ", indexPath.item)
        //only draw if last cell
        let last_item = RecordingViewController.gestures.count - 1
        print ("^^ last item ", last_item)
        if indexPath.item == last_item {
            let lastGesture = RecordingViewController.gestures.last
            let x = lastGesture?.x
            let y = lastGesture?.y
            let xstrokes = x?.getTimeOrderedList()
            let ystrokes = y?.getTimeOrderedList()
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 200, height: 150))
            imageView.backgroundColor = UIColor.white
            imageView.contentMode = UIViewContentMode.scaleAspectFit

            
            cell.contentView.addSubview(imageView)
            print ("^^ added imageview ")
            drawThumbnail(xStrokes: xstrokes!, yStrokes: ystrokes!, image: imageView)
            
            collectionView.reloadData()
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                                 willDisplay cell: UICollectionViewCell,
                                 forItemAt indexPath: IndexPath) {

        //now draw on it...

    }

    func drawThumbnail(xStrokes:[Float],yStrokes:[Float],image:UIImageView) {
        //assert xStrokes.count == yStrokes.count
        print ("^^ in draw thumb")
        for idx in stride(from:0, to:xStrokes.count, by:1) {
            let c1x = xStrokes[idx] / divisor
            let c1y = yStrokes[idx] / divisor
            var idx2 = idx + 1
            if idx == xStrokes.count - 1 { idx2 = idx }
            let c2x = xStrokes[idx2] / divisor
            let c2y = yStrokes[idx2] / divisor
            let p1 = CGPoint(x:Int(c1x), y:Int(c1y))
            let p2 = CGPoint(x:Int(c2x), y:Int(c2y))
            drawLine(from:p1, to:p2, image:image)
        }
    }
    
    // ====== selection handling ======
    //select start and end ranges
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let idx = indexPath[1]
        print("^^ recording selected index", indexPath[1])
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
        print("^^ recording deselected index", indexPath[1])
        resetSelection()
    }
    
    func highlightCells() {
        print("^^ highlighting from", RecordingViewController.recording_start, " to ", RecordingViewController.recording_end+1)
        for i in stride(from:RecordingViewController.recording_start, to:RecordingViewController.recording_end+1, by:1) {
            let indexPath = NSIndexPath(item:i, section:0)
            let cell = collectionView?.cellForItem(at: indexPath as IndexPath)
            cell?.layer.borderWidth = 4.0
            cell?.layer.borderColor = UIColor.green.cgColor
            collectionView?.selectItem(at: indexPath as IndexPath, animated: false, scrollPosition: [])
        }
    }
    
    func resetSelection() {
        print ("^^ reseting selection from ", RecordingViewController.recording_start, " to ", RecordingViewController.recording_end+1)
        for i in stride(from:RecordingViewController.recording_start, to:RecordingViewController.recording_end+1, by:1) {
            let indexPath = NSIndexPath(item:i, section:0)
            print ("^^ total cells in collectionview ", collectionView?.numberOfItems(inSection: 0))
            let cell = collectionView?.cellForItem(at: indexPath as IndexPath)
            print("^^inside reset found cell ", cell)
            cell?.layer.borderWidth = 0.0
            collectionView?.deselectItem(at: indexPath as IndexPath, animated: false)
        }
        RecordingViewController.recording_start = Int.max
        RecordingViewController.recording_end = -1
    }

    //from an index, go to a gesture stringid
    func getGestureId(index:Int) -> String {
        return RecordingViewController.gestures[index].id
    }
    
    func loopInitialized() {
        print ("^^ loop button pressed")
        print (RecordingViewController.recording_start, RecordingViewController.recording_end)
        if (RecordingViewController.recording_start >= 0 && RecordingViewController.recording_end >= RecordingViewController.recording_start) {
            print ("^^ going to loop from ", RecordingViewController.recording_start, " to ", RecordingViewController.recording_end)
            let start_id = getGestureId(index: RecordingViewController.recording_start)
            let end_id = getGestureId(index: RecordingViewController.recording_end)
            if (StylusManager.liveStatus()) {
                StylusManager.setToRecording(idStart: start_id, idEnd: end_id)
                //erase strokes associated with the recording
                StylusManager.eraseStrokesForLooping(idStart:start_id, idEnd:end_id)
                
            } else { //stop recording
                StylusManager.setToLive()
                //clear selection
                resetSelection()
            }
        }
    }
    
    func recordingCreatedHandler (data:(String, StylusRecordingPackage), key:String) {
        let stylusdata = data.1
        RecordingViewController.gestures.append(GestureRecording(id: stylusdata.id, x:stylusdata.x, y:stylusdata.y))
        print("^^ appended new stylus data")
        let IndexPath = NSIndexPath(item: RecordingViewController.gestures.count-1, section:0)
        collectionView?.insertItems(at: [IndexPath as IndexPath])
        collectionView?.scrollToItem(at: IndexPath as IndexPath, at: UICollectionViewScrollPosition.right, animated: false)
    }

    func drawLine(from fromPoint: CGPoint, to toPoint: CGPoint, image imageView:UIImageView) {
//        print("^^ drawing from ", fromPoint, toPoint)
        let brushWidth: CGFloat = 1.0
        let opacity: CGFloat = 1.0

        UIGraphicsBeginImageContextWithOptions(imageView.frame.size, false, 0)
        
        imageView.image?.draw(in: imageView.frame)
        
        let context = UIGraphicsGetCurrentContext()
        
        context?.move(to: fromPoint)
        context?.addLine(to: toPoint)
        
        context?.setLineCap(CGLineCap.round)
        context?.setLineWidth(brushWidth)
        context?.setStrokeColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 1.0)
        context?.setBlendMode(CGBlendMode.normal)
        context?.strokePath()
        
        imageView.image = UIGraphicsGetImageFromCurrentImageContext()
        imageView.alpha = opacity
        UIGraphicsEndImageContext()
    }
    
}

