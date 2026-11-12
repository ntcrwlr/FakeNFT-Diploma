//
//  Logger.swift
//  iOS-FakeNFT-Extended
//
//  Created by Leo Gabuev on 08.11.2026.
//

import Foundation
import OSLog

extension Logger {
    static let shared = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.app.FakeNFT",
        category: "App"
    )
}
