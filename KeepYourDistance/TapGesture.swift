//
//  TapGesture.swift
//  KeepYourDistance
//
//  Created by Kraig Spear on 5/20/20.
//  Copyright © 2020 spearware. All rights reserved.
//

import UIKit
import Combine

final class TapGesture {
    
    private weak var view: UIView?
    private weak var tapGesture: UITapGestureRecognizer?
    
    private let tapPassThroughSubject = PassthroughSubject<CGPoint, Never>()
    
    var tapPublisher: AnyPublisher<CGPoint, Never> {
        tapPassThroughSubject.eraseToAnyPublisher()
    }
    
    init(on view: UIView) {
        
        self.view = view
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tapGesture.numberOfTapsRequired = 1
        view.addGestureRecognizer(tapGesture)
        self.tapGesture = tapGesture
    }
    
    func remove() {
        guard let tapGesture = self.tapGesture else { return }
        view?.removeGestureRecognizer(tapGesture)
    }
    
    @objc private func handleTap(_ sender: UITapGestureRecognizer) {
        
        guard let view = view else { return }
        
        let location = sender.location(in: view)
        
        tapPassThroughSubject.send(location)
    }
}
