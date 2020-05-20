//
//  ViewController.swift
//  KeepYourDistance
//
//  Created by Kraig Spear on 5/13/20.
//  Copyright © 2020 spearware. All rights reserved.
//

import UIKit
import AVFoundation
import CoreMotion

final class ViewController: UIViewController {

    @IBOutlet private weak var previewView: PreviewView!
    @IBOutlet private weak var redlineBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var redLineHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var distanceLabel: UILabel!
    @IBOutlet private weak var redLineView: UIView!
    
    //MARK: - Session Management
    private enum SessionSetupResult {
       case success
       case notAuthorized
       case configurationFailed
    }
    
    private let session = AVCaptureSession()
    
    private var setupResult: SessionSetupResult = .success
    
    private let sessionQueue = DispatchQueue(label: "session queue")
    
    @objc dynamic var videoDeviceInput: AVCaptureDeviceInput!
    
    private var captureSession: AVCaptureSession?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        requestAccess()
       
        //transform
        
      
        
        //
       
        
        previewView.session = session
        
        sessionQueue.async {
            self.configureSession()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sessionQueue.async {
            switch self.setupResult {
            case .success:
                self.session.startRunning()
            default:
                break
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startAccelermoters()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        timer.invalidate()
        timer = nil
        super.viewDidDisappear(animated)
    }
   
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    private func requestAccess() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                // The user has previously granted access to the camera.
                break
            case .notDetermined:
                sessionQueue.suspend()
                AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                               if !granted {
                                   self.setupResult = .notAuthorized
                               }
                               self.sessionQueue.resume()
                           })
        default:
            setupResult = .notAuthorized
        }
    }
    
    private func configureSession() {
        guard setupResult == .success else { return }
        session.beginConfiguration()
        session.sessionPreset = .photo
        
        do {
            
            if let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                          for: .video,
                                                          position: .back) {
                
                let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
                
                if session.canAddInput(videoDeviceInput) {
                    session.addInput(videoDeviceInput)
                    DispatchQueue.main.async {
                        self.previewView.videoPreviewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
                        self.previewView.videoPreviewLayer.videoGravity = .resizeAspectFill
                    }
                }
                
                
            } else {
                setupResult = .configurationFailed
                return
            }
        } catch {
            setupResult = .configurationFailed
            session.commitConfiguration()
            return
        }
        
        session.commitConfiguration()
    }
    
    //MARK: - CoreMotion
    private let motion = CMMotionManager()
    private var timer: Timer!
    
    private func startAccelermoters() {
        guard motion.isAccelerometerAvailable else { return }
        
        let parentHeight = self.previewView.frame.height
        
        let interval = 1.0 / 60.0
        
        motion.accelerometerUpdateInterval = interval  // 60 Hz
        motion.startAccelerometerUpdates()
        
        timer = Timer(fire: Date(), interval: interval, repeats: true) { timer in
            
            if let data = self.motion.accelerometerData {
                
                let y = CGFloat(abs(data.acceleration.y))
                
                let constraintConst = parentHeight * y
                //let delta = abs(constraintConst - self.redlineBottomConstraint.constant)
                
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
                
                //if delta >= 10.0 {
                    //self.redlineBottomConstraint.constant = constraintConst
                self.redLineHeightConstraint.constant = constraintConst
                
                UIView.animate(withDuration: 0.10) {
                    self.previewView.layoutIfNeeded()
                }
                
                //self.previewView.setNeedsLayout()
                //print("x: \(x) y: \(y) z: \(z)")
                print("constraintConst: \(constraintConst)")
                
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

