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
    var gestures = [GestureRecording]()
    //selection handling
    var recording_start = Int.max
    var recording_end = -1
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var exportRecording: UIButton!
    @IBOutlet weak var loopRecording: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let recordingKey = NSUUID().uuidString
         collectionView?.allowsMultipleSelection = true
        _ = StylusManager.recordEvent.addHandler(target:self, handler: RecordingViewController.recordingCreatedHandler, key: recordingKey)
        collectionView?.register(RecordingFrameCell.self, forCellWithReuseIdentifier: "cell")
        loopRecording.addTarget(self, action: #selector(RecordingViewController.loopInitialized), for: .touchUpInside)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return gestures.count
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
        if idx < recording_start {
            recording_start = idx
        }
        if idx > recording_end {
            recording_end = idx
        }
        highlightCells(start: recording_start, end: recording_end)
    }
    
    //if click on any cell in range, deselect range
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        print("^^ recording deselected index", indexPath[1])
        resetSelection()
    }
    
    func highlightCells(start:Int, end:Int) {
        print("^^ highlighting from", start, " to ", end+1)
        for i in stride(from:start, to:end+1, by:1) {
            let indexPath = NSIndexPath(item:i, section:0)
            let cell = collectionView?.cellForItem(at: indexPath as IndexPath)
            cell?.layer.borderWidth = 4.0
            cell?.layer.borderColor = UIColor.green.cgColor
            collectionView?.selectItem(at: indexPath as IndexPath, animated: false, scrollPosition: [])
        }
    }
    
    func resetSelection() {
        print ("^^ reseting selection")
        for i in stride(from:recording_start, to:recording_end+1, by:1) {
            let indexPath = NSIndexPath(item:i, section:0)
            let cell = collectionView?.cellForItem(at: indexPath as IndexPath)
            cell?.layer.borderWidth = 0.0
            collectionView?.deselectItem(at: indexPath as IndexPath, animated: false)
        }
        recording_start = Int.max
        recording_end = -1
    }

    //from an index, go to a gesture stringid
    func getGestureId(index:Int) -> String {
        return gestures[index].id
    }
    
    func loopInitialized() {
        print ("^^ going to loop from ", recording_start, " to ", recording_end)
        let start_id = getGestureId(index: recording_start)
        let end_id = getGestureId(index: recording_end)
        StylusManager.setToRecording(idStart: start_id, idEnd: end_id)
    }
    
    func recordingCreatedHandler (data:(String, StylusRecordingPackage), key:String) {
        let stylusdata = data.1
        gestures.append(GestureRecording(id: stylusdata.id, resultantStrokes: stylusdata.resultantStrokes))
        let IndexPath = NSIndexPath(item: self.gestures.count-1, section:0)
        collectionView?.insertItems(at: [IndexPath as IndexPath])
        collectionView?.scrollToItem(at: IndexPath as IndexPath, at: UICollectionViewScrollPosition.right, animated: false)
    }

}

