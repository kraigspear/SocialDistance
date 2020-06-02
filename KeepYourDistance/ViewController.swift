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

    /// Distance text to show around the scene node text
    @IBOutlet private var sceneNodeText: UILabel!
    @IBOutlet private var instructionsStackView: UIStackView!

    /// The ARKit scene view
    @IBOutlet var sceneView: ARSCNView!

    /// Gesture to receive taps to indicate where to place a node for measurment
    private var tapGesture: TapGesture?

    /// Model managing two ARKit scene nodes to measure distance
    private var distanceNode: DistanceNode!
    
    private let distanceScanner = DistanceScanner()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.navigationBar.prefersLargeTitles = true

        setupARKit()
        distanceNode = DistanceNode(sceneView: sceneView)
        accelerometers = Accelerometers()
        sinkToAccelerometers()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        accelerometers.start()
        sinkToTapPublisher()
        sinkToInstructionsTapGesture()
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
        cancelInstructionsTap()
        super.viewWillDisappear(animated)
    }

    // MARK: - Tap Gesture

    private var tapCancel: AnyCancellable?
    /// Listen for taps
    private func sinkToTapPublisher() {
        tapGesture = TapGesture(on: sceneView)
        tapCancel = tapGesture!.tapPublisher.sink { location in

            if !self.instructionsStackView.isHidden {
                self.hideInstructions()
                return
            }
            
            guard let distanceInchces = self.distanceNode.distanceTo(location) else {
                self.distanceLabel.text = "Try again"
                return
            }
            
            self.distanceScanner.scan(onSurfaceSize: self.view.frame.size, distanceNode: self.distanceNode)
            
            let distanceInFeet = CGFloat(distanceInchces) / 12.0

            self.sceneNodeText.text = String(format: "%.1f", distanceInFeet)

            var sceneNodeTextFrame = self.sceneNodeText.frame
            sceneNodeTextFrame.origin = location

            self.sceneNodeText.frame = sceneNodeTextFrame
            self.sceneNodeText.isHidden = false
        }
    }
    
    
    private var instructionsTapCancel: AnyCancellable?
    private var instructrionsTap: TapGesture?
    
    private func sinkToInstructionsTapGesture() {
        
        instructrionsTap = TapGesture(on: instructionsStackView)
        instructionsTapCancel = instructrionsTap!.tapPublisher.sink { _ in
            self.hideInstructions()
        }
        
    }
    
    private func hideInstructions() {
        UIView.animate(withDuration: 0.10, animations: { self.instructionsStackView.layer.opacity = 0.0 } ) { _ in
            self.instructionsStackView.isHidden = true
            self.cancelInstructionsTap()
        }
    }
    
    private func cancelInstructionsTap() {
        self.instructionsTapCancel = nil
        self.instructrionsTap?.cancelGesture()
        self.instructrionsTap = nil
    }

    // MARK: - Accelerometers

    /// Provides information about the tilt of the device
    private var accelerometers: Accelerometers!
    private var cancelAccelerometers: AnyCancellable?

    private var cancellableSet: Set<AnyCancellable> = []
    
    private var yChangedPublisher: AnyPublisher<CGFloat, Never> {
        
        let parentHeight = sceneView.frame.height
        let redLineHeight = redLineHeightConstraint.constant
        
        return accelerometers.y.map { parentHeight * $0 }
            .map { abs($0 - redLineHeight) }
            .eraseToAnyPublisher()
    }

    private func sinkToAccelerometers() {

        yChangedPublisher.removeDuplicates()
                         .receive(on: DispatchQueue.main).sink { height in
                            
            UIView.animate(withDuration: 0.30) {
                self.redLineHeightConstraint.constant = height
                self.view.layoutIfNeeded()
            }
                            
        }.store(in: &cancellableSet)
        
        accelerometers.y.map { self.calcYPosition($0)  }
            .map { self.distanceScanner.distanceText(forHeight: $0) }
            .receive(on: DispatchQueue.main)
            .assign(to: \.text, on: self.distanceLabel)
            .store(in: &cancellableSet)
    }
    
    func calcYPosition(_ percentage: CGFloat) -> Int {
        let parentY = abs((percentage * sceneView.frame.height) - sceneView.frame.height)
        print("percentage: \(percentage) parentY: \(parentY)")
        return Int(parentY)
    }
    

    // MARK: - ARKit - Setup

    private func setupARKit() {
        precondition(sceneView.delegate == nil, "Delgate is not nil")
        sceneView.delegate = self
        sceneView.showsStatistics = false
        sceneView.debugOptions = [.showWorldOrigin]
        //sceneView.debugOptions = [.showConstraints, .showLightExtents, .showFeaturePoints, .showWorldOrigin]
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

extension ViewController: ARSCNViewDelegate {
    func renderer(_: SCNSceneRenderer, updateAtTime _: TimeInterval) {
        guard let tappedNode = distanceNode.tappedSceneKitNode else { return }

        let screenCoordinate = sceneView.projectPoint(tappedNode.position)

        DispatchQueue.main.async {
            self.sceneNodeText.center = CGPoint(x: CGFloat(screenCoordinate.x), y: CGFloat(screenCoordinate.y))

            self.sceneNodeText.isHidden = (screenCoordinate.z > 1)

            if let rotation = self.sceneView.session.currentFrame?.camera.eulerAngles.z {
                self.sceneNodeText.transform = CGAffineTransform(rotationAngle: CGFloat(rotation + Float.pi / 2))
            }
        }
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
