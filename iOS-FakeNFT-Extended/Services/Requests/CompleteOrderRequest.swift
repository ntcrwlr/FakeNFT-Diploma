//
//  CompleteOrderRequest.swift
//  iOS-FakeNFT-Extended
//
//  Created by Leo Gabuev on 11.11.2026.
//

import Foundation

struct CompleteOrderRequest: NetworkRequest {
    let id: String
    let nftIDs: [String]

    var endpoint: URL? {
        URL(
            string: "\(RequestConstants.baseURL)/api/v1/orders/\(id)"
        )
    }

    var httpMethod: HttpMethod {
        .post
    }

    var contentType: String {
        "application/x-www-form-urlencoded"
    }

    var formFields: [URLQueryItem]? {
        [
            URLQueryItem(
                name: "nfts",
                value: nftIDs.joined(separator: ",")
            )
        ]
    }
}
