//
//  ViewController.swift
//  KeepYourDistance
//
//  Created by Kraig Spear on 5/13/20.
//  Copyright © 2020 spearware. All rights reserved.
//

import ARKit
import AVFoundation
import Combine
import UIKit

final class ViewController: UIViewController {
    /// The ARKit scene view
    @IBOutlet weak var sceneView: ARSCNView!

    /// Model managing two ARKit scene nodes to measure distance
    private var distanceCalculator: DistanceCalculator!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.navigationBar.prefersLargeTitles = true

        setupARKit()
        distanceCalculator = DistanceCalculator(sceneView: sceneView)
        distanceLabelPopulate = DistanceLabelPopulate(label: distanceLabel,
                                                      distanceCalculator: distanceCalculator,
                                                      sceneView: sceneView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        sinkToTapPublisher()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        runSession()
    }

    override func viewWillDisappear(_ animated: Bool) {
        pauseSession()
        tapCancel = nil
        tapGesture?.cancelGesture()
        tapGesture = nil
        super.viewWillDisappear(animated)
    }

    // MARK: - Distance Label

    /// Distance text to show around the scene node text
    @IBOutlet private var distanceLabel: UILabel!

    private final class DistanceLabelPopulate {
        private weak var label: UILabel?
        private let sceneView: ARSCNView
        private let distanceCalculator: DistanceCalculator

        init(label: UILabel,
             distanceCalculator: DistanceCalculator,
             sceneView: ARSCNView) {
            self.label = label
            self.distanceCalculator = distanceCalculator
            self.sceneView = sceneView
        }

        func updatePosition() {
            guard let tappedNode = distanceCalculator.tappedSceneKitNode else { return }

            let screenCoordinate = sceneView.projectPoint(tappedNode.position)

            DispatchQueue.main.async {
                guard let label = self.label else { return }

                label.center = CGPoint(x: CGFloat(screenCoordinate.x), y: CGFloat(screenCoordinate.y))
                label.sizeToFit()

                label.isHidden = (screenCoordinate.z > 1)

                if let rotation = self.sceneView.session.currentFrame?.camera.eulerAngles.z {
                    label.transform = CGAffineTransform(rotationAngle: CGFloat(rotation + Float.pi / 2))
                }
            }
        }

        func updateText(at location: CGPoint) {
            guard let label = label else { return }

            if let distanceInchces = distanceCalculator.distanceTo(location) {
                let distanceInFeet = CGFloat(distanceInchces) / 12.0
                label.text = String(format: "%.1f", distanceInFeet)
            }

            var sceneNodeTextFrame = label.frame
            sceneNodeTextFrame.origin = location
            label.frame = sceneNodeTextFrame
            label.isHidden = false
            label.sizeToFit()
        }
    }

    private var distanceLabelPopulate: DistanceLabelPopulate!

    // MARK: - Tap Gesture

    /// Gesture to receive taps to indicate where to place a node for measurment
    private var tapGesture: TapGesture?

    private var tapCancel: AnyCancellable?
    /// Listen for taps
    private func sinkToTapPublisher() {
        tapGesture = TapGesture(on: sceneView)
        tapCancel = tapGesture!.tapPublisher.sink { location in
            self.distanceLabelPopulate.updateText(at: location)
        }
    }

    // MARK: - ARKit - Setup

    private func setupARKit() {
        precondition(sceneView.delegate == nil, "Delegate is not nil")
        sceneView.delegate = self
        sceneView.showsStatistics = false
    }

    private func runSession() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
        addBottomShape()
    }

    private func pauseSession() {
        sceneView.session.pause()
        sceneView.removeFromSuperview()
    }
    
    //MARK: - Add Bottom Shape
    
    private func addBottomShape() {
        
        let node = SCNNode()
        
        let sixFeetInCenimeters: CGFloat = 574.2432
        let radius: CGFloat = sixFeetInCenimeters / 100.0
        
        let sphere = SCNSphere(radius: radius)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.red.withAlphaComponent(0.9)
        sphere.firstMaterial = material
        
        node.geometry = sphere
        node.position = SCNVector3(x: 0.0, y: -8.0, z: 0.0)
        sceneView.scene.rootNode.addChildNode(node)
    }
    
    //MARK: - Grid
    
    private let planeGrids = PlaneGrids()
    
    /// Grids that show what planes have been detected.
    private final class PlaneGrids {
        /// GridNodes that have been detected. Stored so that the grids can be updated
        private var grids: [GridNode] = []
        
        func add(planeAnchor: ARPlaneAnchor, to node: SCNNode) {
            let gridNode = GridNode(anchor: planeAnchor)
            grids.append(gridNode)
            node.addChildNode(gridNode)
        }
        
        func update(planeAnchor: ARPlaneAnchor) {
            
            guard let foundGrid = grids.first(where: { $0.anchor.identifier == planeAnchor.identifier } ) else {
                return
            }
            
            foundGrid.update(anchor: planeAnchor)
        }
        
    }

    // MARK: - Orientation

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}

// MARK: - ARSCNViewDelegate

extension ViewController: ARSCNViewDelegate {
    func renderer(_: SCNSceneRenderer, updateAtTime _: TimeInterval) {
        distanceLabelPopulate.updatePosition()
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        guard let planeAnchor = anchor as? ARPlaneAnchor else {
            assertionFailure("ARPlaneAnchor expected?")
            return
        }

        planeGrids.add(planeAnchor: planeAnchor, to: node)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        
        guard let planeAnchor = anchor as? ARPlaneAnchor else {
            assertionFailure("ARPlaneAnchor expected?")
            return
        }
        
        planeGrids.update(planeAnchor: planeAnchor)
    }
}
