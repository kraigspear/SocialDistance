//
//  DistanceScanner.swift
//  KeepYourDistance
//
//  Created by Kraig Spear on 6/2/20.
//  Copyright © 2020 spearware. All rights reserved.
//

import Foundation
import CoreGraphics

final class DistanceScanner {
    
    private var distances: [DistanceCoordinates] = []
    
    func scan(onSurfaceSize size: CGSize,
              distanceNode: DistanceNode) {
        
        var distanceNode = distanceNode
        var distances = DistanceScanner.initCoordinates()
        
        let middleX = CGFloat(size.width / 2)
        
        for y in (0...Int(size.height)) {
            let point = CGPoint(x: middleX, y: CGFloat(y))
            if let dinstanceInInches = distanceNode.distanceTo(point) {
               let distanceInFeet = CGFloat(dinstanceInInches) / 12.0
                
                for (index, var distanceCoordinate) in distances.enumerated() {
                    distanceCoordinate.updateIfClose(feet: distanceInFeet, point: point)
                    distances[index] = distanceCoordinate
                }
                
            }
        }
        
         self.distances = distances
    }
    
    func distanceText(forHeight height: Int) -> String {
           
           print("distanceText: \(height)")
           
           func compareDistance(a: DistanceCoordinates, b: DistanceCoordinates) throws -> Bool  {
               return abs(Int(a.y) - height) < abs(Int(b.y) - height)
           }
           
           if let minDistance = try? distances.min (by: compareDistance(a:b:)) {
               return "\(minDistance.closestTo)"
           }
           
           return ""
       }
    
    private static func initCoordinates() -> [DistanceCoordinates] {
        let oneFoot = DistanceCoordinates(closestTo: 1.0)
        let twoFoot = DistanceCoordinates(closestTo: 2.0)
        let threeFoot = DistanceCoordinates(closestTo: 3.0)
        let fourFoot = DistanceCoordinates(closestTo: 4.0)
        let fiveFoot = DistanceCoordinates(closestTo: 5.0)
        let sixFoot = DistanceCoordinates(closestTo: 6.0)
        return [oneFoot, twoFoot, threeFoot, fourFoot, fiveFoot, sixFoot]
    }
}
