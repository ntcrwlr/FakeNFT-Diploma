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

    var formFields: [URLQueryItem]? {
            [URLQueryItem(name: "nfts", value: nftIDs.isEmpty ? "null" : nftIDs.joined(separator: ","))]
        }
}


