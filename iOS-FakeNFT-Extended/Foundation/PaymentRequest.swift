//
//  PaymentRequest.swift
//  iOS-FakeNFT-Extended
//
//  Created by Leo Gabuev on 05.11.2026.
//

import Foundation

struct PaymentRequest: NetworkRequest {
    let currencyID: String

    var endpoint: URL? {
        URL(
            string: "\(RequestConstants.baseURL)/api/v1/orders/1/payment/\(currencyID)"
        )
    }
}
