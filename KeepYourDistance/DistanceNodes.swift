//
//  DistanceNodes.swift
//  KeepYourDistance
//
//  Created by Kraig Spear on 5/21/20.
//  Copyright © 2020 spearware. All rights reserved.
//

import Foundation
import CoreGraphics
import ARKit
import os.log

struct DistanceNodes {
    
    private let log = LogContext.distanceNodes
    
    struct Nodes {
        
        private let log = LogContext.distanceNodes
        
        let tapped: SCNNode
        let device: SCNNode
        
        func add(to: ARSCNView) {
            os_log("add",
                   log: log,
                   type: .debug)
            to.scene.rootNode.addChildNode(device)
            to.scene.rootNode.addChildNode(tapped)
        }
        
        func remove() {
            os_log("remove",
                   log: log,
                   type: .debug)
            tapped.removeFromParentNode()
            device.removeFromParentNode()
        }
        
        var distanceInInches: Int {
            // Meters to inches conversion
            let inches: Float = 39.3701
            
            // Difference between x-positions
            let dx = tapped.position.x - device.position.x
            let dy = tapped.position.y - device.position.y
            let dz = tapped.position.z - device.position.z
            
            let meters = sqrt(dx*dx + dy*dy + dz*dz)
            return Int(meters * inches)
        }
    }
    
    private let sceneView: ARSCNView
    private var nodes: Nodes?
    private var textNode: SCNNode?
    
    init(sceneView: ARSCNView) {
        self.sceneView = sceneView
    }
    
    mutating func setTapped(at location: CGPoint) {
       
        os_log("setTapped: %s",
               log: log,
               type: .debug,
               location.debugDescription)
        
        nodes?.remove()
        
        let height = sceneView.frame.height - 20
        let middle = sceneView.frame.width / 2
        
        guard let tappedNode = pointToNode(location) else { return }
        guard let deviceNode = pointToNode(CGPoint(x: middle, y: height)) else { return }
        
        nodes = Nodes(tapped: tappedNode, device: deviceNode)
        nodes!.add(to: sceneView)
        
        addTextNode(at: tappedNode.position)
    }
    
    private func addTextNode(at location: SCNVector3) {
        
        guard let nodes = self.nodes else { return }
        
        os_log("addTextNode",
               log: log,
               type: .debug)
        
        textNode?.removeFromParentNode()
        
        let text = "\(nodes.distanceInInches / 12) Feet"
        
        print("Distance: \(text)")
        
        let newText = SCNText(string: text, extrusionDepth: 0.00)
        newText.firstMaterial!.diffuse.contents = UIColor.red
        newText.firstMaterial!.specular.contents = UIColor.white
        newText.font = UIFont(name: "Futura", size: 0.15)
        newText.alignmentMode = CATextLayerAlignmentMode.center.rawValue
        newText.firstMaterial?.isDoubleSided = true
        newText.chamferRadius = 0.01
        newText.containerFrame = CGRect(x: 0, y: 0, width: 100, height: 44)
        
        
        let (minBound, maxBound) = newText.boundingBox
        let textNode = SCNNode(geometry: newText)
        textNode.pivot = SCNMatrix4MakeTranslation( (maxBound.x - minBound.x)/2, minBound.y, 0.02/2)
        textNode.scale = SCNVector3Make(0.1, 0.1, 0.1)
        
        textNode.position = location
        
        addChildNode(textNode)
    }
    
    private func addChildNode(_ childNode: SCNNode) {
        sceneView.scene.rootNode.addChildNode(childNode)
    }
    
    private func filter(at location: CGPoint) -> ARHitTestResult? {
        let histTest = sceneView.hitTest(location, types: [ARHitTestResult.ResultType.featurePoint])
        return histTest.last
    }
    
    private func pointToNode(_ point: CGPoint) -> SCNNode? {
        guard let result = filter(at: point) else { return nil }
        
        let transform = SCNMatrix4.init(result.worldTransform)
        let vector = SCNVector3Make(transform.m41, transform.m42, transform.m43)
        return vector.toSphere()
    }
    
}

extension SCNVector3 {
    func toSphere() -> SCNNode {
        
        // Creates an SCNSphere with a radius of 0.4
        let sphere = SCNSphere(radius: 0.03)
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
