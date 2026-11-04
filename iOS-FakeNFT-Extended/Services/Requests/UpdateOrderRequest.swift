//
//  UpdateOrderRequest.swift
//  iOS-FakeNFT-Extended
//
//  Created by Leo Gabuev on 27.10.2026.
//

import Foundation

struct UpdateOrderRequest: NetworkRequest {
    let id: String
    let nftIDs: [String]

    var endpoint: URL? {
        URL(string: "\(RequestConstants.baseURL)/api/v1/orders/\(id)")
    }

    var httpMethod: HttpMethod {
        .put
    }

    var contentType: String {
        "application/x-www-form-urlencoded"
    }

    var httpBody: Data? {
        var components = URLComponents()
        components.queryItems = nftIDs.map {
            URLQueryItem(name: "nfts", value: $0)
        }

        return components.percentEncodedQuery?.data(using: .utf8)
    }
}


