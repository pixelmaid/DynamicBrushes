//
//  RecordingViewController.swift
//  DynamicBrushes
//
//  Created by Jingyi Li on 2/5/18.
//  Copyright © 2018 pixelmaid. All rights reserved.
//

import Foundation
import UIKit

class RecordingViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet var collectionView: UICollectionView!
    let recordingKey = NSUUID().uuidString
    
    var strokes = [String]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        strokes = ["1", "2", "3", "4", "5"]
        _ = StylusManager.recordEvent.addHandler(target:self, handler: RecordingViewController.recordingCreatedHandler, key: recordingKey)

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return strokes.count
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
        print (data)
    }

}

