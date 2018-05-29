//
//  SVGgenerator.swift
//  DynamicBrushes
//
//  Created by JENNIFER MARY JACOBS on 9/19/16.
//  Copyright © 2016 pixelmaid. All rights reserved.
//

import Foundation


class SVGGenerator{
    
    func generatePath(stroke:Stroke)->String{
        var source = "<polyline fill =\"none\" stroke=\"#000000\" stroke-miterlimit=\"10\" points=\""
        
        for i in 0..<stroke.segments.count{
            source += String(stroke.segments[i].point.x.get(id: nil))
            source += ","
            source += String(stroke.segments[i].point.y.get(id: nil))
            source += " "
            
        }
        
        source += "\"/>"
        return source;
        
    }
    
    func generate(strokes:[Stroke])->String{
        var source = "<?xml version=\"1.0\" encoding=\"utf-8\"?><svg version=\"1.1\" id=\"Layer_1\" xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" x=\"0px\" y=\"0px\" viewBox=\"0 0 1366 1024\" xml:space=\"preserve\">"
        
        
        for i in 0..<strokes.count{
            
            source += generatePath(stroke: strokes[i])
        }
        
        source += "</svg>"
        return source
        
    }
    
    
}
