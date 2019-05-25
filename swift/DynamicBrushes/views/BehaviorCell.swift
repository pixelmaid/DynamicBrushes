//
//  BehaviorCell.swift
//  DynamicBrushes
//
//  Created by JENNIFER MARY JACOBS on 6/5/17.
//  Copyright © 2017 pixelmaid. All rights reserved.
//


import Foundation
import UIKit

class BehaviorCell: UITableViewCell {
    
    //MARK: properties
    
    @IBOutlet weak var refreshButton: UIButton!
    
    @IBOutlet weak var activateButton: UIButton!
    
    @IBOutlet weak var label: UILabel!
    
    
    var active = true;
    var id: String!
    var name: String!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        // strokeImage = CanvasView(frame: CGRectMake(0,0,90,90));
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        // strokeImage = CanvasView(frame: CGRectMake(0,0,90,90));
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // strokeImage.backgroundColor = UIColor.blueColor();
        // self.addSubview(strokeImage)
        // Initialization code
    }
    
    
    
    func modeClicked(){
        
    }
    
}
