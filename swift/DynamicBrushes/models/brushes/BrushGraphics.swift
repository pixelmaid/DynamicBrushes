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
       // print("## drawing into context for brush ", self.id, " state is ", state  )

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
                                           x: self.params.x, y:self.params.y, cx: self.params.cx, cy:self.params.cy, ix:ix, iy:iy )
        }

        if state == 2 || (state == 1 && Debugger.lastState == 0) {
            Debugger.toDrawPenDown = true //queue for next one
        } else if state == 0 && Debugger.lastState == 1 {
            Debugger.toDrawPenUp = true
        }
        
        if Debugger.toDrawPenDown {
            context.scene!.movePenDown(x: ix, y: iy, lastX: Debugger.lastPointX, lastY: Debugger.lastPointY)
            Debugger.toDrawPenDown = false
        }
        if Debugger.toDrawPenUp  {
            context.scene!.movePenUp(x: ix, y: iy, lastX: Debugger.lastPointX, lastY: Debugger.lastPointY)
            Debugger.toDrawPenUp = false
        }
        
        context.updateNode()
        self.unrendered = false;
        Debugger.lastState = state
        Debugger.lastPointX = ix
        Debugger.lastPointY = iy
    }
    
    //to do - remove brush visualizations
    
}

protocol Renderable{
    
   var unrendered:Bool {get set}
}
