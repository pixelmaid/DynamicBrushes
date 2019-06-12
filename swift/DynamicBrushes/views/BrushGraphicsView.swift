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
        print("## (2) init BG scene")
    }

    public func addBrushGraphic(id:String, ox:Float, oy:Float, r: Float,
                         x: Float, y:Float, cx: Float, cy:Float ) {
        //add to id, create new class
        self.activeBrushIds.append(id)
        let brushGraphic = BrushGraphic(view:self.view, scene:self, id:id, ox:ox, oy:oy, r:r, x:x, y:y, cx:cx, cy:cy)
        brushes.append(brushGraphic)
    }
    
    public func updateBrush(id:String, r: Float, x: Float, y: Float, cx: Float, cy: Float, ox: Float, oy: Float) {
        for brush in brushes {
            if brush.id == id {
                print("## updating brush with id ", id)
                brush.updateBrushIcon(r:r, ox: ox, oy: oy)
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
    let brushIcon: Group
    let inputIcon: Shape
    let computedIcon: Shape
    let originText: Text
    let inputText: Text
    let computedText: Text
    
    let id: String
    var ox: Float
    var oy: Float
    var r: Float
    var x: Float
    var y: Float
    var cx: Float
    var cy: Float
    
    let ox_offset:Double = 15
    let oy_offset:Double = 15
    
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
        
        let brushColor = Macaw.Color.rgba(r: 2, g:196, b:239, a: 63)
        let outputColor = Macaw.Color.rgba(r: 180, g: 5, b: 255, a: 63)


        //init brush icon
        node = Group()
        
//        let rotationIndicator = Shape (form: Polygon(points: [0,0,50,25,0,50,13,25]), fill: brushColor)
        let rotationIndicator = Shape (form: Polygon(points: [30,0,35,15,30,30]), fill: brushColor)
        let originIndicator = Group(contents: [Macaw.Line(x1: 0, y1: 15, x2: 30, y2: 15).stroke(fill: brushColor, width: 2), Macaw.Line(x1: 15, y1: 0, x2: 15, y2: 30).stroke(fill: brushColor, width: 2)])
        originText = BrushGraphic.newText("ox: 0, oy: 0, r: 0", Transform.move(dx:21,dy:45))
        
        brushIcon = Group(contents: [rotationIndicator, originIndicator])
        brushIcon.place = Transform.move(dx:Double(self.ox) - ox_offset,dy:Double(self.oy) - oy_offset)
        node.contents.append(brushIcon)
        node.contents.append(originText)
        print("## init brush icon for brush ", id, " at " , self.ox, self.oy)

        
        //init inputicon
        inputIcon = Shape(form: Circle(r: 10), fill: brushColor, stroke: Macaw.Stroke(fill: Macaw.Color.white, width:2))
        inputIcon.place = Transform.move(dx:Double(self.x), dy:Double(self.y))
        node.contents.append(inputIcon)
        inputText = BrushGraphic.newText("pos x: 0, pos y: 0", Transform.move(dx:0,dy:10))
        node.contents.append(inputText)
        print("## init input icon for brush ", id, " at " , self.x, self.y)

        //init computedicon
        computedIcon = Shape(form: Circle(r: 10), fill: outputColor, stroke: Macaw.Stroke(fill: Macaw.Color.white, width:2))
        computedIcon.place = Transform.move(dx:Double(self.cx), dy:Double(self.cy))
        node.contents.append(computedIcon)
        computedText = BrushGraphic.newText("abs x: 0, abs y: 0", Transform.move(dx:0,dy:20))
        node.contents.append(computedText)
        print("## init computed icon for brush ", id, " at " , self.cx, self.cy)

        
        self.addToScene()
    }
    
    static func newText(_ text: String, _ place: Transform, baseline: Baseline = .bottom) -> Text {
        return Text(text: text, fill: Macaw.Color.black, align: .mid, baseline: baseline, place: place)
    }
    
    func addToScene() {
        self.scene.node.contents.append(self.node)
    }
    
    func removeFromScene() {
        //uhhh todo
    }
    
    func updateBrushIcon(r: Float, ox:Float, oy:Float) {
        brushIcon.place = Transform.rotate(angle:Double(r * Float.pi / 180), x:Double(ox), y:Double(oy)).move(dx: Double(ox) - ox_offset, dy: Double(oy) - oy_offset)
        originText.place = Transform.move(dx: Double(ox), dy: Double(oy) - Double(20))
        self.ox = ox
        self.oy = oy
        self.r = r
        originText.text = "ox: "+String(Int(ox))+", oy: "+String(Int(oy))+", r: "+String(Int(r))
        print("## rotated brush ", self.id, " by ", r, " Moved to ox ,oy,", ox, oy )
    }
    
    func moveInputLocation(x: Float, y: Float) {
        inputIcon.place = Transform.move(dx: Double(x), dy: Double(y)) //need this offset for some reason?
        self.x = x
        self.y = y
        inputText.text = "pos x: "+String(Int(x))+", pos y: "+String(Int(y))
        inputText.place = Transform.move(dx: Double(x), dy: Double(y) - Double(20))

        print("## moved input" , self.id, " to x ,y,", x, y )
    }
    
    func moveComputedLocation(cx: Float, cy: Float) {
        computedIcon.place = Transform.move(dx: Double(cx), dy: Double(cy))
        self.cx = cx
        self.cy = cy
        computedText.text = "abs x: "+String(Int(cx))+", abs y: "+String(Int(cy))
        computedText.place = Transform.move(dx: Double(cx), dy: Double(cy) + Double(30))

        print("## moved computed" , self.id, "to cx cy" , cx, cy)
    }
    
}

class BrushGraphicsView: MacawView {
    //overall container
    var scene: BrushGraphicsScene?
  
    override init(frame: CGRect) {
        super.init(frame: frame);
        self.backgroundColor =  UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.0)
        print("## (1) initialized BG view")
        scene = BrushGraphicsScene(view:self)
        self.updateNode()
    }
    
    required init?(coder aDecoder: NSCoder) {
        //this is dummy, it's never called but we need it
        let brushIcon = Shape (form: Polygon(points: [0,0,100,50,0,100,25,50]),
                               fill: Macaw.Color.rgba(r:0, g:0, b:0, a:100))
        super.init(node: Group(contents:[brushIcon]), coder: aDecoder)
    }
    
    func updateNode() {
        let node = scene?.node
        self.node = node!
        print("## called update node in graphics view", self.node)
    }
    
}
