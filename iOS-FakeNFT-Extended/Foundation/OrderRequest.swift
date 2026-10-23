//
//  OrderRequest.swift
//  iOS-FakeNFT-Extended
//
//  Created by Leo Gabuev on 21.10.2026.
//

import Foundation

struct OrderRequest: NetworkRequest {
    let id: String

    var endpoint: URL? {
        URL(
            string: "\(RequestConstants.baseURL)/api/v1/orders/\(id)"
        )
    }
}
