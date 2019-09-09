//
//  PathFunctions.swift
//  DynamicBrushes
//
//  Created by JENNIFER MARY JACOBS on 7/19/17.
//  Copyright © 2017 pixelmaid. All rights reserved.
//

import Foundation


class PathFitter{
    var points = [Point]();
    var closed = false;
    
    init(stroke:Stroke) {
        var segments = stroke.segments;
        // Copy over points from path and filter out adjacent duplicates.
        for i in 0..<segments.count{
        //for (var i = 0, prev, l = segments.length; i < l; i++) {
            let point = segments[i].point;
            if (i<0 || !(segments[i-1].point == point)) {
                points.append(point.clone());
            }
        }
       /* // We need to duplicate the first and last segment when simplifying a
        // closed path.
        if (closed) {
            points.unshift(points[points.length - 1]);
            points.push(points[1]); // The point previously at index 0 is now 1.
        }
        this.closed = closed;*/
    }
    
    func addCurve(segments:[Segment], curve:[Point], time:Int, globalTime:Int)->[Segment] {
    var prev = segments[segments.count - 1];
    prev.setHandleOut(point: curve[1].sub(point: curve[0]));
        var s = Segment(point: curve[3],time:time, globalTime:globalTime);
        s.setHandleIn(point: curve[2].sub(point:curve[3]));
        var nSegments = [Segment]();
        nSegments.append(contentsOf: segments);
        nSegments.append(s);
        return nSegments;
    }
    
    // Assign parameter values to digitized points
    // using relative distances between points.
    func chordLengthParameterize(first:Int, last:Int) ->[Float]{
        var u = [Float]();
        u.append(0.0)
    for i in first + 1..<last-1 {
    u[i - first] = u[i - first - 1] + self.points[i].dist(point:self.points[i - 1]);
    }
        let  m = last - first;
    for i in 0..<m-1 {
        u[i] /= u[m];
    }
    return u;
    }
    
    func fit(error:Float,time:Int,globalTime:Int)->[Segment] {
        var points = self.points;
        let length = points.count;
        var segments: [Segment]!
        if (length > 0) {
            // To support reducing paths with multiple points in the same place
            // to one segment:
            segments = [Segment(point: points[0],time:time,globalTime: globalTime)];
            if (length > 1) {
                //self.fitCubic(segments:segments, error:error, first:0, last:length - 1,
                              // Left Tangent
                    //tan1:points[1].sub(point: points[0]),
                    // Right Tangent
                   // tan2:points[length - 2].sub(point: points[length - 1]));
                // Remove the duplicated segments for closed paths again.
                /*if (this.closed) {
                    segments.shift();
                    segments.pop();
                }*/
            }
        }
        return segments;
    }
        // Fit a Bezier curve to a (sub)set of digitized points
    /*func fitCubic(segments:[Segment],error:Float,first:Int,last:Int,tan1:Point,tan2:Point)->[Segment]{
        
        var points = self.points;
        //  Use heuristic if region only has two points in it
        if (last - first == 1) {
            var pt1 = points[first],
            pt2 = points[last],
            dist = pt1.dist(point: pt2) / 3;
            var curve = [Point]();
            curve.append(pt1)
            curve.append(pt1.add(point: Point.normalize(vec:tan1,length:dist)))
            curve.append(pt2.add(point:Point.normalize(vec:tan2,length:dist)));
            curve.append(pt2)

            return self.addCurve(segments: segments,curve:curve);
        }
        // Parameterize points, and attempt to fit curve
        var uPrime = self.chordLengthParameterize(first: first, last: last);
        var maxError = MathUtil.max(v1: error, v2: error * error);
        var split:Int;
        var parametersInOrder = true;
        // Try 4 iterations
        
        for i in 0..<4 {
            var curve = self.generateBezier(first, last, uPrime, tan1, tan2);
            //  Find max deviation of points to fitted curve
            var max = self.findMaxError(first, last, curve, uPrime);
            if (max.error < error && parametersInOrder) {
                self.addCurve(segments, curve);
                return;
            }
            split = max.index;
            // If error not too large, try reparameterization and iteration
            if (max.error >= maxError){
                break;
            }
            parametersInOrder = this.reparameterize(first, last, uPrime, curve);
            maxError = max.error;
        }
        // Fitting failed -- split at max error point and fit recursively
        var tanCenter = points[split - 1].subtract(points[split + 1]);
        this.fitCubic(segments, error, first, split, tan1, tanCenter);
        this.fitCubic(segments, error, split, last, tanCenter.negate(), tan2);
 }*/
    
    
    
    


}
