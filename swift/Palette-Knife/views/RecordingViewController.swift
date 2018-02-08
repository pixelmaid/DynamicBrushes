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
    init(id:String, resultantStrokes:[String:[String]]) {
        self.id = id;
        self.resultantStrokes = resultantStrokes;
    }
}

class RecordingViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet var collectionView: UICollectionView!
    
    let recordingKey = NSUUID().uuidString
    var gestures = [GestureRecording]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        _ = StylusManager.recordEvent.addHandler(target:self, handler: RecordingViewController.recordingCreatedHandler, key: recordingKey)
        collectionView?.register(RecordingFrameCell.self, forCellWithReuseIdentifier: "cell")
        
        self.gestures.append(GestureRecording(id:"hi", resultantStrokes:["":[""]]))
        self.gestures.append(GestureRecording(id:"test", resultantStrokes:["":[""]]))
        self.gestures.append(GestureRecording(id:"test2", resultantStrokes:["":[""]]))
        self.gestures.append(GestureRecording(id:"test3", resultantStrokes:["":[""]]))
        self.gestures.append(GestureRecording(id:"test4", resultantStrokes:["":[""]]))

        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.gestures.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RecordingFrameCell", for: indexPath) as! RecordingFrameCell
//        cell.recordingThumbnail.image =
        print ("*** RECORDING MADE NEW FRAME")

        cell.backgroundColor = UIColor.blue
        return cell
    }
    
//    
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        return CGSize(width: 400, height: 200)
//    }
    
    func recordingCreatedHandler (data:(String, StylusRecordingPackage), key:String) {
        //get data here
        print ("****** RECORDING NEW DATA!")
        let stylusdata = data.1
        self.gestures.append(GestureRecording(id: stylusdata.id, resultantStrokes: stylusdata.resultantStrokes))
        print (self.gestures.count-1)
        let IndexPath = NSIndexPath(item: self.gestures.count-1, section:0)
        print (IndexPath)
        self.collectionView?.insertItems(at: [IndexPath as IndexPath])
        print ("recording tried inserting")
        print ("recording gestures len", self.gestures.count)
        self.collectionView?.reloadData()
    }

}

