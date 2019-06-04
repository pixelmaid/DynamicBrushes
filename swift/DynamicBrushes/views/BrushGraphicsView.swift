//
//  BrushGraphicsView.swift
//  DynamicBrushes
//
//  Created by Jingyi Li on 5/22/19.
//  Copyright © 2019 pixelmaid. All rights reserved.
//

import Foundation
import Macaw

public class BrushGraphicsScene {
    //a brush graphics scene contains brushgraphics (one for each active brush)
    let view: BrushGraphicsView
    var brushes = [BrushGraphic]()
    var node: Group
    var activeBrushIds = [String]()
    
    init(view: BrushGraphicsView) {
        self.view = view
        self.node = Group()
    }

    public func addBrushGraphic(id:String, ox:Float, oy:Float, r: Float,
                         x: Float, y:Float, cx: Float, cy:Float ) {
        //add to id, create new class
        self.activeBrushIds.append(id)
        let brushGraphic = BrushGraphic(view:self.view, scene:self, id:id, ox:ox, oy:oy, r:r, x:x, y:y, cx:cx, cy:cy)
        brushes.append(brushGraphic)
    }
    
    public func updateBrush(id:String, r: Float, x: Float, y: Float, cx: Float, cy: Float) {
        for brush in brushes {
            if brush.id == id {
                print("updating brush with id ", id)
                brush.rotateBrushIcon(r: r)
                brush.moveComputedLocation(cx: cx, cy: cy)
                brush.moveInputLocation(x: x, y: y)
            }
        }
    }
    
    public func checkActiveId(id:String) -> Bool {
        if self.activeBrushIds.contains(id) {
            return true;
        }
        return false;
    }
    
    
    public func removeActiveId(id:String) {
        activeBrushIds = activeBrushIds.filter {$0 != id}
    }
    
}

class BrushGraphic {
    //a brush graphic is the atomic unit of a brush graphics scene
    //contains rotation brush icon, and drawing/stylus icons
    
    let view: BrushGraphicsView
    let scene: BrushGraphicsScene
    
    var node: Group
    let brushIcon: Shape
    let inputIcon: Shape
    let computedIcon: Shape
    
    let id: String
    var ox: Float
    var oy: Float
    var r: Float
    var x: Float
    var y: Float
    var cx: Float
    var cy: Float
    
    init(view:BrushGraphicsView, scene:BrushGraphicsScene, id:String, ox:Float, oy:Float, r: Float, x: Float, y:Float,
         cx: Float, cy:Float ) {
        self.id = id
        self.view = view
        self.scene = scene
        self.ox = ox
        self.oy = oy
        self.r = r
        self.x = x
        self.y = y
        self.cx = cx
        self.cy = cy
        
        //add to scene
        
        //init brush icon
        node = Group()
        brushIcon = Shape (form: Polygon(points: [0,0,100,50,0,100,25,50]),
                           fill: Macaw.Color.rgba(r: 0, g: 255, b: 255, a: 128))
        brushIcon.place = Transform.scale(sx:0.4, sy:0.4)
        brushIcon.place = Transform.move(dx:Double(self.ox),dy:Double(self.oy))
        node.contents.append(brushIcon)
        
        //init inputicon
        inputIcon = Shape(form: Circle(r: 10), fill: Macaw.Color.rgba(r:0, g: 255, b:255, a:200))
        inputIcon.place = Transform.move(dx:Double(self.x), dy:Double(self.y))
        node.contents.append(inputIcon)
        
        //init computedicon
        computedIcon = Shape(form: Circle(r: 10), fill: Macaw.Color.rgba(r:125, g: 0, b:255, a:200))
        computedIcon.place = Transform.move(dx:Double(self.cx), dy:Double(self.cy))
        node.contents.append(computedIcon)
        
        print("!! init icons for brush ", id)
        self.addToScene()
    }
    
    func addToScene() {
        self.scene.node.contents.append(self.node)
    }
    
    func removeFromScene() {
        //uhhh todo
    }
    
    func rotateBrushIcon(r: Float) {
        brushIcon.place = Transform.rotate(angle:Double(r * Float.pi / 180), x:Double(self.ox), y:Double(self.oy))
        print("rotated brush ", self.id, " by ", r)
    }
    
    func moveInputLocation(x: Float, y: Float) {
        inputIcon.place = Transform.move(dx: Double(self.x - x), dy: Double(self.y - y))
        self.x = x
        self.y = y
        print("moved brush" , self.id, " to x ,y,", x, y )
    }
    
    func moveComputedLocation(cx: Float, cy: Float) {
        computedIcon.place = Transform.move(dx: Double(self.cx - cx), dy: Double(self.cy - cy))
        self.cx = x
        self.cy = y
        print("moved computed" , self.id, "to cx cy" , cx, cy)
    }
    
}

class BrushGraphicsView: MacawView {
    //overall container
    var scene: BrushGraphicsScene?
  
    override init(frame: CGRect) {
        super.init(frame: frame);
        self.backgroundColor =  UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.0)
        self.updateNode()
    }
    
    required init?(coder aDecoder: NSCoder) {
        //this is dummy, it's never called but we need it
        let brushIcon = Shape (form: Polygon(points: [0,0,100,50,0,100,25,50]),
                               fill: Macaw.Color.rgba(r:0, g:0, b:0, a:100))
        super.init(node: Group(contents:[brushIcon]), coder: aDecoder)
    }
    
    func updateNode() {
        let scene = BrushGraphicsScene(view:self) //making this every time..?
        let node = scene.node
        self.scene = scene
        self.node = node
        print("called update node in graphics view")
    }
    
}
