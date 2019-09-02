//
//  GestureRecognizer.swift
//  DynamicBrushes
//
//  Created by JENNIFER  JACOBS on 8/29/19.
//  Copyright © 2019 pixelmaid. All rights reserved.
//

import UIKit
import UIKit.UIGestureRecognizerSubclass

/// A custom gesture recognizer that receives touch events and appends data to the stroke sample.
/// - Tag: StrokeGestureRecognizer
class GestureRecognizer: UIGestureRecognizer {
    // MARK: - Configuration
    var collectsCoalescedTouches = true
    var usesPredictedSamples = true
    var touchTarget:TouchTarget?
    
    /// A Boolean value that determines whether the gesture recognizer tracks Apple Pencil or finger touches.
    /// - Tag: isForPencil
    var isForPencil: Bool = false {
        didSet {
            if isForPencil {
                allowedTouchTypes = [UITouch.TouchType.pencil.rawValue as NSNumber]
            } else {
                allowedTouchTypes = [UITouch.TouchType.direct.rawValue as NSNumber]
            }
        }
    }
    
    
    
    // MARK: - Data
    var outstandingUpdateIndexes = [Int: (Stroke, Int)]()
    var coordinateSpaceView: UIView?
    
    // MARK: - State
    var trackedTouch: UITouch?
    var initialTimestamp: TimeInterval?
    var collectForce = false
    
    var fingerStartTimer: Timer?
    private let cancellationTimeInterval = TimeInterval(0.1)
    
    var ensuredReferenceView: UIView {
        if let view = coordinateSpaceView {
            return view
        } else {
            return view!
        }
    }
    
    // MARK: - data collection
    
    func setTouchTarget(target:TouchTarget){
        self.touchTarget = target;
    }
    
    /// Appends touch data to the stroke sample.
    /// - Tag: appendTouches
    func append(touches: Set<UITouch>, event: UIEvent?) -> Bool {
        // Check that we have a touch to append, and that touches
        // doesn't contain it.
        guard let touchToAppend = trackedTouch, touches.contains(touchToAppend) == true
            else {
                return false
                
        }
        
        // Cancel the stroke recognition if we get a second touch during cancellation period.
        if shouldCancelRecognition(touches: touches, touchToAppend: touchToAppend) {
            if state == .possible {
                state = .failed
            } else {
                state = .cancelled
            }
            return false
        }
        
        if collectsCoalescedTouches {
            if let event = event {
                let coalescedTouches = event.coalescedTouches(for: touchToAppend)!
                let lastIndex = coalescedTouches.count - 1
                for index in 0..<lastIndex {
                    touchTarget!.recieveTouch(touch:coalescedTouches[index],state:state,predicted: false);
                }
                touchTarget!.recieveTouch(touch:coalescedTouches[lastIndex],state:state,predicted:false);

            }
        } else {
            touchTarget!.recieveTouch(touch:touchToAppend,state:state,predicted:false);

            
        }
        
        if usesPredictedSamples {
            if let predictedTouches = event?.predictedTouches(for: touchToAppend) {
                for touch in predictedTouches {
                    //touchTarget!.recieveTouch(touch:touch,state:state,predicted:true);

                }
            }
        }
        
        return true
    }
    
    func shouldCancelRecognition(touches: Set<UITouch>, touchToAppend: UITouch) -> Bool {
        var shouldCancel = false
        for touch in touches {
            if touch !== touchToAppend &&
                touch.timestamp - initialTimestamp! < cancellationTimeInterval {
                shouldCancel = true
                break
            }
        }
        return shouldCancel
    }
    
    /*func saveStrokeSample(stroke: Stroke, touch: UITouch, view: UIView, coalesced: Bool, predicted: Bool ) {
        // Only collect samples that actually moved in 2D space.
        let location = touch.preciseLocation(in: view)
        if let previousSample = stroke.samples.last {
            if (previousSample.location - location).quadrance < 0.003 {
                return
            }
        }
        
        var sample = StrokeSample(timestamp: touch.timestamp,
                                  location: location,
                                  coalesced: coalesced,
                                  predicted: predicted,
                                  force: self.collectForce ? touch.force : nil)
        
        if touch.type == .pencil {
            let estimatedProperties = touch.estimatedProperties
            sample.estimatedProperties = estimatedProperties
            sample.estimatedPropertiesExpectingUpdates = touch.estimatedPropertiesExpectingUpdates
            sample.altitude = touch.altitudeAngle
            sample.azimuth = touch.azimuthAngle(in: view)
            if stroke.samples.isEmpty &&
                estimatedProperties.contains(.azimuth) {
                stroke.expectsAltitudeAzimuthBackfill = true
            } else if stroke.expectsAltitudeAzimuthBackfill &&
                !estimatedProperties.contains(.azimuth) {
                for (index, priorSample) in stroke.samples.enumerated() {
                    var updatedSample = priorSample
                    if updatedSample.estimatedProperties.contains(.altitude) {
                        updatedSample.estimatedProperties.remove(.altitude)
                        updatedSample.altitude = sample.altitude
                    }
                    if updatedSample.estimatedProperties.contains(.azimuth) {
                        updatedSample.estimatedProperties.remove(.azimuth)
                        updatedSample.azimuth = sample.azimuth
                    }
                    stroke.update(sample: updatedSample, at: index)
                }
                stroke.expectsAltitudeAzimuthBackfill = false
            }
        }
        
        if predicted {
            stroke.addPredicted(sample: sample)
        } else {
            let index = stroke.add(sample: sample)
            if touch.estimatedPropertiesExpectingUpdates != [] {
                if let estimationUpdateIndex = touch.estimationUpdateIndex {
                    self.outstandingUpdateIndexes[Int(estimationUpdateIndex.intValue)] = (stroke, index)
                }
            }
        }
    }*/
    
    // MARK: - Touch handling methods
    
    /// A set of functions that track touches.
    /// - Tag: HandleTouches
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if trackedTouch == nil {
            trackedTouch = touches.first
            initialTimestamp = trackedTouch?.timestamp
            collectForce = trackedTouch!.type == .pencil || view?.traitCollection.forceTouchCapability == .available
            if !isForPencil {
                // Give other gestures, such as pan and pinch, a chance by
                // slightly delaying the `.begin.
                fingerStartTimer = Timer.scheduledTimer(
                    withTimeInterval: cancellationTimeInterval,
                    repeats: false,
                    block: { [weak self] (timer) in
                        guard let strongSelf = self else { return }
                        if strongSelf.state == .possible {
                            strongSelf.state = .began
                        }
                })
            }
        }
        if isForPencil {
            state = .began
        }
        
        let _ = append(touches: touches, event: event);
          
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if state == .began {
            state = .changed
        }
       let _ = append(touches: touches, event: event) 
          
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        state = .ended

       let _ = append(touches: touches, event: event)
       
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if append(touches: touches, event: event) {
            //stroke.state = .cancelled
            state = .failed
        }
    }
    
    /// Replaces previously estimated touch data with updated touch data.
    /// - Tag: estimatedPropertiesUpdated
  /*  override func touchesEstimatedPropertiesUpdated(_ touches: Set<UITouch>) {
        for touch in touches {
            guard let index = touch.estimationUpdateIndex else {
                continue
            }
            if let (stroke, sampleIndex) = outstandingUpdateIndexes[Int(index.intValue)] {
                //var sample = stroke.samples[sampleIndex]
               // let expectedUpdates = sample.estimatedPropertiesExpectingUpdates
                if expectedUpdates.contains(.force) {
                    //sample.force = touch.force
                    if !touch.estimatedProperties.contains(.force) {
                        // Only remove the estimate flag if the new value isn't estimated as well.
                        //sample.estimatedProperties.remove(.force)
                    }
                }
                //sample.estimatedPropertiesExpectingUpdates = touch.estimatedPropertiesExpectingUpdates
                if touch.estimatedPropertiesExpectingUpdates == [] {
                    outstandingUpdateIndexes.removeValue(forKey: sampleIndex)
                }
                //stroke.update(sample: sample, at: sampleIndex)
            }
        }
    }*/
    
    override func reset() {
        trackedTouch = nil
        if let timer = fingerStartTimer {
            timer.invalidate()
            fingerStartTimer = nil
        }
        super.reset()
    }
}
