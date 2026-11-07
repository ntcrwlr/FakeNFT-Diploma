//
//  CurrenciesRequest.swift
//  iOS-FakeNFT-Extended
//
//  Created by Leo Gabuev on 05.11.2026.
//

import Foundation

struct CurrenciesRequest: NetworkRequest {
    var endpoint: URL? {
        URL(
            string: "\(RequestConstants.baseURL)/api/v1/currencies"
        )
    }
}
