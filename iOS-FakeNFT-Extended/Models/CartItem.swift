//
//  CartItem.swift
//  iOS-FakeNFT-Extended
//
//  Created by Leo Gabuev on 21.10.2026.
//

import Foundation

struct CartItem: Identifiable {
    let id = UUID()
    let image: String
    let name: String
    let rating: Int
    let price: Double
}
