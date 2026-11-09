//
//  MockAnalyticsService.swift
//  iOS-FakeNFT-ExtendedTests
//
//  Created by Leo Gabuev on 08.11.2026.
//

import XCTest
@testable import iOS_FakeNFT_Extended

final class MockAnalyticsService: AnalyticsService {
    func reportEvent(
        name: String,
        parameters: [AnyHashable: Any]
    ) {

    }
}
