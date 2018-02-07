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
    
    private let cellReuseID = "cell"

    
    override func viewDidLoad() {
        super.viewDidLoad()
        //collectionView?.register(RecordingFrameCell.self, forCellWithReuseIdentifier: cellReuseID)
        //collectionView?.delegate = self
        //collectionView?.dataSource = self
        //collectionView?.backgroundColor = UIColor.cyan;
        
//        var layout = UICollectionViewFlowLayout()
//        layout.scrollDirection = .horizontal
//        let screenWidth = UIScreen.main.bounds.width
//        collectionView?.contentSize = CGSize(width: screenWidth, height: 220)
//
        strokes = ["1", "2", "3", "4"]
       // _ = StylusManager.recordEvent.addHandler(target:self, handler: RecordingViewController.RecordingCreatedHandler, key: recordingKey)

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
        cell.backgroundColor = UIColor.blue
        print("cell inflate")
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 400, height: 200)
    }
    
    func RecordingCreatedHandler (data:(String, StylusRecordingPackage), key:String) {
        //get data here
    }

}

