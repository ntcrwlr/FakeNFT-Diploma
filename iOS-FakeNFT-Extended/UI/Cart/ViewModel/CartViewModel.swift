//
//  CartViewModel.swift
//  iOS-FakeNFT-Extended
//
//  Created by Leo Gabuev on 21.10.2026.
//


import Foundation

enum CartSortOption {
    case price
    case rating
    case name
}

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
    
    func sortItems(by option: CartSortOption) {
        switch option {
        case .price:
            items.sort { $0.price < $1.price }
        case .rating:
            items.sort { $0.rating > $1.rating }
        case .name:
            items.sort {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        }
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
    
    func removeItem(_ item: CartItem) async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        let updatedNFTIDs = items
            .filter { $0.id != item.id }
            .map { $0.id }

        do {
            try await cartService.updateOrder(
                id: "1",
                nftIDs: updatedNFTIDs
            )

            items.removeAll { $0.id == item.id }
        } catch {
            print("Ошибка удаления NFT: \(error)")
            errorMessage = "Не удалось удалить NFT. Попробуйте ещё раз."
        }
    }
}
