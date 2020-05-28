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
    @IBOutlet private var redlineBottomConstraint: NSLayoutConstraint!
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
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startAccelermoters()
        sinkToTapPublisher()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        runSession()
    }

    override func viewWillDisappear(_ animated: Bool) {
        stopTimer()
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

    private func stopTimer() {
        timer.invalidate()
        timer = nil
    }

    // MARK: - CoreMotion

    private let motion = CMMotionManager()
    private var timer: Timer!

    private func startAccelermoters() {
        guard motion.isAccelerometerAvailable else { return }

        let parentHeight = sceneView.frame.height

        let interval = 1.0 / 60.0

        motion.accelerometerUpdateInterval = interval // 60 Hz
        motion.startAccelerometerUpdates()

        timer = Timer(fire: Date(), interval: interval, repeats: true) { _ in

            if let data = self.motion.accelerometerData {
                let y = CGFloat(abs(data.acceleration.y))

                let constraintConst = parentHeight * y
                let delta = abs(constraintConst - self.redLineHeightConstraint.constant)

                // let feet = Int(constraintConst / 100)
                // let distance = Int(y * 100)

//                var distanceText: String
//                switch distance {
//                case ...36:
//                    distanceText = "Less than 1"
//                case 36..<44:
//                    distanceText = "1"
//                case 44..<52:
//                    distanceText = "2"
//                case 52..<57:
//                    distanceText = "3"
//                case 57..<60:
//                    distanceText = "4"
//                case 60..<64:
//                    distanceText = "5"
//                case 64...:
//                    distanceText = "Over six"
//                default:
//                    distanceText = ""
//                }

                // self.distanceLabel.text = distanceText

                if delta >= 10.0 {
                    UIView.animate(withDuration: 0.30) {
                        self.redLineHeightConstraint.constant = constraintConst
                        self.view.layoutIfNeeded()
                    }

                    // updateDistanceText(to: self.view.frame.height - constraintConst)
                }
            }
        }

        RunLoop.current.add(timer, forMode: .default)

        func updateDistanceText(to y: CGFloat) {
            let x = view.frame.size.width / 2

            let point = CGPoint(x: x, y: y)
            distanceNode.distanceTo(point)
        }
    }

    private func stopAccelermoters() {
        guard timer != nil else { return }
        timer.invalidate()
        timer = nil
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}
