//
//  DistanceCoordinates.swift
//  KeepYourDistance
//
//  Created by Kraig Spear on 6/1/20.
//  Copyright © 2020 spearware. All rights reserved.
//

import Foundation
import CoreGraphics

/// Track the coordinates closest to desired distance
struct DistanceCoordinates: Equatable {
    
    var point = CGPoint()
    var distanceToPoint = CGFloat.greatestFiniteMagnitude
    
    let closestTo: CGFloat
    
    init(closestTo: CGFloat) {
        self.closestTo = closestTo
    }
    
    var y: CGFloat { point.y }
    
    mutating func updateIfClose (feet: CGFloat,
                                 point: CGPoint)  {
        
        let delta = abs(feet - closestTo)
        
        if delta < distanceToPoint {
            print("updateIfClose closestTo: \(closestTo) current: \(distanceToPoint) new: \(delta) point: \(point.y)")
            self.distanceToPoint = delta
            self.point = point
        } else {
            print("Not updating")
        }
        
    }
}
