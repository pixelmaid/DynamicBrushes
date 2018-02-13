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
    var resultantStrokes = [String:[String]]();
    //add a thumbnail thing
    init(id:String, resultantStrokes:[String:[String]]) {
        self.id = id;
        self.resultantStrokes = resultantStrokes;
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
    
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let recordingKey = NSUUID().uuidString
         collectionView?.allowsMultipleSelection = true
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
        //set thumbnail
        //cell.recordingThumbnail.image =
        print ("recording now has ", collectionView.numberOfItems(inSection:0))

        cell.backgroundColor = UIColor.random
        return cell
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
        print ("^^ reseting selection")
        for i in stride(from:RecordingViewController.recording_start, to:RecordingViewController.recording_end+1, by:1) {
            let indexPath = NSIndexPath(item:i, section:0)
            let cell = collectionView?.cellForItem(at: indexPath as IndexPath)
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
        print ("called loop init! ^^")
        print (RecordingViewController.recording_start, RecordingViewController.recording_end)
        if (RecordingViewController.recording_start >= 0 && RecordingViewController.recording_end >= RecordingViewController.recording_start) {
            print ("^^ going to loop from ", RecordingViewController.recording_start, " to ", RecordingViewController.recording_end)
            let start_id = getGestureId(index: RecordingViewController.recording_start)
            let end_id = getGestureId(index: RecordingViewController.recording_end)
            if (StylusManager.liveStatus()) {
                StylusManager.setToRecording(idStart: start_id, idEnd: end_id)
            } else { //stop recording
                StylusManager.setToLive()
                //clear selection
                resetSelection()
            }
        }
    }
    
    func recordingCreatedHandler (data:(String, StylusRecordingPackage), key:String) {
        let stylusdata = data.1
        RecordingViewController.gestures.append(GestureRecording(id: stylusdata.id, resultantStrokes: stylusdata.resultantStrokes))
        let IndexPath = NSIndexPath(item: RecordingViewController.gestures.count-1, section:0)
        collectionView?.insertItems(at: [IndexPath as IndexPath])
        collectionView?.scrollToItem(at: IndexPath as IndexPath, at: UICollectionViewScrollPosition.right, animated: false)
    }

}

