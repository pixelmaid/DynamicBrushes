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
    
    
    func drawIntoContext(context: BrushGraphicsView, info:(Double,Double,Double,Int)){
        let ix = info.0
        let iy = info.1
        let force = info.2
        let state = info.3 // 2- pen down, 0 - pen up
        print("## drawing into context for brush ", self.id, " state is ", state  )

        let active = context.scene!.checkActiveId(id: self.id)
        //first, check if brush is already active
        if active {
            //update locations
            //x, y are brush dot
            //cx, cy are output dot
            // are input dot
            context.scene!.updateBrush(id:self.id, r: self.params.rotation, x: self.params.x, y:self.params.y,
                                       cx: self.params.cx, cy:self.params.cy, ox: self.params.ox, oy: self.params.oy,
                                       sx: self.params.sx, sy: self.params.sy, ix:ix, iy:iy, force:force, state:state)
        } else {
            //create new, add to active ids
            context.scene!.addBrushGraphic(id:self.id, ox:self.params.ox, oy:self.params.oy, r: self.params.rotation,
                                          x: self.params.x, y:self.params.y, cx: self.params.cx, cy:self.params.cy )
        }
        if state == 2 || (state == 1 && Debugger.lastState == 0) {
            context.scene!.movePenDown(x: ix, y: iy)
        } else if state == 0  {
            context.scene!.movePenUp(x: ix, y: iy)
        }
        context.updateNode()
        self.unrendered = false;
        Debugger.lastState = state
    }
    
    //to do - remove brush visualizations
    
}

protocol Renderable{
    
   var unrendered:Bool {get set}
}
