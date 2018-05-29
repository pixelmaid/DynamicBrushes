//
//  Matrix.swift
//  DynamicBrushes
//
//  Created by JENNIFER MARY JACOBS on 8/16/16.
//  Copyright © 2016 pixelmaid. All rights reserved.
//

import Foundation


class Matrix{
    
    var a:Float
    var b:Float
    var c:Float
    var d:Float
    var tx:Float
    var ty:Float
    
    
    init(){
        self.a = 1;
        self.d = 1;
        self.b = 0
        self.c = 0
        self.tx = 0
        self.ty = 0;
    }
    
    func transformPoint(x:Float,y:Float)->(Float,Float) {
        
        
        let newX =  x * self.a + y * self.c + self.tx
        let newY = x * self.b + y * self.d + self.ty
        
        return(newX,newY)
        
    }
    
    
    
    func translate(x:Float,y:Float) {
        self.tx += x * self.a + y * self.c;
        self.ty += x * self.b + y * self.d;
    }
    
    func rotate (_angle:Float, centerX:Float, centerY:Float) {
        let angle =  _angle * Float(Float.pi / 180);
        
        // Concatenate rotation matrix into this one
        let x = centerX;
        let y = centerY;
        let cs = cos(angle)
        let sn = sin(angle)
        let tx = x - x * cs + y * sn
        let ty = y - x * sn - y * cs
        let a = self.a
        let b = self.b
        let c = self.c
        let d = self.d
        self.a = cs * a + sn * c;
        self.b = cs * b + sn * d;
        self.c = -sn * a + cs * c;
        self.d = -sn * b + cs * d;
        self.tx += tx * a + ty * c;
        self.ty += tx * b + ty * d;
    }
    
    func scale(x:Float,y:Float,centerX:Float,centerY:Float) {
        
        self.translate(x: centerX,y:centerY);
        self.a *= x;
        self.b *= x;
        self.c *= y;
        self.d *= y;
        
        self.translate(x: -centerX,y:-centerY);
        
    }
    
    
    
    func append(mx:Matrix) {
        let a1 = self.a
        let b1 = self.b
        let c1 = self.c
        let d1 = self.d
        let a2 = mx.a
        let b2 = mx.c
        let c2 = mx.b
        let d2 = mx.d
        let tx2 = mx.tx
        let ty2 = mx.ty
        self.a = a2 * a1 + c2 * c1;
        self.c = b2 * a1 + d2 * c1;
        self.b = a2 * b1 + c2 * d1;
        self.d = b2 * b1 + d2 * d1;
        self.tx += tx2 * a1 + ty2 * c1;
        self.ty += tx2 * b1 + ty2 * d1;
        
    }
    
    func prepend(mx:Matrix) {
        let a1 = self.a
        let b1 = self.b
        let c1 = self.c
        let d1 = self.d
        let tx1 = self.tx
        let ty1 = self.ty
        let a2 = mx.a
        let b2 = mx.c
        let c2 = mx.b
        let d2 = mx.d
        let tx2 = mx.tx
        let ty2 = mx.ty
        self.a = a2 * a1 + b2 * b1;
        self.c = a2 * c1 + b2 * d1;
        self.b = c2 * a1 + d2 * b1;
        self.d = c2 * c1 + d2 * d1;
        self.tx = a2 * tx1 + b2 * ty1 + tx2;
        self.ty = c2 * tx1 + d2 * ty1 + ty2;
    }
    
    
    
    func reset() {
        self.a = 1;
        self.d = 1;
        self.b = 0
        self.c = 0
        self.tx = 0
        self.ty = 0;
    }
    
    func clone()->Matrix {
        let m = Matrix()
        m.set(a: self.a, b: self.b, c: self.c, d: self.d,
              tx: self.tx, ty: self.ty)
        return m
    }
    
    private func set(a:Float, b:Float, c:Float, d:Float, tx:Float, ty:Float){
        
        self.a = a;
        self.b = b;
        self.c = c;
        self.d = d;
        self.tx = tx;
        self.ty = ty;
        
    }
}
