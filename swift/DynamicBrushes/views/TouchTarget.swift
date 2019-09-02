//
//  TouchTarget.swift
//  DynamicBrushes
//
//  Created by JENNIFER  JACOBS on 9/1/19.
//  Copyright © 2019 pixelmaid. All rights reserved.
//

import Foundation


protocol TouchTarget{
    
    func recieveTouch(touch:UITouch, state:GestureRecognizer.State, predicted:Bool);
    
}
