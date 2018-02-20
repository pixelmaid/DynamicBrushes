//
//  RecordingFrameCell.swift
//  DynamicBrushes
//
//  Created by Jingyi Li on 2/6/18.
//  Copyright © 2018 pixelmaid. All rights reserved.
//

import Foundation
import UIKit

class RecordingFrameCell: UICollectionViewCell {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        print ("^^ in init cell1")
        initCell()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        print ("^^ cell reused")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        print ("^^ in init cell2")
        initCell()
    }
    
    func initCell() {
//            self.itemSize = CGSize(width: 200, height: 150)
//        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height))
//        imageView.backgroundColor = UIColor.blue
//        imageView.contentMode = UIViewContentMode.scaleAspectFit
//        let gestureIdx = RecordingViewController.gestures.count //tag starts at 1
//        imageView.tag = gestureIdx
//        contentView.addSubview(imageView)
//        print ("^^ == init added img ", imageView.tag)
    }
}
