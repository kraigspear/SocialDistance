//
//  Accelerometers.swift
//  KeepYourDistance
//
//  Created by Kraig Spear on 5/28/20.
//  Copyright © 2020 spearware. All rights reserved.
//

import Combine
import CoreMotion
import UIKit

final class Accelerometers {
    private var timer: Timer!
    private var cancelTimer: AnyCancellable?
    private let motionManager = CMMotionManager()

    private var ySubject = PassthroughSubject<CGFloat, Never>()

    var y: AnyPublisher<CGFloat, Never> {
        ySubject.eraseToAnyPublisher()
    }

    func start() {
        guard motionManager.isAccelerometerAvailable else { return }
        let interval = 1.0 / 60.0
        motionManager.accelerometerUpdateInterval = interval
        motionManager.startAccelerometerUpdates()

        cancelTimer = Timer.publish(every: interval,
                                    on: RunLoop.current, in: .common)
            .autoconnect()
            .sink { _ in
                self.update()
            }
    }

    func stop() {
        cancelTimer = nil
    }

    private func update() {
        guard let data = motionManager.accelerometerData else { return }
        let y = CGFloat(abs(data.acceleration.y))
        ySubject.send(y)
    }

    // MARK: - Timer
}
