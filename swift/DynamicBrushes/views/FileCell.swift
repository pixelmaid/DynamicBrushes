//
//  FileCell.swift
//  DynamicBrushes
//
//  Created by JENNIFER MARY JACOBS on 5/22/17.
//  Copyright © 2017 pixelmaid. All rights reserved.
//

import Foundation
//
//  LayerCell.swift
//  DynamicBrushes
//
//  Created by JENNIFER MARY JACOBS on 5/18/17.
//  Copyright © 2017 pixelmaid. All rights reserved.
//

import Foundation
import UIKit

class FileCell: UITableViewCell {
    
    //MARK: properties
    
    
    
    @IBOutlet weak var label: UILabel!
    
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
