//
//  BrushGraphics.swift
//  DynamicBrushes
//
//  Created by JENNIFER  JACOBS on 5/20/19.
//  Copyright © 2019 pixelmaid. All rights reserved.
//

import Foundation
import Macaw

extension Brush {
    
    
    
    func drawIntoContext(context: BrushGraphicsView, info:(Double,Double,Double)){
        let ix = info.0
        let iy = info.1
        let force = info.2
        let active = context.scene!.checkActiveId(id: self.id)
        //first, check if brush is already active
        if active {
            //update locations
            //x, y are brush dot
            //cx, cy are output dot
            // are input dot
            context.scene!.updateBrush(id:self.id, r: self.params.rotation, x: self.params.x, y:self.params.y,
                                       cx: self.params.cx, cy:self.params.cy, ox: self.params.ox, oy: self.params.oy,
                                       sx: self.params.sx, sy: self.params.sy, ix:ix, iy:iy, force:force)
        } else {
            //create new, add to active ids
            context.scene!.addBrushGraphic(id:self.id, ox:self.params.ox, oy:self.params.oy, r: self.params.rotation,
                                          x: self.params.x, y:self.params.y, cx: self.params.cx, cy:self.params.cy )
        }
        context.updateNode()
        self.unrendered = false;
    }
    
    //to do - remove brush visualizations
    
}

protocol Renderable{
    
   var unrendered:Bool {get set}
}
