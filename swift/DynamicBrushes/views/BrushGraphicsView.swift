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
    
    init(view: BrushGraphicsView) {
        self.view = view
        self.node = Group()
        print("## (2) init BG scene")
    }

    public func addBrushGraphic(id:String, ox:Float, oy:Float, r: Float,
                         x: Float, y:Float, cx: Float, cy:Float ) {
        //add to id, create new class
        let brushGraphic = BrushGraphic(view:self.view, scene:self, id:id, ox:ox, oy:oy, r:r, x:x, y:y, cx:cx, cy:cy)
        self.activeBrushIds[id] = brushGraphic //add to dict
    }
    
    public func updateBrush(id:String, r: Float, x: Float, y: Float, cx: Float, cy: Float, ox: Float, oy: Float, sx:Float, sy:Float, ix:Double, iy:Double, force:Double) {
        for (_, brush) in self.activeBrushIds {
            if brush.id == id {
                print("## updating brush with id ", id)
                brush.updateBrushIcon(r:r, ox: ox, oy: oy, sx:sx, sy:sy)
                brush.moveComputedLocation(cx: cx, cy: cy)
                brush.moveBrushLocation(x: x, y: y)
                brush.moveStylusLocation(x: ix, y: iy, force:force)
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
    
    public func drawGenerator(valArray: [(Double, Int, String)]) {
        var i:Int = 0;

        for (_, brush) in self.activeBrushIds {
            let numGenerators = valArray.count
//            print("~~~ total num active generators" , numGenerators, self.currentGenerator.count);
            
            if numGenerators > self.currentGenerator.count { //increase slots
                let diff = numGenerators - self.currentGenerator.count
                for _ in 0...diff {
                    self.currentGenerator.append("none")
                }
            }
            
            //order result alphabetically
            let sortedValArray = valArray.sorted(by: {$0.2 < $1.2})
            
            for (value, time, type) in sortedValArray {
                if type != self.currentGenerator[i] {
//                    print("~~ before type is ", self.currentGenerator[i])
                    brush.updateGeneratorKind(type: type, i:i)
                    self.currentGenerator[i] = type
//                    print("~~~ updated generator to ", type, i)
                }
                if type != "none" {
//                    print("~~~~~~ about to update dot for id ", brush.id, value, time, type, i)
                    brush.updateGeneratorDot(v: value, t: time, type:type, i:i)
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
    let stylusText: Text
    let inputIcon: Shape
    var lastStylusInputs = Group()
    let inputLimit = 50
    let computedIcon: Shape
    let originText: Text
    let inputText: Text
    let computedText: Text
    let xAxis: Group
    let yAxis: Group
    
    let generator: Group
    
    let id: String
    var ox: Float
    var oy: Float
    var r: Float
    var x: Float
    var y: Float
    var cx: Float
    var cy: Float
    
    let oxOffset:Double = 0
    let oyOffset:Double = 0
    
    let axisScale:Double = 15
    let axisLen:Double = 50
    var scaleChanged = false
    
    let inputColor = Macaw.Color.rgba(r: 74, g:137, b:235, a: 1)
    let lighterInputColor = Macaw.Color.rgba(r: 74, g:137, b:235, a: 200)
    let brushColor = Macaw.Color.rgba(r: 255, g:53, b:95, a: 63)
    let outputColor = Macaw.Color.rgba(r: 134, g: 73, b: 180, a: 63)
    
    
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
        
        
//        let rotationIndicator = Shape (form: Polygon(points: [30,0,35,15,30,30]), fill: brushColor)
//        let originIndicator = Group(contents: [Macaw.Line(x1: 0, y1: 15, x2: 30, y2: 15).stroke(fill: brushColor, width: 2), Macaw.Line(x1: 15, y1: 0, x2: 15, y2: 30).stroke(fill: brushColor, width: 2)])
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
        originText = BrushGraphic.newText("ox:0, oy:0, r:0\nsx:100, sy:100", Transform.move(dx:0,dy:0))
        let rotArc = Macaw.Arc(ellipse: Ellipse(cx:0,cy:0, rx:axisScale, ry:axisScale),shift: 0, extent: 0).stroke(fill: brushColor, width:10)
        
        brushIcon = Group(contents: [xAxis, yAxis, originCircle, biggerOriginCircle, rotArc])
//        brushIcon.place = Transform.move(dx:Double(self.ox) - oxOffset,dy:Double(self.oy) - oyOffset)
        //for testing
        brushIcon.place = Transform.move(dx:Double(0),dy:Double(0))
        
        node.contents.append(brushIcon)
        node.contents.append(originText)
        print("## init brush icon for brush ", id, " at " , self.ox, self.oy)

        //init stylusicon
        node.contents.append(lastStylusInputs)
        stylusText = BrushGraphic.newText("stylus x: 0, stylus y: 0", Transform.move(dx:0,dy:10))
        node.contents.append(stylusText)
        print("## init stylus icon for brush ", id, " at " , self.x, self.y)
        
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

        //init generator static location
        let empty = Shape(form: Circle(r:1), fill: Macaw.Color.rgba(r:0,g:0,b:0,a:0))
        generator = Group(contents: [empty])
        generator.place = Transform.move(dx:25, dy:75)
        node.contents.append(generator)
        
        self.addToScene()
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
    
    func updateGeneratorDot(v: Double, t: Int, type:String, i: Int) {
//        print("dot contents are ~~~~ ", self.generator.contents.count, " i is ", i)
        var multiplier = 10
        if type == "sawtooth" {
            multiplier = 1
        }
        else if type == "sine" {
            multiplier = 1
        }
        if i >= self.generator.contents.count {
            reinitGen(i: i)
        }
        if let genGroup = self.generator.contents[i] as? Group {
            let dot = genGroup.contents[1] as! Shape
            dot.place = Transform.move(dx:Double((t*multiplier%100)*2) , dy: 100-v*100)
            let gText = genGroup.contents[2] as! Text
            gText.text = type+", time: "+String(t)+", value: "+String((v*100).rounded()/100)
        } else {
            //reinit
            print("~~~ reinit in update dot")
            reinitGen(i: i)
            updateGeneratorKind(type: type, i: i)
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
        genGroup.place = Transform.move(dx:0, dy:Double(i*130+30))
        if i+1 > self.generator.contents.count {
            self.generator.contents.append(genGroup)
        } else {
            self.generator.contents[i] = genGroup
        }
//        print("~~~ reinit generator. now contents are ", self.generator.contents.count , " with i ", i )
    }
    
    func updateGeneratorKind(type:String, i: Int){
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
    }
    
    func updateBrushIcon(r: Float, ox:Float, oy:Float, sx:Float, sy:Float) {
        brushIcon.place = Transform.move(dx: Double(ox) - oxOffset, dy: Double(oy) - oyOffset)
        originText.place = Transform.move(dx: Double(ox), dy: Double(oy) - Double(20))
        self.ox = ox
        self.oy = oy
        self.r = r
        originText.text = "ox:"+String(Int(ox))+", oy:"+String(Int(oy))+", r:"+String(Int(r))
        print("## rotated brush ", self.id, " by ", r, " Moved to ox ,oy,", ox, oy )
        
        //rotate
        let rotArc = Macaw.Arc(ellipse: Ellipse(cx:0,cy:0, rx:axisScale*0.75, ry:axisScale*0.75),shift: 0, extent: Double(r * pi/180)).stroke(fill: brushColor, width:10)
        brushIcon.contents[4] = rotArc
        
        if (sx != 1 || sy != 1 || scaleChanged) {
            originText.text = originText.text + "\nsx:"+String(Int(sx))+"%, sy:"+String(Int(sy))+"%"
            scaleChanged = true
            if (sx != 100) {
                let newLine = Macaw.Line(x1: axisScale, y1: 0, x2: axisScale + (axisLen * Double(sx)), y2: 0)
                let xLine = xAxis.contents[0] as! Shape
                let animation = xLine.formVar.animation(to: newLine, during: 0.1, delay: 0)
                animation.play()
                let xTri = xAxis.contents[1] as! Shape
                xTri.placeVar.animate(to: Transform.move(dx:(axisScale + axisLen * Double(sx)), dy: 0).rotate(angle:Double(pi)), during: 0.1, delay: Double(0))
                    //Transform.scale(sx: Double(sx/100.0), sy:1)
                print("## changed x scale")
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
                print("## changed y scale")
            }
            if (sx == 1 && sy == 1) {
                scaleChanged = false
            }
        }
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
//        let stylusIcon =
        let forceScale = (force+1)
        let currStylusIcon = Shape(form: Circle(r: 10), fill: inputColor)//, stroke: Macaw.Stroke(fill: Macaw.Color.white, width:2))

        print("~~~ in move stylus location with ", x, y, force)
        stylusText.text = "x: "+String(Int(x))+", y: "+String(Int(y))+", force: "+String((force*10).rounded()/10)
        stylusText.place = Transform.move(dx: x, dy: y + 20)
        currStylusIcon.place = Transform.move(dx:x, dy:y).scale(sx:forceScale, sy:forceScale)
        lastStylusInputs.contents.append(currStylusIcon)
        if lastStylusInputs.contents.count > inputLimit {
            lastStylusInputs.contents.removeFirst()
        }
        updateExistingStylusStrokes()
        print("~~~ node len is ", lastStylusInputs.contents.count)
//                node.contents.append(stylusIcon)
    }
    
    func moveBrushLocation(x: Float, y: Float) {
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
