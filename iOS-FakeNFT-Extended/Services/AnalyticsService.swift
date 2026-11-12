//
//  AnalyticsService.swift
//  iOS-FakeNFT-Extended
//
//  Created by Leo Gabuev on 08.11.2026.
//

import Foundation
import AppMetricaCore
import OSLog

protocol AnalyticsService {
    func reportEvent(
        name: String,
        parameters: [AnyHashable: Any]
    )
}

final class AppMetricaAnalyticsService: AnalyticsService {

    func reportEvent(
        name: String,
        parameters: [AnyHashable: Any] = [:]
    ) {
        AppMetrica.reportEvent(
            name: name,
            parameters: parameters,
            onFailure: { error in
                Logger.shared.error(
                    "Ошибка отправки события: \(error.localizedDescription, privacy: .public)"
                )
            }
        )
    }
}
