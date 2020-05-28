//
//  LogContext.swift
//  KeepYourDistance
//
//  Created by Kraig Spear on 5/21/20.
//  Copyright © 2020 spearware. All rights reserved.
//

import Foundation
import os.log

struct LogContext {
    static let distanceNodes = OSLog(subsystem: "com.dornerworks.keepdistance", category: "🤖distanceNodes")
}
