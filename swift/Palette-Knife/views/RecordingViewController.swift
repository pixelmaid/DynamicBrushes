//
//  RecordingViewController.swift
//  DynamicBrushes
//
//  Created by Jingyi Li on 2/5/18.
//  Copyright © 2018 pixelmaid. All rights reserved.
//

import Foundation
import UIKit

class RecordingViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    var strokes = [String]()
//    @IBOutlet weak var frame: UICollectionViewCell!

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView?.register(RecordingFrameCell.self, forCellWithReuseIdentifier: "cell")
        
        strokes = ["1", "2", "3", "1", "2", "3", "1", "2", "3"]
//        collectionView?.register(UICollectionViewCell.self, forCellWithReuseIdentifier: frame)
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return strokes.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! UICollectionViewCell
        cell.backgroundColor = UIColor.blue
        return cell
    }

}

