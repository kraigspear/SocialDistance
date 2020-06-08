//
//  GridNode.swift
//  KeepYourDistance
//
//  Created by Kraig Spear on 6/5/20.
//  Copyright © 2020 spearware. All rights reserved.
//

import Foundation
import SceneKit
import ARKit

/// Node that shows detected planes
final class GridNode: SCNNode {
    
    /// Anchor of the detected plane
    private(set) var anchor: ARPlaneAnchor
    /// The plane node that can be used to update the postion of the plane for rotation
    private var planeGeometry: SCNPlane!
    
    /**
     Initialize a new instance
     - parameter anchor: Anchor of the detected plane
     */
    init(anchor: ARPlaneAnchor) {
        self.anchor = anchor
        super.init()
        
        func addPlaneNode() {
            
            planeGeometry = SCNPlane(width: CGFloat(self.anchor.extent.x), height: CGFloat(self.anchor.extent.z))
            
            let material = SCNMaterial()
            material.diffuse.contents = UIImage(named:"Grid")
            
            planeGeometry.materials = [material]
            let planeNode = SCNNode(geometry: planeGeometry)
            planeNode.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(geometry: self.planeGeometry, options: nil))
            planeNode.physicsBody!.categoryBitMask = 2
            planeNode.position = SCNVector3Make(anchor.center.x, 0, anchor.center.z)
            planeNode.transform = SCNMatrix4MakeRotation(Float(-Double.pi / 2.0), 1.0, 0.0, 0.0)
            
            addChildNode(planeNode)
            
        }
        
        addPlaneNode()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(anchor: ARPlaneAnchor) {
        planeGeometry.width = CGFloat(anchor.extent.x)
        planeGeometry.height = CGFloat(anchor.extent.z)
        position = SCNVector3Make(anchor.center.x, 0, anchor.center.z)
        let planeNode = self.childNodes.first!
        planeNode.physicsBody = SCNPhysicsBody(type: .static,
                                               shape: SCNPhysicsShape(geometry:
                                                planeGeometry,
                                                options: nil))
    }
    
}
