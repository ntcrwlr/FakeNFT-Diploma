//
//  PreviewCartService.swift
//  iOS-FakeNFT-Extended
//
//  Created by Leo Gabuev on 21.10.2026.
//


import Foundation

struct PreviewCartService: CartService {
    func loadOrder(id: String) async throws -> Order {
        Order(
            id: id,
            nfts: ["1", "2", "3"]
        )
    }
}

struct PreviewNftService: NftService {
    func loadNft(id: String) async throws -> Nft {
        switch id {
        case "1":
            return Nft(
                id: "1",
                name: "April",
                images: [],
                rating: 3,
                price: 1.78
            )
        case "2":
            return Nft(
                id: "2",
                name: "Greena",
                images: [],
                rating: 4,
                price: 1.78
            )
        default:
            return Nft(
                id: "3",
                name: "Spring",
                images: [],
                rating: 5,
                price: 1.78
            )
        }
    }
}
