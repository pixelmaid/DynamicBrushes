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
    
    
    func drawIntoContext(context: BrushGraphicsView, brushInfo:BrushStateStorage,stylusInfo:(Double,Double,Double,Double,Double,Int)){
        let ix = stylusInfo.0
        let iy = stylusInfo.1
        let idx = stylusInfo.2
        let idy = stylusInfo.3
        let force = stylusInfo.4
        let state = stylusInfo.5 // 2- pen down, 0 - pen up
       // print("## drawing into context for brush ", self.id, " state is ", state  )

        let active = context.scene!.checkActiveId(id: self.id)
        //first, check if brush is already active
        if active {
            //update locations
            //x, y are brush dot
            //cx, cy are output dot
            // are input dot
            context.scene!.updateBrush(id:self.id, r: brushInfo.rotation, dx: brushInfo.dx, dy:brushInfo.dy, x: brushInfo.x, y:brushInfo.y, cx: brushInfo.cx, cy:brushInfo.cy, ox: brushInfo.ox, oy: brushInfo.oy, sx: brushInfo.sx, sy: brushInfo.sy, ix:ix, iy:iy, idx:idx, idy:idy, force:force, state:state)
        } else {
            //create new, add to active ids
            context.scene!.addBrushGraphic(id:self.id, ox:self.params.ox, oy:self.params.oy, r: self.params.rotation,
                                           x: self.params.x, y:self.params.y, cx: self.params.cx, cy:self.params.cy, ix:ix, iy:iy)
        }
        if Debugger.toDrawPenDown {
            context.scene!.movePenDown(x: ix, y: iy, lastX: Debugger.lastPointX, lastY: Debugger.lastPointY)
            Debugger.toDrawPenDown = false
        }

        if state == 2 || (state == 1 && Debugger.lastState == 0) {
            Debugger.toDrawPenDown = true //queue for next one
            context.scene!.clearStreams()

        } else if state == 0 && Debugger.lastState == 1 {
            context.scene!.movePenUp(x: ix, y: iy, lastX: Debugger.lastPointX, lastY: Debugger.lastPointY)
        }
        
        context.updateNode()
        self.unrendered = false;
        Debugger.lastState = state
        Debugger.lastPointX = ix
        Debugger.lastPointY = iy
//        print("~~~ draw into context called")
    }
    
    //to do - remove brush visualizations
    
}

protocol Renderable{
    
   var unrendered:Bool {get set}
}
