//
//  BrushGraphicsView.swift
//  DynamicBrushes
//
//  Created by Jingyi Li on 5/22/19.
//  Copyright © 2019 pixelmaid. All rights reserved.
//

import Foundation
import Macaw

class BrushGraphicsView: MacawView {
    
    var activeBrushes = {}; //dictionary containing brush ids to group (origin, brush, output)
    // i guess everything goes through this data structure?
    
    
    required init?(coder aDecoder: NSCoder) {
        //make a container for shapes
        let shape = Shape(form: Polygon(points: [250, 100, 300, 150, 200, 150]),
                          fill: Macaw.Color(val: 0xfcc07c))
        super.init(node: shape, coder: aDecoder)
    }
    
    public func drawBrush(id:String, params:DeltaStorage) {
        print("drawing brush")
        //control flow
//        if not in activeBrushes: add
//        else (active):
//           update Brush
        //q - when to delete brush?
        
    }
    
    func initBrush(id:String, x:Double, y:Double) {
        //append to shape container
        //move to origin
        //draw dot on x,y
        //draw dot on cx,cy
    }
    
    func destroyBrush(id:String){
        //remove from shape container
    }
    
    func updateBrush(id:String, params:DeltaStorage) {
        //animate rotate around origin
        // animated to new positions
    }
}
