//
//  CartViewModel.swift
//  iOS-FakeNFT-Extended
//
//  Created by Leo Gabuev on 21.10.2026.
//


import Foundation

@Observable
@MainActor
final class CartViewModel {
    private let cartService: CartService
    private let nftService: NftService

    private(set) var nfts: [Nft] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    init(
        cartService: CartService,
        nftService: NftService
    ) {
        self.cartService = cartService
        self.nftService = nftService
    }

    func loadCart() async {
        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            let order = try await cartService.loadOrder(id: "1")

            var loadedNfts: [Nft] = []

            for nftID in order.nfts {
                let nft = try await nftService.loadNft(id: nftID)
                loadedNfts.append(nft)
            }
            nfts = loadedNfts
        } catch {
            errorMessage = "Не удалось загрузить корзину"
        }
    }
}
