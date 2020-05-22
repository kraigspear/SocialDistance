//
//  ViewController.swift
//  KeepYourDistance
//
//  Created by Kraig Spear on 5/13/20.
//  Copyright © 2020 spearware. All rights reserved.
//

import UIKit
import AVFoundation
import ARKit
import CoreMotion
import Combine


final class ViewController: UIViewController {
    
    @IBOutlet private weak var redlineBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var redLineHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var distanceLabel: UILabel!
    @IBOutlet private weak var redLineView: UIView!
    
    @IBOutlet var sceneView: ARSCNView!
    
    private var tapGesture: TapGesture!
    
    private var textNode: SCNText?
    
    private var distanceNodes: DistanceNodes!
    
    //MARK: - Session Management
    
    private var tapCancel: AnyCancellable?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupARKit()
        tapGesture = TapGesture(on: sceneView)
        
        distanceNodes = DistanceNodes(sceneView: sceneView)
        
        tapCancel = tapGesture.tapPublisher.sink { location in
            self.distanceNodes.setTapped(at: location)
        }
    }
    
    
    
    override func viewDidAppear(_ animated: Bool) {
         super.viewDidAppear(animated)
         startAccelermoters()
     }
     
     override func viewWillDisappear(_ animated: Bool) {
         stopTimer()
         pauseSession()
         super.viewWillDisappear(animated)
     }
    
     override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
         return .portrait
     }
    
    //MARK: - ARKit - Setup
    private func setupARKit() {
        precondition(sceneView.delegate == nil, "Delgate is not nil")
        sceneView.showsStatistics = true
    }
    
    private func runSession() {
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
    }
    
    private func pauseSession() {
        sceneView.session.pause()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        runSession()
    }
    
    private func stopTimer() {
        timer.invalidate()
        timer = nil
    }
    
    
    //MARK: - CoreMotion
    private let motion = CMMotionManager()
    private var timer: Timer!
    
    private func startAccelermoters() {
        guard motion.isAccelerometerAvailable else { return }
        
        let parentHeight = sceneView.frame.height
        
        let interval = 1.0 / 60.0
        
        motion.accelerometerUpdateInterval = interval  // 60 Hz
        motion.startAccelerometerUpdates()
        
        timer = Timer(fire: Date(), interval: interval, repeats: true) { timer in
            
            if let data = self.motion.accelerometerData {
                
                let y = CGFloat(abs(data.acceleration.y))
                
                let constraintConst = parentHeight * y
                let delta = abs(constraintConst - self.redLineHeightConstraint.constant)
                
               // let feet = Int(constraintConst / 100)
                let distance = Int(y * 100)
                
                var distanceText: String
                switch distance {
                case ...36:
                    distanceText = "Less than 1"
                case 36..<44:
                    distanceText = "1"
                case 44..<52:
                    distanceText = "2"
                case 52..<57:
                    distanceText = "3"
                case 57..<60:
                    distanceText = "4"
                case 60..<64:
                    distanceText = "5"
                case 64...:
                    distanceText = "Over six"
                default:
                    distanceText = ""
                }
               
                self.distanceLabel.text = distanceText
                
                if delta >= 10.0 {
                    
                   // print("Updating constriant: \(constraintConst)")
                    UIView.animate(withDuration: 0.30) {
                        self.redLineHeightConstraint.constant = constraintConst
                        self.view.layoutIfNeeded()
                    }
                    
                }
                
                
                //self.previewView.setNeedsLayout()
                //print("x: \(x) y: \(y) z: \(z)")
                //print("constraintConst: \(constraintConst)")
                
            }
            
        }
        
        RunLoop.current.add(timer, forMode: .default)
        
        
    }
    
    private func stopAccelermoters() {
        
        guard timer != nil else { return }
        timer.invalidate()
        timer = nil
        
    }
}

extension SCNNode {
    // Gets distance between two SCNNodes
    func distance(to destination: SCNNode) -> CGFloat {
        
        // Meters to inches conversion
        let inches: Float = 39.3701
        
        // Difference between x-positions
        let dx = destination.position.x - position.x
        
        // Difference between x-positions
        let dy = destination.position.y - position.y
        
        // Difference between x-positions
        let dz = destination.position.z - position.z
        
        // Formula to get meters
        let meters = sqrt(dx*dx + dy*dy + dz*dz)
        
        // Returns inches
        return CGFloat(meters * inches)
    }
}
