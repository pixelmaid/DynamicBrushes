//
//  VirtualMachine.swift
//  PaletteKnife
//
//  Created by JENNIFER MARY JACOBS on 10/13/16.
//  Copyright © 2016 pixelmaid. All rights reserved.
//

import Foundation

//static class which stores state and position of fabrication device (like the shopbot)
class Fabricator{
    static var x=0;
    static var y=0;
    static var z=0
    static var xy_speed = 0;
    static var z_speed = 0;
    
    static var target_x:Float! = nil
    static var target_y:Float! = nil
    static var status = "1";
    
}
