//
//  TapGesture.swift
//  KeepYourDistance
//
//  Created by Kraig Spear on 5/20/20.
//  Copyright © 2020 spearware. All rights reserved.
//

import Combine
import UIKit

/// Encompass a `UITapGestureRecognizer` and a view
/// Indicates that a tap happened via a Combine publisher
final class TapGesture {
    /// View that the gesture is added to
    private weak var tapOnView: UIView?
    /// `UITapGestureRecognizer` used to receive the tap
    private weak var tapGesture: UITapGestureRecognizer?

    /// `PassthroughSubject` used to inform that a tap has occured at a given point
    private let tapPassThroughSubject = PassthroughSubject<CGPoint, Never>()

    /// Publisher that is used to subscribe to the Tap
    var tapPublisher: AnyPublisher<CGPoint, Never> {
        tapPassThroughSubject.eraseToAnyPublisher()
    }

    /**
     Initialize a new instance with the view that will receive the gesture
     - parameter on: View that will receive the gesture
     */
    init(on view: UIView) {
        tapOnView = view
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tapGesture.numberOfTapsRequired = 1
        view.addGestureRecognizer(tapGesture)
        self.tapGesture = tapGesture
    }

    deinit {
        cancelGesture()
    }

    /// Removes the tap gesture
    func cancelGesture() {
        guard let tapGesture = self.tapGesture else { return }
        tapOnView?.removeGestureRecognizer(tapGesture)
    }

    /// Handle the tap, notifify subject
    @objc private func handleTap(_ sender: UITapGestureRecognizer) {
        guard let view = tapOnView else { return }

        let location = sender.location(in: view)

        tapPassThroughSubject.send(location)
    }
}
