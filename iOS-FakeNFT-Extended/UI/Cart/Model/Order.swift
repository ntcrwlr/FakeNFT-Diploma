//
//  Order.swift
//  iOS-FakeNFT-Extended
//
//  Created by Leo Gabuev on 21.10.2026.
//

import Foundation

struct Order: Decodable {
    let id: String
    let nfts: [String]
}
