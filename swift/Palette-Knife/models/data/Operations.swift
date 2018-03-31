//
//  Operations.swift
//  DynamicBrushes
//
//  Created by Jingyi Li on 3/31/18.
//  Copyright © 2018 pixelmaid. All rights reserved.
//

import Foundation

final class Operations {

    static func findMin(_ signalBuffer:[Float]) -> Float {
        var min:Float = signalBuffer[0]
        for signal in signalBuffer {
            if signal < min {
                min = signal
            }
        }
        return min
    }
    
    static func findMax(_ signalBuffer:[Float]) -> Float {
        var max:Float = signalBuffer[0]
        for signal in signalBuffer {
            if signal > max {
                max = signal
            }
        }
        return max
    }
    
    static func map(signalBuffer:[Float], toMin:Float, toMax:Float) -> [Float] {
        let fromMin = findMin(signalBuffer)
        let fromMax = findMax(signalBuffer)
        var newSignal = [Float]()

        for signal in signalBuffer {
            newSignal.append( (signal - fromMin) * (toMax - toMin) / (fromMax - fromMin) + toMin )
        }
        return newSignal
    }
}
