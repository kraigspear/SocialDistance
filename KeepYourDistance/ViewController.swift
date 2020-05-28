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
import CoreMotion
import UIKit

final class ViewController: UIViewController {
    @IBOutlet private var redLineHeightConstraint: NSLayoutConstraint!
    @IBOutlet private var distanceLabel: UILabel!
    @IBOutlet private var redLineView: UIView!

    /// The ARKit scene view
    @IBOutlet var sceneView: ARSCNView!

    /// Gesture to receive taps to indicate where to place a node for measurment
    private var tapGesture: TapGesture?

    /// Model managing two ARKit scene nodes to measure distance
    private var distanceNode: DistanceNode!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupARKit()
        distanceNode = DistanceNode(sceneView: sceneView)
        accelerometers = Accelerometers()
        sinkToAccelerometers()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        accelerometers.start()
        sinkToTapPublisher()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        runSession()
    }

    override func viewWillDisappear(_ animated: Bool) {
        accelerometers.stop()
        pauseSession()
        tapGesture?.cancelGesture()
        tapGesture = nil
        super.viewWillDisappear(animated)
    }

    // MARK: - Tap Gesture

    private var tapCancel: AnyCancellable?
    /// Listen for taps
    private func sinkToTapPublisher() {
        tapGesture = TapGesture(on: sceneView)
        tapCancel = tapGesture!.tapPublisher.sink { location in

            guard let distanceInchces = self.distanceNode.distanceTo(location) else {
                self.distanceLabel.text = "Try again"
                return
            }

            let distanceText = "\(Float(distanceInchces) / 12.0)"
            self.distanceLabel.text = distanceText
        }
    }

    // MARK: - Accelerometers

    /// Provides information about the tilt of the device
    private var accelerometers: Accelerometers!
    private var cancelAccelerometers: AnyCancellable?

    private var cancellableSet: Set<AnyCancellable> = []

    private func sinkToAccelerometers() {
        let parentHeight = sceneView.frame.height
        let redLineHeight = redLineHeightConstraint.constant

        accelerometers.y
            .map { parentHeight * $0 }
            .map { abs($0 - redLineHeight) }
            .receive(on: DispatchQueue.main)
            .sink { height in

                UIView.animate(withDuration: 0.30) {
                    self.redLineHeightConstraint.constant = height
                    self.view.layoutIfNeeded()
                }

            }.store(in: &cancellableSet)

        accelerometers.y.map { Int($0 * 100) }     // Convert to percentage
                        .map { $0.distanceText }
                        .receive(on: DispatchQueue.main)
                        .assign(to: \.text, on: distanceLabel)
                        .store(in: &cancellableSet)
    }

    // MARK: - ARKit - Setup

    private func setupARKit() {
        precondition(sceneView.delegate == nil, "Delgate is not nil")
        sceneView.showsStatistics = true
        sceneView.debugOptions = [.showConstraints, .showLightExtents, .showFeaturePoints, .showWorldOrigin]
    }

    private func runSession() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
    }

    private func pauseSession() {
        sceneView.session.pause()
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}

private extension Int {
    var distanceText: String {
        switch self {
        case ...36:
            return "Less than 1"
        case 36 ..< 44:
            return "1"
        case 44 ..< 52:
            return "2"
        case 52 ..< 57:
            return "3"
        case 57 ..< 60:
            return "4"
        case 60 ..< 64:
            return "5"
        case 64...:
            return "Over six"
        default:
            return ""
        }
    }
}
