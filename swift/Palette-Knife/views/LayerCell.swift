//
//  LayerCell.swift
//  DynamicBrushes
//
//  Created by JENNIFER MARY JACOBS on 5/18/17.
//  Copyright © 2017 pixelmaid. All rights reserved.
//

import Foundation
import UIKit

class LayerCell: UITableViewCell {
    
    //MARK: properties
    

    @IBOutlet weak var layerLabel: UILabel!
    @IBOutlet weak var layerVisibleButton: UIButton!
    @IBOutlet weak var layerThumbnail: UIImageView!
    @IBOutlet weak var deleteLayerButton: UIButton!
    
    var visible = true;
    
    var id: String!
    var name: String!

    let brushStandard = UIImage(named: "brush_button2x")

    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
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
