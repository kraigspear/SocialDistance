//
//  PreviewView.swift
//  KeepYourDistance
//
//  Created by Kraig Spear on 5/13/20.
//  Copyright © 2020 spearware. All rights reserved.
//

import AVFoundation
import UIKit

class PreviewView: UIView {
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        guard let layer = layer as? AVCaptureVideoPreviewLayer else {
            fatalError("Expected `AVCaptureVideoPreviewLayer` type for layer. Check PreviewView.layerClass implementation.")
        }
        return layer
    }

    var session: AVCaptureSession? {
        get {
            return videoPreviewLayer.session
        }
        set {
            videoPreviewLayer.session = newValue
        }
    }

    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
}
