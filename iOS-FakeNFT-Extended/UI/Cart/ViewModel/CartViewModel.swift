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
    
    private(set) var items: [CartItem] = []
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
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        defer {
            isLoading = false
        }
        
        do {
            let order = try await cartService.loadOrder(id: "1")
            
            var loadedItems: [CartItem] = []
            
            for nftID in order.nfts {
                let nft = try await nftService.loadNft(id: nftID)
                
                let item = CartItem(
                    id: nft.id,
                    imageName: nft.imagesURLs.first?.absoluteString ?? "",
                    name: nft.name,
                    rating: nft.rating,
                    price: nft.price
                )
                
                loadedItems.append(item)
            }
            
            items = loadedItems
            
        } catch {
            print("Ошибка загрузки корзины: \(error)")
            // Временно использовать CartMockData.items для проверки UI,пока сервер недоступен.
             items = CartMockData.items
            errorMessage = "Не удалось загрузить корзину. Попробуйте ещё раз."
        }
    }
}
