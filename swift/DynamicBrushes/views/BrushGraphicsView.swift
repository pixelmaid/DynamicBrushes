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
    var node: Group
    var activeBrushIds = [String:BrushGraphic]() //dictionary
    var currentGenerator = ["none"]
    var lastPoint:(Float,Float) = (0.0, 0.0)
    
    //highlight vars for persistence
    var stylusOn = false
    var forceOn = false
    var originOn = false
    var rotationOn = false
    var scaleXOn = false
    var scaleYOn = false
    var brushOn = false
    var outputOn = false
    var generatorOn = false
    var generatorOnName = ""
    
    let eraseEventKey = NSUUID().uuidString
    
    init(view: BrushGraphicsView) {
        self.view = view
        self.node = Group()
        print("## (2) init BG scene")
        _ = stylusManager.visualizationEvent.addHandler(target: self, handler: BrushGraphicsScene.eraseEventHandler, key: eraseEventKey)

    }
    
    func eraseEventHandler(data:String, key:String){
        if data == "ERASE_REQUEST" {
            print("~~~~!! erase request")
            for (_, brush) in self.activeBrushIds {
                brush.stylusStream.contents = []
                brush.brushStream.contents = []
                brush.outputStream.contents = []

            }
        }
    }
    
    public func clearStreams() {
        for (_, brush) in self.activeBrushIds {
            brush.stylusStream.contents = []
            brush.brushStream.contents = []
            brush.outputStream.contents = []
        }
    }
    
    public func toggleViz(type: String) {
        for (_, brush) in self.activeBrushIds {
            brush.toggleViz(type: type)
        }
    }
    public func toggleLabel(type: String) {
        for (_, brush) in self.activeBrushIds {
            brush.toggleLabel(type: type)
        }
    }

    public func addBrushGraphic(id:String, ox:Float, oy:Float, r: Float,
                                x: Float, y:Float, cx: Float, cy:Float, ix:Double, iy:Double) {
        //add to id, create new class
        let brushGraphic = BrushGraphic(view:self.view, scene:self, id:id, ox:ox, oy:oy, r:r, x:x, y:y, cx:cx, cy:cy, ix:ix, iy:iy)
        self.activeBrushIds[id] = brushGraphic //add to dict
    }
    
    public func updateBrush(id:String, r: Float, dx: Float, dy: Float, x:Float,y:Float,cx: Float, cy: Float, ox: Float, oy: Float, sx:Float, sy:Float, ix:Double, iy:Double, force:Double, state:Int) {
        for (_, brush) in self.activeBrushIds {
            if brush.id == id {
//                print("## updating brush with id ", id)
                brush.updateBrushIcon(r:r, ox: ox, oy: oy, sx:sx, sy:sy)
                brush.moveComputedLocation(cx: cx, cy: cy)
                brush.moveBrushLocation(x: x, y: y, dx:dx,dy:dy)
                brush.moveStylusLocation(x: ix, y: iy, force:force)
                self.lastPoint = (x, y)
                if state == 0 { //penDown
                    
                }
            }
        }
    }
    
    public func checkActiveId(id:String) -> Bool {
        if (self.activeBrushIds[id] != nil) {
            return true;
        }
        return false;
    }
    
    
    public func removeActiveId(id:String) {
        if let removedBrush = self.activeBrushIds.removeValue(forKey: id) {
            removedBrush.removeFromScene()
            print("## removed id ", id)
        }
    }
    
    public func checkCollisions(x: Float, y:Float) {
        var hit = ""
        for (_, brush) in self.activeBrushIds {
            hit = brush.checkCollision(x:x, y:y)
        }
        print("~~~ FINAL HIT WAS ", hit)
        switch (hit) {
        case "off":
            return;
            break;
        case "input":
            self.highlightViz(name: "param-styx", on: true)
            break;
        case "origin":
            self.highlightViz(name: "param-ox", on: true)
            break;
        case "scale-x":
            self.highlightViz(name: "param-sx", on: true)
            break;
        case "scale-y":
            self.highlightViz(name: "param-sy", on: true)
            break;
        case "rotation":
            self.highlightViz(name: "param-rotation", on: true)
            break;
        case "brush":
            self.highlightViz(name: "param-dx", on: true)
            break;
        case "output":
            self.highlightViz(name: "param-x", on: true)
            break;
        default:
            self.highlightViz(name: hit, on: true) //captures the generator cases
            break;
        }
        if hit == "" {
            print("~~clearing highlights")
            clearHighlights()
            Debugger.setupHighlightRequest(kind: "clear")
        } else {
            Debugger.setupHighlightRequest(kind: "clear")
            Debugger.setupHighlightRequest(kind: hit)
        }
    }
    
    func clearHighlights(){
        self.stylusOn = false
        self.forceOn = false
        self.originOn = false
        self.rotationOn = false
        self.scaleXOn = false
        self.scaleYOn = false
        self.brushOn = false
        self.outputOn = false
        self.generatorOn = false
        for (_, brush) in self.activeBrushIds{
            if Debugger.inputGfx {
                brush.unhighlightStylus()
                brush.unhighlightGenerator()
                brush.unhighlightForce()
            }
            if Debugger.brushGfx {
                brush.unhighlightOrigin()
                brush.unhighlightScaleX()
                brush.unhighlightScaleY()
                brush.unhighlightRotation()
                brush.unhighlightBrushIcon()
            }
            if Debugger.outputGfx {
                brush.unhighlightOutput()
            }
        }
    }
    
    public func highlightViz(name: String, on:Bool) {
        self.clearHighlights()
        print("!!~~ now finally in brush highlighting ", name, on)
        for (_, brush) in self.activeBrushIds {
            switch (name) {
            case "param-styx", "param-styy":
                if !Debugger.inputGfx { return }
                if on {
                    brush.highlightStylus()
                    self.stylusOn = true
                } else {
                    brush.unhighlightStylus()
                    self.stylusOn = false
                }
                break;
            case "param-force":
                if !Debugger.inputGfx { return }
                if on {
                    brush.highlightForce()
                    self.forceOn = true
                } else {
                    brush.unhighlightForce()
                    self.forceOn = false
                }
                break;
            case "gen-sawtooth":
                if !Debugger.inputGfx { return }
                if on {
                    brush.highlightGenerator(name:"sawtooth")
                    self.generatorOn = true
                    self.generatorOnName = "sawtooth"
                } else {
                    brush.unhighlightGenerator()
                    self.generatorOn = false
                }
                break;
            case "gen-square":
                if !Debugger.inputGfx { return }
                if on {
                    brush.highlightGenerator(name:"square")
                    self.generatorOn = true
                    self.generatorOnName = "square"
                } else {
                    brush.unhighlightGenerator()
                    self.generatorOn = false
                }
                break;
            case "gen-triangle":
                if !Debugger.inputGfx { return }
                if on {
                    brush.highlightGenerator(name:"triangle")
                    self.generatorOn = true
                    self.generatorOnName = "triangle"
                } else {
                    brush.unhighlightGenerator()
                    self.generatorOn = false
                }
                break;
            case "gen-sine":
                if !Debugger.inputGfx { return }
                if on {
                    brush.highlightGenerator(name:"sine")
                    self.generatorOnName = "sine"
                    self.generatorOn = true
                } else {
                    brush.unhighlightGenerator()
                    self.generatorOn = false
                }
                break;
            case "gen-random":
                if !Debugger.inputGfx { return }
                if on {
                    brush.highlightGenerator(name:"random")
                    self.generatorOnName = "random"
                    self.generatorOn = true
                } else {
                    brush.unhighlightGenerator()
                    self.generatorOn = false
                }
                break;
            case "param-ox", "param-oy":
                if !Debugger.brushGfx { return }
                if on {
                    brush.highlightOrigin()
                    self.originOn = true
                } else {
                    brush.unhighlightOrigin()
                    self.originOn = false
                }
                break;
            case "param-sx":
                if !Debugger.brushGfx { return }
                if on {
                    brush.highlightScaleX()
                    self.scaleXOn = true
                } else {
                    brush.unhighlightScaleX()
                    self.scaleXOn = false
                }
                break;
            case "param-sy":
                if !Debugger.brushGfx { return }
                if on {
                    brush.highlightScaleY()
                    self.scaleYOn = true
                } else {
                    brush.unhighlightScaleY()
                    self.scaleYOn = false
                }
                break;
            case "param-rotation":
                if !Debugger.brushGfx { return }
                if on {
                    brush.highlightRotation()
                    self.rotationOn = true
                } else {
                    brush.unhighlightRotation()
                    self.rotationOn = false
                }
                break;
            case "param-dx", "param-dy":
                if !Debugger.brushGfx { return }
                if on {
                    brush.highlightBrushIcon()
                    self.brushOn = true
                } else {
                    brush.unhighlightBrushIcon()
                    self.brushOn = false
                }
                break;
            case "param-x", "param-y":
                if !Debugger.outputGfx { return }
                if on {
                    brush.highlightOutput()
                    self.outputOn = true
                } else {
                    brush.unhighlightOutput()
                    self.outputOn = false
                }
                break;
            default:
                break;
            }
        }

    }
    
    public func movePenDown(x:Double, y:Double, lastX:Double, lastY:Double){
        for (_, brush) in self.activeBrushIds{
            var angle:Double
            let newX = x - lastX
            var newY = y - lastY
            print("diff for down is ~~~ ", newX, newY, " original ", x, y, " new ", lastX, lastY)
            if newY < 0 {
                print("~~ down neg")
//                newY = -newY
                angle = acos(newX / sqrt(pow(newX,2) + pow(newY,2)))*180/Double(pi)// + 180
            } else {
                angle = acos(newX / sqrt(pow(newX,2) + pow(newY,2)))*180/Double(pi)
            }
            brush.movePenDown(x:x, y:y, angle:angle)
            
        }
    }
    
    public func movePenUp(x:Double, y:Double, lastX:Double, lastY:Double){
        for (_, brush) in self.activeBrushIds{
            var angle:Double
            let newX = x - lastX
            var newY = y - lastY
            print("diff for up is ~~~ ", newX, newY, " original ", x, y, " new ", lastX, lastY)
            if newY < 0 {
                print("~~ up neg")
//                newY = -newY
                angle = acos(newX / sqrt(pow(newX,2) + pow(newY,2)))*180/Double(pi) //+ 180
            } else {
                angle = acos(newX / sqrt(pow(newX,2) + pow(newY,2)))*180/Double(pi)
            }
            brush.movePenUp(x:x, y:y, angle:angle)
        }
    }
    
    public func drawGenerator(valArray: [(Double, Int, String, Float )]) {
       //val array is value, time, type
//        print("~~~~ drawing generator, active brushIds are ", self.activeBrushIds.count)
        for (_, brush) in self.activeBrushIds {
            var newVals = [(Double, Int, String, Float)]()
            var seenTypes = [String]()
            for (v, t, type, freq) in valArray {
                if !seenTypes.contains(type) {
                    seenTypes.append(type)
                    newVals.append((v, t, type, freq))
                }
            }
        
            let numGenerators = newVals.count

//            print("~~~ total num UNIQUE active generators" , numGenerators, self.currentGenerator.count);
            let currCount = self.currentGenerator.count
            if numGenerators > currCount { //increase slots
                let diff = numGenerators - currCount
                for _ in 0...diff {
//                    print("~~~ total Adding!")
                    self.currentGenerator.append("none")
                }
            } else if numGenerators < currCount { //decrease slots
                let diff = currCount - numGenerators
                for _ in 0...diff {
                    if(self.currentGenerator.count>0){
                        self.currentGenerator.removeLast()
                    }
                }
            }
            
            //order result alphabetically
            let sortedValArray = newVals.sorted(by: {$0.2 < $1.2})
            var i:Int = 0;
//            print("~~~ total after change" , numGenerators, self.currentGenerator.count);

            for (value, time, type, freq) in sortedValArray {
                if i >= self.currentGenerator.count {
                    return
                }
                if type != self.currentGenerator[i] {
//                    print("~~ before type is ", self.currentGenerator[i])
                    brush.updateGeneratorKind(type: type, i:i, freq:freq)
                    self.currentGenerator[i] = type
//                    print("~~~ updated generator to ", type, i)
                }
                if type != "none" {
//                    print("~~~~~~ about to update dot for id ", brush.id, value, time, type, i)
                    brush.updateGeneratorDot(v: value, t: time, type:type, i:i, freq:freq)
                }
                i += 1
            }
        }
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
    var lastStylusInputs = Group()
    var stylusStream = Group()
    var brushStream = Group()
    var outputStream = Group()
    let streamLimit = 10
    let inputLimit = 10
    let computedIcon: Shape
    let stylusIcon: Shape
    let xAxis: Group
    let yAxis: Group
    let stylusDownIcon: Shape
    let stylusUpIcon: Shape
    
    let stylusText: Group
    let originText: Group
    let inputText: Group
    let computedText: Group //0 text 1 bg
    
    let generator: Group
    
    let id: String
    var ox: Float
    var oy: Float
    var r: Float
    var x: Float
    var y: Float
    var cx: Float
    var cy: Float
    var ix: Double
    var iy: Double
    
    let oxOffset:Double = 0
    let oyOffset:Double = 0
    
    let axisScale:Double = 15
    let axisLen:Double = 50
    var scaleChanged = false
    
    let inputColor = Macaw.Color.rgba(r: 74, g:137, b:235, a: 63)
    let lighterInputColor = Macaw.Color.rgba(r: 74, g:137, b:235, a: 200)
    let brushColor = Macaw.Color.rgba(r: 255, g:53, b:95, a: 63)
    let outputColor = Macaw.Color.rgba(r: 134, g: 73, b: 180, a: 63)
    let hiddenColor = Macaw.Color.rgba(r:255,g:255,b:255,a:0)
    let highlightColor = Macaw.Color.rgba(r:0,g:255,b:0,a:63)
    let labelColor = Macaw.Color.rgba(r:255,g:255,b:255,a:128)

    let empty = Shape(form: Circle(r:1), fill: Macaw.Color.rgba(r:0,g:0,b:0,a:0))

    
    init(view:BrushGraphicsView, scene:BrushGraphicsScene, id:String, ox:Float, oy:Float, r: Float, x: Float, y:Float,
         cx: Float, cy:Float, ix:Double, iy:Double ) {
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
        self.ix = ix
        self.iy = iy
        
        //add to scene


        //init brush icon
        node = Group()
        

        //init stylusicon
        node.contents.append(lastStylusInputs)
        stylusIcon = Shape(form: Circle(r: 10), fill: inputColor, stroke: Macaw.Stroke(fill: Macaw.Color.white, width:2))
        stylusIcon.place = Transform.move(dx:ix, dy:iy)
        node.contents.append(stylusIcon)

        let stylusTextContent = BrushGraphic.newText("stylus x: 0, stylus y: 0", Transform.move(dx:0,dy:10))
        let stylusTextBg = Shape(form: Rect(x:-90, y:-9, w:180, h:20), fill:labelColor)
        stylusText = Group(contents:[stylusTextBg, stylusTextContent])
        
        let inputScale = 10.0
        stylusUpIcon = Polygon(points:[0, -inputScale, inputScale, 0, 0, inputScale]).fill(with: inputColor)
        stylusDownIcon = Polygon(points:[-inputScale*0.5, -inputScale, 0, -inputScale, inputScale, 0, 0, inputScale, -inputScale*0.5, inputScale, 0, 0]).fill(with: inputColor)
//        stylusDownIcon.place = Transform.move(dx:500,dy:500)
//        stylusUpIcon.place = Transform.move(dx:800,dy:500)
        node.contents.append(stylusUpIcon)
        node.contents.append(stylusDownIcon)
        node.contents.append(stylusStream)

        //init reified brush
        let xLine = Shape(form: Macaw.Line(x1: axisScale, y1: 0, x2: axisScale+axisLen, y2:0), stroke: Macaw.Stroke(fill:brushColor, width:2))
        let yLine = Macaw.Line(x1: 0, y1: axisScale, x2: 0, y2:axisScale+axisLen).stroke(fill:brushColor, width:2)
        let triScale = axisScale*0.25
        let xTriangle = Polygon(points:[0, -triScale, -triScale*sqrt(3), 0, 0, triScale]).fill(with: brushColor)
        xTriangle.place = Transform.move(dx:axisScale+axisLen, dy:0).rotate(angle:Double(pi))
        let yTriangle = Polygon(points:[0, -triScale, -triScale*sqrt(3), 0, 0, triScale]).fill(with: brushColor)
        yTriangle.place = Transform.move(dx:0, dy:axisScale+axisLen).rotate(angle:Double(-pi/2))
        
        xAxis = Group(contents:[xLine, xTriangle])
        yAxis = Group(contents:[yLine, yTriangle])
        
        let originCircle = Circle(r:(axisScale*0.33)).stroke(fill:brushColor, width:2)
        let biggerOriginCircle = Circle(r:(axisScale)).stroke(fill:brushColor, width:2)
        
        let originTextContent = BrushGraphic.newText("ox:0, oy:0, r:0\nsx:100, sy:100", Transform.move(dx:0,dy:0))
        let originTextBg = Shape(form: Rect(x:-75, y:-20, w:150, h:18), fill:labelColor)
        originText = Group(contents:[originTextBg, originTextContent])

        
        let rotArc = Macaw.Arc(ellipse: Ellipse(cx:0,cy:0, rx:axisScale, ry:axisScale),shift: 0, extent: 0).stroke(fill: brushColor, width:10)
        
        brushIcon = Group(contents: [xAxis, yAxis, originCircle, biggerOriginCircle, rotArc])
        brushIcon.place = Transform.move(dx:Double(0),dy:Double(0))
        
        node.contents.append(brushIcon)
        node.contents.append(brushStream)
        
        //init brush icon
        inputIcon = Shape(form: Circle(r: 10), fill: brushColor, stroke: Macaw.Stroke(fill: Macaw.Color.white, width:2))
        inputIcon.place = Transform.move(dx:Double(self.x), dy:Double(self.y))
        node.contents.append(inputIcon)
        
        let inputTextContent = BrushGraphic.newText("dx: 0, dy: 0", Transform.move(dx:0,dy:10))
        let inputTextBg = Shape(form: Rect(x:-45, y:-6, w:90, h:18), fill:labelColor)
        inputText = Group(contents:[inputTextBg, inputTextContent])

        //init computedicon
        computedIcon = Shape(form: Circle(r: 10), fill: outputColor, stroke: Macaw.Stroke(fill: Macaw.Color.white, width:2))
        computedIcon.place = Transform.move(dx:Double(self.cx), dy:Double(self.cy))
        node.contents.append(computedIcon)
        let computedTextContent = BrushGraphic.newText("abs x: 0, abs y: 0", Transform.move(dx:0,dy:20))
        let computedTextBg = Shape(form: Rect(x:-80, y:3, w:160, h:18), fill:labelColor)
        computedText = Group(contents:[computedTextBg, computedTextContent])

        node.contents.append(outputStream)

        //init generator static location
        generator = Group(contents: [empty])
        generator.place = Transform.move(dx:25, dy:75)
        node.contents.append(generator)
        
        //text
        node.contents.append(stylusText)
        node.contents.append(originText)
        node.contents.append(inputText)
        node.contents.append(computedText)

        
        self.addToScene()
    }
    
    func pointInCircle(x: Float, y:Float, cx:Float, cy:Float, radius:Float) -> Bool {
        print("!!~~ point in circle", x, y, cx, cy)
        let dist = pow((x-cx),2) + pow((y-cy),2)
        let j = dist <= pow(radius, 2)
        print("!!~~ ", j )
        return j
    }
    
    func pointInBox(x: Float, y: Float, ix: Float, iy: Float, ax: Float, ay: Float) -> Bool {
        //ixy are top left, axy are bottom right
        return ix <= x && x <= ax && iy <= y && y <= ay
    }
    
    func checkCollision(x:Float, y:Float) -> String {
        let boxThres:Float = 5
        
        if pointInCircle(x:x, y:y, cx:self.cx, cy:self.cy, radius:15) {
            if !Debugger.outputGfx { return "off"}
            return "output"
        } else if pointInCircle(x:x, y:y, cx:self.x, cy:self.y, radius:15) {
            if !Debugger.brushGfx { return "off"}
            return "brush"
        } else if pointInCircle(x:x, y:y, cx:Float(self.ix), cy:Float(self.iy), radius:15) {
            if !Debugger.inputGfx { return "off"}
            return "input"
        } else if pointInCircle(x:x, y:y, cx:self.ox, cy:self.oy, radius: Float(self.axisScale*0.33) + 5.0) {
            if !Debugger.brushGfx { return "off"}
            return "origin"
        } else if pointInCircle(x:x, y:y, cx:self.ox, cy:self.oy, radius:Float(self.axisScale) + 5.0) {
            if !Debugger.brushGfx { return "off"}
            return "rotation"
        } else if pointInBox(x:x, y:y, ix:self.ox - boxThres, iy:self.oy+Float(self.axisScale),
                             ax: self.ox + boxThres, ay: self.oy + Float(self.axisScale + self.axisLen)) {
            if !Debugger.brushGfx { return "off"}
            return "scale-y"
        } else if pointInBox(x:x, y:y, ix:self.ox+Float(self.axisScale), iy:self.oy-boxThres,
                             ax: self.ox + Float(self.axisScale + self.axisLen), ay: self.oy + boxThres) {
            if !Debugger.brushGfx { return "off"}
            return "scale-x"
        }
        //check generators
        for i in 0...self.generator.contents.count {
            let top_left_x:Float = 25.0
            let top_left_y:Float = 75.0 + Float(i)*130.0 + 30.0
            let bottom_right_x:Float = 225.0
            let bottom_right_y:Float = 175.0 + Float(i)*130.0 + 30.0
            if pointInBox(x:x, y:y, ix:top_left_x, iy:top_left_y,
                          ax: bottom_right_x, ay: bottom_right_y) {
                if !Debugger.inputGfx { return "off"}
                print("~~~ hit in generator ", i)
                //get text
                let node = generator.contents[i] as! Group
                let text = node.contents[2] as! Text
                let t = text.text
                let t_arr = t.split(separator: ",")
                print("~~~ gen name is " , t_arr[0])
                return "gen-"+t_arr[0]
            }
        }
        return ""
    }
    
    static func newText(_ text: String, _ place: Transform, baseline: Baseline = .bottom) -> Text {
        return Text(text: text, fill: Macaw.Color.black, align: .mid, baseline: baseline, place: place)
    }
    
    func addToScene() {
        self.scene.node.contents.append(self.node)
    }
    
    func removeFromScene() {
        var array = self.scene.node.contents
        if let index = array.index(of:self.node) {
            array.remove(at: index)
        }
        self.scene.node.contents = array
    }
    
    func changeColorInGroup(group:Group, color:Macaw.Color) {
        for thing in group.contents {
            if let shape = thing as? Shape {
                shape.fill = color
            } else if let secondGroup = thing as? Group {
                changeColorInGroup(group: secondGroup, color: color)
            }
            else {
                print("~~~ a thing is unfillable :( ", thing)
            }
        }
    }
    
    //for reference, node order is
//    ["lastStylusInputs", "stylusIcon", "stylusUpIcon", "stylusDownIcon", "stylusStream",
//    5 "brushIcon", "brushStream", "inputIcon", "computedIcon", "outputStream",
//    10 "generator", "stylusText", "originText", "inputText", "computedText"]
    
    func toggleViz(type:String) {
        switch(type) {
        case "input":
            //input stream, input dot, generator viz
            if Debugger.inputGfx {
                self.node.contents[0] = lastStylusInputs
                self.node.contents[1] = stylusIcon
                self.node.contents[2] = stylusUpIcon
                self.node.contents[3] = stylusDownIcon
                self.node.contents[4] = stylusStream
                self.node.contents[10] = generator
                
                if Debugger.inputLabelTurnedOff {
                    Debugger.inputLabel = true
                }
                
                if self.scene.stylusOn { self.highlightStylus() }
                if self.scene.forceOn { self.highlightForce() }
                if self.scene.generatorOn { self.highlightGenerator(name:self.scene.generatorOnName) }
                
            } else {
                
                self.node.contents[0] = empty
                self.node.contents[1] = empty
                self.node.contents[2] = empty
                self.node.contents[3] = empty
                self.node.contents[4] = empty
                self.node.contents[10] = empty

                if Debugger.inputLabel {
                    Debugger.inputLabelTurnedOff = true
                }
                Debugger.inputLabel = false
            }
            break
        case "brush":
            //origin icon, brush dot
            if Debugger.brushGfx {
                self.node.contents[5] = brushIcon
                self.node.contents[6] = brushStream
                self.node.contents[7] = inputIcon

                if Debugger.brushLabelTurnedOff {
                    Debugger.brushLabel = true
                }
                
                if self.scene.originOn { self.highlightOrigin() }
                if self.scene.scaleXOn { self.highlightScaleX() }
                if self.scene.scaleYOn { self.highlightScaleY() }
                if self.scene.rotationOn { self.highlightRotation() }
                if self.scene.brushOn { self.highlightBrushIcon() }
                
            } else {
                self.node.contents[5] = empty
                self.node.contents[6] = empty
                self.node.contents[7] = empty
                
                if Debugger.brushLabel {
                    Debugger.brushLabelTurnedOff = true
                }
                Debugger.brushLabel = false
                
            }
            break
        case "output":
            if Debugger.outputGfx {
                
                self.node.contents[8] = computedIcon
                self.node.contents[9] = outputStream
                
                if Debugger.outputLabelTurnedOff {
                    Debugger.outputLabel = true
                }
                if self.scene.outputOn { self.highlightOutput() }
            } else {

                self.node.contents[8] = empty
                self.node.contents[9] = empty
                
                if Debugger.outputLabel {
                    Debugger.outputLabelTurnedOff = true
                }
                Debugger.outputLabel = false
            }
            break
        default:
            break
        }
        toggleLabel(type:type)
    }
    
    func toggleLabel(type:String) {

        switch(type) {
        case "input":
            let text = stylusText.contents[1] as! Text
            let bg = stylusText.contents[0] as! Shape
            if Debugger.inputLabel {
                text.fill = Macaw.Color.black
                bg.fill = labelColor
            } else {
                text.fill = hiddenColor
                bg.fill = hiddenColor
            }
            break
        case "brush":
            let text = originText.contents[1] as! Text
            let text2 = inputText.contents[1] as! Text
            let bg = originText.contents[0] as! Shape
            let bg2 = inputText.contents[0] as! Shape
            
            if Debugger.brushLabel {
                text.fill = Macaw.Color.black
                text2.fill = Macaw.Color.black
                bg.fill = labelColor
                bg2.fill = labelColor

            } else {
                text.fill = hiddenColor
                text2.fill = hiddenColor
                bg.fill = hiddenColor
                bg2.fill = hiddenColor

            }
            break
        case "output":
            let text = computedText.contents[1] as! Text
            let bg = computedText.contents[0] as! Shape
            if Debugger.outputLabel {
                text.fill = Macaw.Color.black
                bg.fill = labelColor
            } else {
                text.fill = hiddenColor
                bg.fill = hiddenColor
            }
            break
        default:
            break
        }
    }
    
    func makeBrushIconInvisible() {
        let xAxis = brushIcon.contents[0] as! Group
        let xLine = xAxis.contents[0] as! Shape
        let xTri = xAxis.contents[1] as! Shape
        xLine.stroke = Macaw.Stroke(fill: hiddenColor, width:2)
        xTri.fill = hiddenColor
        let yAxis = brushIcon.contents[1] as! Group
        let yLine = yAxis.contents[0] as! Shape
        let yTri = yAxis.contents[1] as! Shape
        yLine.stroke = Macaw.Stroke(fill: hiddenColor, width:2)
        yTri.fill = hiddenColor
        let orgCirc = brushIcon.contents[2] as! Shape
        orgCirc.stroke = Macaw.Stroke(fill: hiddenColor, width:2)
        let orgCircBig = brushIcon.contents[3] as! Shape
        orgCircBig.stroke = Macaw.Stroke(fill: hiddenColor, width:2)
        let rotArc = brushIcon.contents[4] as! Shape
        rotArc.stroke = Macaw.Stroke(fill: hiddenColor, width:10)
    }

    func makeBrushIconVisible() {
        let xAxis = brushIcon.contents[0] as! Group
        let xLine = xAxis.contents[0] as! Shape
        let xTri = xAxis.contents[1] as! Shape
        xLine.stroke = Macaw.Stroke(fill: brushColor, width:2)
        xTri.fill = brushColor
        let yAxis = brushIcon.contents[1] as! Group
        let yLine = yAxis.contents[0] as! Shape
        let yTri = yAxis.contents[1] as! Shape
        yLine.stroke = Macaw.Stroke(fill: brushColor, width:2)
        yTri.fill = brushColor
        let orgCirc = brushIcon.contents[2] as! Shape
        orgCirc.stroke = Macaw.Stroke(fill: brushColor, width:2)
        let orgCircBig = brushIcon.contents[3] as! Shape
        orgCircBig.stroke = Macaw.Stroke(fill: brushColor, width:2)
        let rotArc = brushIcon.contents[4] as! Shape
        rotArc.stroke = Macaw.Stroke(fill: brushColor, width:10)
    }
    
    func makeGeneratorInvisible() {
        if !Debugger.inputGfx {
            for groupo in self.generator.contents {
                if let group = groupo as? Group {
                    let bg = group.contents[0] as! Shape
                    bg.fill = hiddenColor
                    bg.stroke = Macaw.Stroke(fill: hiddenColor, width:2)
                    let dot = group.contents[1] as! Shape
                    dot.fill = hiddenColor
                    let text = group.contents[2] as! Text
                    text.fill = hiddenColor
                    if let graph = group.contents[3] as? Group {
                        for thing in graph.contents {
                            let g = thing as! Shape
                            g.stroke = Macaw.Stroke(fill: hiddenColor, width:2)
                        }
                    } else if let graph = group.contents[3] as? Shape {
                        graph.stroke = Macaw.Stroke(fill: hiddenColor, width:2)
                    }
                    let lab = group.contents[4] as! Text
                    lab.fill = hiddenColor
                }
            }
        }
    }
    
    func makeGeneratorVisible() {
        if Debugger.inputGfx {
            for groupo in self.generator.contents {
                if let group = groupo as? Group {
                    let bg = group.contents[0] as! Shape
                    bg.fill = Macaw.Color.white
                    bg.stroke = Macaw.Stroke(fill: Macaw.Color.black, width:2)
                    let dot = group.contents[1] as! Shape
                    dot.fill = inputColor
                    let text = group.contents[2] as! Text
                    text.fill = Macaw.Color.black
                    if let graph = group.contents[3] as? Group {
                        for thing in graph.contents {
                            let g = thing as! Shape
                            g.stroke = Macaw.Stroke(fill: lighterInputColor, width:2)
                        }
                    } else if let graph = group.contents[3] as? Shape {
                        graph.stroke = Macaw.Stroke(fill: lighterInputColor, width:2)
                    }
                    let lab = group.contents[4] as! Text
                    lab.fill = Macaw.Color.black
                    
                }
            }
        }
    }
    
   //highlighting funcs
    
    func highlightStylus() {
        stylusIcon.fill = highlightColor
    }
    func unhighlightStylus() {
        stylusIcon.fill = inputColor
    }
    
    func highlightForce() {
        changeColorInGroup(group: self.lastStylusInputs, color: highlightColor)
    }
    func unhighlightForce() {
        updateExistingStylusStrokes()
    }
    
    func highlightOrigin() {
        let orgCirc = brushIcon.contents[2] as! Shape
        orgCirc.stroke = Macaw.Stroke(fill: highlightColor, width:2)
    }
    
    func unhighlightOrigin() {
        let orgCirc = brushIcon.contents[2] as! Shape
        orgCirc.stroke = Macaw.Stroke(fill: brushColor, width:2)
    }
    
    func highlightScaleX() {
        let xAxis = brushIcon.contents[0] as! Group
        let xLine = xAxis.contents[0] as! Shape
        let xTri = xAxis.contents[1] as! Shape
        xLine.stroke = Macaw.Stroke(fill: highlightColor, width:2)
        xTri.fill = highlightColor
    }
    
    func unhighlightScaleX() {
        let xAxis = brushIcon.contents[0] as! Group
        let xLine = xAxis.contents[0] as! Shape
        let xTri = xAxis.contents[1] as! Shape
        xLine.stroke = Macaw.Stroke(fill: brushColor, width:2)
        xTri.fill = brushColor
    }

    func highlightScaleY() {
        let yAxis = brushIcon.contents[1] as! Group
        let yLine = yAxis.contents[0] as! Shape
        let yTri = yAxis.contents[1] as! Shape
        yLine.stroke = Macaw.Stroke(fill: highlightColor, width:2)
        yTri.fill = highlightColor
    }
    
    func unhighlightScaleY() {
        let yAxis = brushIcon.contents[1] as! Group
        let yLine = yAxis.contents[0] as! Shape
        let yTri = yAxis.contents[1] as! Shape
        yLine.stroke = Macaw.Stroke(fill: brushColor, width:2)
        yTri.fill = brushColor
    }
    
    
    
    func highlightRotation() {
        let rotArc = brushIcon.contents[4] as! Shape
        rotArc.stroke = Macaw.Stroke(fill: highlightColor, width:10)
        let orgCircBig = brushIcon.contents[3] as! Shape
        orgCircBig.stroke = Macaw.Stroke(fill: highlightColor, width:2)

    }
    
    func unhighlightRotation() {
        let rotArc = brushIcon.contents[4] as! Shape
        rotArc.stroke = Macaw.Stroke(fill: brushColor, width:10)
        let orgCircBig = brushIcon.contents[3] as! Shape
        orgCircBig.stroke = Macaw.Stroke(fill: brushColor, width:2)
    }
    
    func highlightBrushIcon() {
        inputIcon.fill = highlightColor
    }
    
    func unhighlightBrushIcon() {
        inputIcon.fill = brushColor
    }
    
    func highlightOutput() {
        computedIcon.fill = highlightColor
    }
    
    func unhighlightOutput() {
        computedIcon.fill = outputColor
    }
    
    
    func highlightGenerator(name:String) {
        if Debugger.inputGfx {
            for groupo in self.generator.contents {
                if let group = groupo as? Group {
                    let text = group.contents[2] as! Text
                    if text.text.contains(name) {
                        let bg = group.contents[0] as! Shape
                        bg.stroke = Macaw.Stroke(fill: highlightColor, width:2)
                    }
                }
            }
        }
    }
    
    func unhighlightGenerator() {
        if Debugger.inputGfx {
            for groupo in self.generator.contents {
                if let group = groupo as? Group {
                    let bg = group.contents[0] as! Shape
                    bg.stroke = Macaw.Stroke(fill: Macaw.Color.black, width:2)
                }
            }
        }
    }
    
    
    func updateGeneratorDot(v: Double, t: Int, type:String, i: Int, freq:Float) {
//        print("dot contents are ~~~~ ", self.generator.contents.count, " i is ", i)
        let sineMultiplier = Int(1/freq)*2
        print("~~~ sine period is", sineMultiplier)
        var biggestMultiplier = 100
        if sineMultiplier > 100 {
            biggestMultiplier = sineMultiplier
        }
        var multiplier = 10
        if type == "sawtooth" {
            multiplier = 1
        }
        else if type == "sine" { //period is 1/freq
            multiplier = Int(biggestMultiplier/sineMultiplier)
            print("~~~ sine mult is " , multiplier)
        }
        if i >= self.generator.contents.count {
            reinitGen(i: i)
        }
        if let genGroup = self.generator.contents[i] as? Group {
            let dot = genGroup.contents[1] as! Shape
            dot.place = Transform.move(dx:Double((t*multiplier%biggestMultiplier)*2)  , dy: 100-v*100)
            let gText = genGroup.contents[2] as! Text
            gText.text = type+", time: "+String(t)+", value: "+String((v*100).rounded()/100)
        } else {
            //reinit
            print("~~~ reinit in update dot")
            reinitGen(i: i)
            updateGeneratorKind(type: type, i: i, freq:freq)
        }
    }
    
    func makeGeneratorGroup() -> Group {
        let generatorDot = Shape(form: Circle(r: 5), fill: inputColor)
        let generatorBg = Shape(form: Rect(x:0, y:0, w: 200, h: 100),
                                fill: Macaw.Color.white,
                                stroke: Macaw.Stroke(fill: Macaw.Color.black, width:2))
        let generatorText = BrushGraphic.newText("", Transform.move(dx:100,dy:125))
        let generatorYAxisLabels = BrushGraphic.newText("1\n\n\n\n\n\n0", Transform.move(dx:-12,dy:10))
        let generatorGraph = Shape(form: Circle(r: 1), fill: Macaw.Color.rgba(r:0,g:0,b:0,a:0))
        let genGroup = Group(contents:[generatorBg, generatorDot, generatorText, generatorGraph, generatorYAxisLabels])
        return genGroup
    }
    
    func reinitGen(i:Int) { //this is only called once!!
        let genGroup = makeGeneratorGroup()
        if !Debugger.inputGfx {
            makeGeneratorInvisible()
        }
        genGroup.place = Transform.move(dx:0, dy:Double(i*130+30))
        if i+1 > self.generator.contents.count {
            self.generator.contents.append(genGroup)
        } else {
            self.generator.contents[i] = genGroup
        }
//        print("~~~ reinit generator. now contents are ", self.generator.contents.count , " with i ", i )
    }
    
    func updateGeneratorKind(type:String, i: Int, freq:Float){
        if self.scene.currentGenerator[i] == "none" || self.generator.contents.count < i+1 { //need to reinit
//            print("~~~ reinit generator in update kind")
            reinitGen(i:i)
        }
        if let _ = self.generator.contents[i] as? Group {
            //yay
        } else {
            reinitGen(i: i)
        }
//        print("~~~~ updating generator kind, i is  ", i)
        switch type {
        case "sawtooth":
            let graph = Macaw.Line(x1:0, y1:100, x2:200, y2:0).stroke(fill:lighterInputColor, width:2)
            let group = self.generator.contents[i] as! Group
            group.contents[3] = graph

        case "triangle":
            let line1 = Macaw.Line(x1:0, y1:100, x2:100, y2:0).stroke(fill:lighterInputColor, width:2)
            let line2 = Macaw.Line(x1:100, y1:0, x2:200, y2:100).stroke(fill:lighterInputColor, width:2)
            let graph = Group(contents:[line1, line2])
            let group = self.generator.contents[i] as! Group
            group.contents[3] = graph
            
        case "square":
            let line1 = Macaw.Line(x1:0, y1:0, x2:100, y2:0).stroke(fill:lighterInputColor, width:2)
            let line2 = Macaw.Line(x1:100, y1:0, x2:100, y2:100).stroke(fill:lighterInputColor, width:2)
            let line3 = Macaw.Line(x1:100, y1:100, x2:200, y2:100).stroke(fill:lighterInputColor, width:2)
            let graph = Group(contents:[line1, line2, line3])
            let group = self.generator.contents[i] as! Group
            group.contents[3] = graph
            
        case "sine":
            //sorry this is a saved array
            let sinePoints:[Double] = [0.0, 0.000635981559753418, 0.007733345031738281, 0.007733345031738281, 0.014205098152160645, 0.022594064474105835, 0.03286713361740112, 0.04498377442359924, 0.058896154165267944, 0.07454922795295715, 0.09188148379325867, 0.11082440614700317, 0.13130322098731995, 0.15323710441589355, 0.17653954029083252, 0.20111849904060364, 0.22687700390815735, 0.2537134289741516, 0.2815217971801758, 0.31019240617752075, 0.33961212635040283, 0.3696648180484772, 0.40023186802864075, 0.43119242787361145, 0.46242478489875793, 0.4938054084777832, 0.5252104997634888, 0.5565161108970642, 0.5875986218452454, 0.618335485458374, 0.6486052870750427, 0.6782886385917664, 0.7072683572769165, 0.735430121421814, 0.7626626491546631, 0.7888586521148682, 0.8139146566390991, 0.8377317190170288, 0.8602160215377808, 0.8812786340713501, 0.9008364677429199, 0.9188124537467957, 0.9351356029510498, 0.9497412443161011, 0.9625722765922546, 0.9735774993896484, 0.9827138781547546, 0.9899451732635498, 0.9952428936958313, 0.998586118221283, 0.9999616146087646, 0.9993640184402466, 0.996795654296875, 0.9922667145729065, 0.9857949614524841, 0.9774059057235718, 0.9671329259872437, 0.9550163745880127, 0.941103994846344, 0.9254508018493652, 0.9081185460090637, 0.8891756534576416, 0.8686968088150024, 0.8467628955841064, 0.8234605193138123, 0.7988815307617188, 0.773123025894165, 0.7462871074676514, 0.718478262424469, 0.689807653427124, 0.6603879332542419, 0.6303356885910034, 0.5997686982154846, 0.5688078999519348, 0.5375750660896301, 0.5061944127082825, 0.4747897982597351, 0.44348421692848206, 0.4124016761779785, 0.38166481256484985, 0.35139501094818115, 0.3217116594314575, 0.2927319407463074, 0.2645701766014099, 0.23733758926391602, 0.21114158630371094, 0.18608561158180237, 0.1622684895992279, 0.13978424668312073, 0.118721604347229, 0.0991637110710144, 0.08118772506713867, 0.06486460566520691, 0.050258755683898926, 0.03742784261703491, 0.026422500610351562, 0.01728612184524536, 0.010054826736450195, 0.004757106304168701, 0.0]
            
            
            var lineArray:[Macaw.Node] = []
            for t in 0...(sinePoints.count-2) {
                lineArray.append(Macaw.Line(x1:Double(t*2), y1:100-100*sinePoints[t], x2:Double((t+1)*2), y2:100-100*sinePoints[t+1]).stroke(fill:lighterInputColor, width:2))
            }

            let graph = Group(contents:lineArray)
            let group = self.generator.contents[i] as! Group
            group.contents[3] = graph
                
            print("~~ sine wave added")
        case "none":
            //delete
            let empty = Shape(form: Circle(r:1), fill: Macaw.Color.rgba(r:0,g:0,b:0,a:0))
            self.generator.contents[i] = Group(contents: [empty])
    
//            print("~~~ deleted generator")
        default:
            //get rid of graph
            print("default")

        }
        if !Debugger.inputGfx {
            makeGeneratorInvisible()
        }
    }
    
    func updateBrushIcon(r: Float, ox:Float, oy:Float, sx:Float, sy:Float) {
        let text = originText.contents[1] as! Text
        let bg = originText.contents[0] as! Shape
        if !Debugger.brushLabel {
            text.fill = hiddenColor
            bg.fill = hiddenColor
        }
        
        print("~~ movinf brush" , Debugger.brushLabel)

        brushIcon.place = Transform.move(dx: Double(ox) - oxOffset, dy: Double(oy) - oyOffset)
        originText.place = Transform.move(dx: Double(ox), dy: Double(oy) - Double(20))
        self.ox = ox
        self.oy = oy
        self.r = r

        text.text = "ox:"+String(Int(ox))+", oy:"+String(Int(oy))+", r:"+String(Int(r))
       // print("## rotated brush ", self.id, " by ", r, " Moved to ox ,oy,", ox, oy )
        
        let rotArc:Shape
        //rotate
        if Debugger.brushGfx {
            rotArc = Macaw.Arc(ellipse: Ellipse(cx:0,cy:0, rx:axisScale*0.75, ry:axisScale*0.75),shift: 0, extent: Double(r * pi/180)).stroke(fill: brushColor, width:10)
        } else {
            rotArc = Macaw.Arc(ellipse: Ellipse(cx:0,cy:0, rx:axisScale*0.75, ry:axisScale*0.75),shift: 0, extent: Double(r * pi/180)).stroke(fill: hiddenColor, width:10)
        }
        brushIcon.contents[4] = rotArc
        
        if (sx != 1 || sy != 1 || scaleChanged) {
            text.text = text.text + "\nsx:"+String(Int(sx))+"%, sy:"+String(Int(sy))+"%"
            scaleChanged = true
            if (sx != 100) {
                let newLine = Macaw.Line(x1: axisScale, y1: 0, x2: axisScale + (axisLen * Double(sx)), y2: 0)
                let xLine = xAxis.contents[0] as! Shape
                let animation = xLine.formVar.animation(to: newLine, during: 0.1, delay: 0)
                animation.play()
                let xTri = xAxis.contents[1] as! Shape
                xTri.placeVar.animate(to: Transform.move(dx:(axisScale + axisLen * Double(sx)), dy: 0).rotate(angle:Double(pi)), during: 0.1, delay: Double(0))
                    //Transform.scale(sx: Double(sx/100.0), sy:1)
               //print("## changed x scale")
            }
            if (sy != 100) {
                let newLine = Macaw.Line(x1: 0, y1: axisScale, x2: 0, y2: axisScale + (axisLen * Double(sy)))
                let yLine = yAxis.contents[0] as! Shape
                let animation = yLine.formVar.animation(to: newLine, during: 0.1, delay: 0)
                animation.play()
                let yTri = yAxis.contents[1] as! Shape
                yTri.placeVar.animate(to: Transform.move(dx:0, dy: (axisScale + axisLen * Double(sy))).rotate(angle:Double(-pi/2)), during: 0.1, delay: Double(0))
//                yAxis.contents[0].form = Macaw.Line(x1: 0, y1: (-axisScale * sy/100.0), x2: 0, y2:(3*axisScale * sy/100.0))
                    //Transform.scale(sx: 1, sy: Double(sy/100.0))
               // print("## changed y scale")
            }
            if (sx == 1 && sy == 1) {
                scaleChanged = false
            }
        }
        
        if self.scene.originOn { self.highlightOrigin() }
        if self.scene.scaleXOn { self.highlightScaleX() }
        if self.scene.scaleYOn { self.highlightScaleY() }
        if self.scene.rotationOn { self.highlightRotation() }


    }
    
    func updateExistingStylusStrokes() {
        var i = 1
        for stroke in lastStylusInputs.contents {
            let stroke = stroke as! Shape
            stroke.fill = Macaw.Color.rgba(r: 74, g:137, b:235, a: Double(225-i*2))
            i += 1
        }
        
    }
    
    
    func moveStylusLocation(x: Double, y: Double, force: Double) {
        self.ix = x
        self.iy = y
        let bg = stylusText.contents[0] as! Shape
        let text = stylusText.contents[1] as! Text
        if !Debugger.inputLabel {
            text.fill = hiddenColor
            bg.fill = hiddenColor
        }
        
        stylusIcon.place = Transform.move(dx: x, dy: y)
        let currStylusIcon:Shape
        let currStylusStream:Shape
        let forceScale = (force+1)/50;
        if Debugger.inputGfx {
            currStylusIcon = Shape(form: Circle(r: 10), fill: inputColor)
            currStylusStream = Shape(form: Circle(r: 3), fill: inputColor)
        } else {
            currStylusIcon = Shape(form: Circle(r: 10), fill: hiddenColor)
            currStylusStream = Shape(form: Circle(r: 3), fill: hiddenColor)
        }


//        print("~~~ in move stylus location with ", x, y, force)
        text.text = "x: "+String(Int(x))+", y: "+String(Int(y))+", force: "+String((force*10).rounded()/10)
        stylusText.place = Transform.move(dx: x, dy: y + 20)
        currStylusIcon.place = Transform.move(dx:x, dy:y).scale(sx:forceScale, sy:forceScale)
        currStylusStream.place = Transform.move(dx:x, dy:y)
        lastStylusInputs.contents.append(currStylusIcon)
        stylusStream.contents.append(currStylusStream)
        if lastStylusInputs.contents.count > inputLimit {
            lastStylusInputs.contents.removeFirst()
        }
        if stylusStream.contents.count > streamLimit {
            stylusStream.contents.removeFirst()
        }
        if Debugger.inputGfx {
            updateExistingStylusStrokes()
        }
        if self.scene.stylusOn { self.highlightStylus() }
        if self.scene.forceOn { self.highlightForce() }
        if self.scene.generatorOn { self.highlightGenerator(name:self.scene.generatorOnName) }

//        print("~~~ node len is ", lastStylusInputs.contents.count)
//        self.savedInputArray = lastStylusInputs
//                node.contents.append(stylusIcon)
    }
    
    func moveBrushLocation(x: Float, y: Float, dx:Float, dy:Float) {
        let text = inputText.contents[1] as! Text
        let bg = inputText.contents[0] as! Shape
        if !Debugger.brushLabel {
            text.fill = hiddenColor
            bg.fill = hiddenColor
        }
        
        inputIcon.place = Transform.move(dx: Double(x), dy: Double(y)) //need this offset for some reason?
        self.x = x
        self.y = y
        text.text = "dx: "+String(Int(dx))+", dy: "+String(Int(dy))
        inputText.place = Transform.move(dx: Double(x), dy: Double(y) - Double(20))
        if self.scene.brushOn { self.highlightBrushIcon() }

        let currBrushStream:Shape
        if Debugger.brushGfx {
            currBrushStream = Shape(form: Circle(r: 3), fill: brushColor)
        } else {
            currBrushStream = Shape(form: Circle(r: 3), fill: hiddenColor)
        }
        currBrushStream.place = Transform.move(dx:Double(x), dy:Double(y))
        brushStream.contents.append(currBrushStream)
        if brushStream.contents.count > streamLimit {
            brushStream.contents.removeFirst()
        }
//        print("## moved input" , self.id, " to x ,y,", x, y )
    }
    
    func moveComputedLocation(cx: Float, cy: Float) {
        let text = computedText.contents[1] as! Text
        let bg = computedText.contents[0] as! Shape
        if !Debugger.outputLabel {
            text.fill = hiddenColor
            bg.fill = hiddenColor
        }
        
        computedIcon.place = Transform.move(dx: Double(cx), dy: Double(cy))
        self.cx = cx
        self.cy = cy
        text.text = "abs x: "+String(Int(cx))+", abs y: "+String(Int(cy))
        computedText.place = Transform.move(dx: Double(cx), dy: Double(cy) + Double(30))
        if self.scene.outputOn { self.highlightOutput() }
        
        let currOutputStream:Shape
        if Debugger.outputGfx {
            currOutputStream = Shape(form: Circle(r: 3), fill: outputColor)
        } else {
            currOutputStream = Shape(form: Circle(r: 3), fill: hiddenColor)
        }
        currOutputStream.place = Transform.move(dx:Double(cx), dy:Double(cy))
        outputStream.contents.append(currOutputStream)
        if outputStream.contents.count > streamLimit {
            outputStream.contents.removeFirst()
        }
        
//        print("## moved computed" , self.id, "to cx cy" , cx, cy)
    }
    
    func movePenUp(x:Double, y:Double, angle:Double){
        var correctedAngle = angle
        print("~~~~ penup angle is ", angle)
        if angle.isNaN { correctedAngle = 0}
        //todo figure out orientation of rotation
        stylusUpIcon.place = Transform.move(dx: x, dy: y).rotate(angle:correctedAngle)
    }
    
    func movePenDown(x:Double, y:Double, angle:Double){
        print("~~~~ pendown angle is ", angle)
        var correctedAngle = angle
        if angle.isNaN { correctedAngle = 0}
        stylusDownIcon.place = Transform.move(dx: x, dy: y).rotate(angle:correctedAngle)
    }
    
}

class BrushGraphicsView: MacawView {
    //overall container
    var scene: BrushGraphicsScene?
  
    override init(frame: CGRect) {
        super.init(frame: frame);
        self.backgroundColor =  UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.0)
       // print("## (1) initialized BG view")
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
//        print("## called update node in graphics view", self.node)
    }
    
}
