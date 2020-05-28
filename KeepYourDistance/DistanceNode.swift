//
//  DistanceNodes.swift
//  KeepYourDistance
//
//  Created by Kraig Spear on 5/21/20.
//  Copyright © 2020 spearware. All rights reserved.
//

import ARKit
import CoreGraphics
import Foundation
import os.log

/// Two SCNNode used to compare distance
struct DistanceNode {
    private let log = LogContext.distanceNodes

    /// Scene view that Node that was tapped is added to
    private let sceneView: ARSCNView

    /// A SceneKit node added from being tapped
    private var tappedSceneKitNode: SCNNode?

    /**
     Initialize a new `DistanceNodes` with the `ARSCNView` that shows the AR content
     - parameter sceneView: SceneView hosting the AR Content
     */
    init(sceneView: ARSCNView) {
        self.sceneView = sceneView
    }

    /**
     Set a node at the tapped point.
     It's not guaranteed that it will be successful

     - parameter at: The point that was tapped to add a node.
     - returns: The distance in inches to the orgian or nil if it was not added
     */
    mutating func distanceTo(_ point: CGPoint) -> Int? {
        os_log("setTapped: %s",
               log: log,
               type: .debug,
               point.debugDescription)

        tappedSceneKitNode?.removeFromParentNode()

        guard let tappedNode = pointToNode(point) else {
            // SceneKit might not be able to create a node at the tapped point
            os_log("Tapped node nil",
                   log: log,
                   type: .debug)
            return nil
        }

        tappedSceneKitNode = tappedNode

        sceneView.scene.rootNode.addChildNode(tappedNode)

        return distanceInInches
    }

    private var distanceInInches: Int? {
        tappedSceneKitNode?.distanceInInches ?? nil
    }

    private func filter(at location: CGPoint) -> ARHitTestResult? {
        let histTest = sceneView.hitTest(location, types: [.featurePoint, .estimatedHorizontalPlane, .existingPlaneUsingGeometry])

        os_log("number of hits %d",
               log: log,
               type: .debug,
               histTest.count)

        if let resultForGeometryPlane = histTest.first(where: { $0.type == .existingPlaneUsingGeometry }) {
            return resultForGeometryPlane
        }

        histTest.forEach {
            switch $0.type {
            case .featurePoint:
                print("featurePoint")
            case .estimatedHorizontalPlane:
                print("estimatedHorizontalPlane")
            case .existingPlaneUsingGeometry:
                print("existingPlaneUsingGeometry")
            default:
                print("🤮🤮🤮🤮🤮🤮🤮🤮🤮🤮")
            }
        }

        return histTest.last
    }

    private func pointToNode(_ point: CGPoint) -> SCNNode? {
        guard let result = filter(at: point) else { return nil }

        let transform = SCNMatrix4(result.worldTransform)
        let vector = SCNVector3Make(transform.m41, transform.m42, transform.m43)
        return vector.toSphere()
    }
}

extension SCNNode {
    var distanceInInches: Int {
        // Meters to inches conversion
        let inches: Float = 39.3701

        // Difference between x-positions
        let dx = position.x
        let dy = position.y
        let dz = position.z

        let meters = sqrt(dx * dx + dy * dy + dz * dz)
        return Int(meters * inches)
    }
}

extension SCNVector3 {
    func toSphere() -> SCNNode {
        // Creates an SCNSphere with a radius of 0.4
        let sphere = SCNSphere(radius: 0.01)
        // Converts the sphere into an SCNNode
        let node = SCNNode(geometry: sphere)
        // Positions the node based on the passed in position
        node.position = self
        // Creates a material that is recognized by SceneKit
        let material = SCNMaterial()
        // Converts the contents of the PNG file into the material
        material.diffuse.contents = UIColor.orange
        // Creates realistic shadows around the sphere
        material.lightingModel = .blinn
        // Wraps the newly made material around the sphere
        sphere.firstMaterial = material
        // Returns the node to the function
        return node
    }
}
