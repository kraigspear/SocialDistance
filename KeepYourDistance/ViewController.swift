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
    @IBOutlet var sceneView: ARSCNView!

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

        instructions = Instructions(instructionsStackView: instructionsStackView)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        sinkToTapPublisher()
        instructions.listenForTap()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        runSession()
    }

    override func viewWillDisappear(_ animated: Bool) {
        pauseSession()
        tapGesture?.cancelGesture()
        tapGesture = nil
        instructions.cancelListenForTap()
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

    // MARK: - Instructions

    /// Instructions on how to use
    @IBOutlet private var instructionsStackView: UIStackView!

    private var instructions: Instructions!

    final class Instructions {
        private var instructionsTapCancel: AnyCancellable?
        private var instructrionsTap: TapGesture?

        private weak var instructionsStackView: UIStackView?

        init(instructionsStackView: UIStackView) {
            self.instructionsStackView = instructionsStackView
        }

        func listenForTap() {
            guard let instructionsStackView = instructionsStackView else { return }

            instructrionsTap = TapGesture(on: instructionsStackView)
            instructionsTapCancel = instructrionsTap!.tapPublisher.sink { _ in
                self.hideInstructions()
            }
        }

        func cancelListenForTap() {
            instructionsTapCancel = nil
            instructrionsTap?.cancelGesture()
            instructrionsTap = nil
        }

        private func hideInstructions() {
            guard let instructionsStackView = instructionsStackView else { return }
            UIView.animate(withDuration: 0.10, animations: { instructionsStackView.layer.opacity = 0.0 }) { _ in
                instructionsStackView.isHidden = true
                self.cancelListenForTap()
            }
        }
    }

    // MARK: - ARKit - Setup

    private func setupARKit() {
        precondition(sceneView.delegate == nil, "Delgate is not nil")
        sceneView.delegate = self
        sceneView.showsStatistics = false
        sceneView.debugOptions = [.showWorldOrigin]
    }

    private func runSession() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
    }

    private func pauseSession() {
        sceneView.session.pause()
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
}
