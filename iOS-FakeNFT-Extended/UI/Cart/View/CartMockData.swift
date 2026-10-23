//
//  CartMockData.swift
//  iOS-FakeNFT-Extended
//
//  Created by Leo Gabuev on 21.10.2026.
//

import Foundation

enum CartMockData {
    static let items: [CartItem] = [
        CartItem(
            id: "1",
            imageName: "april",
            name: "April",
            rating: 1,
            price: 1.78
        ),
        CartItem(
            id: "2",
            imageName: "greena",
            name: "Greena",
            rating: 3,
            price: 1.78
        ),
        CartItem(
            id: "3",
            imageName: "spring",
            name: "Spring",
            rating: 5,
            price: 1.78
        )
    ]
}
