//
//  CartViewModel.swift
//  iOS-FakeNFT-Extended
//
//  Created by Leo Gabuev on 21.10.2026.
//


import Foundation
import OSLog

enum CartSortOption {
    case price
    case rating
    case name
}

@Observable
@MainActor
final class CartViewModel {
    
    private let cartService: CartServiceLocalProtocol
    private let nftService: NftService
    private let analyticsService: AnalyticsService
    
    private(set) var items: [CartItem] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    
    init(
        cartService: CartServiceLocalProtocol,
        nftService: NftService,
        analyticsService: AnalyticsService
    ) {
        self.cartService = cartService
        self.nftService = nftService
        self.analyticsService = analyticsService
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
        
        analyticsService.reportEvent(
            name: "cart_sorted",
            parameters: [
                "sort_option": String(describing: option)
            ]
        )
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
                    rating: min(5, max(0, nft.rating / 2)),
                    price: NSDecimalNumber(decimal: nft.price).doubleValue
                )
                
                loadedItems.append(item)
            }
            
            items = loadedItems
            
            analyticsService.reportEvent(
                name: "cart_loaded",
                parameters: [
                    "items_count": items.count
                ]
            )
            
        } catch {
            Logger.shared.error("Ошибка загрузки корзины: \(error.localizedDescription, privacy: .public)")
            items = CartMockData.items
            errorMessage = NSLocalizedString("Cart.error.load", comment: "")
            
            analyticsService.reportEvent(
                name: "cart_load_failed",
                parameters: [:]
            )
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
        
        let previousItems = items
        
        items.removeAll { $0.id == item.id }
        
        do {
            try await cartService.updateOrder(
                id: "1",
                nftIDs: updatedNFTIDs
            )
            
            analyticsService.reportEvent(
                name: "item_deleted",
                parameters: [
                    "nft_id": item.id
                ]
            )
            
        } catch {
    
            items = previousItems
            errorMessage = NSLocalizedString("Cart.error.delete", comment: "")
            
            analyticsService.reportEvent(
                name: "item_delete_failed",
                parameters: [
                    "nft_id": item.id
                ]
            )
        }
    }
    
    func clearCart(isMockPayment: Bool) async -> Bool {
        guard !isLoading else { return false }
        
        isLoading = true
        errorMessage = nil
        
        defer {
            isLoading = false
        }
        
        if isMockPayment {
            items = []
            
            analyticsService.reportEvent(
                name: "cart_cleared",
                parameters: [
                    "mock_payment": true
                ]
            )
            
            return true
        }
        
        do {
            try await cartService.updateOrder(
                id: "1",
                nftIDs: []
            )
            
            items = []
            
            analyticsService.reportEvent(
                name: "cart_cleared",
                parameters: [
                    "mock_payment": false
                ]
            )
            
            return true
            
        } catch {
            Logger.shared.error("Ошибка очистки корзины через API: \(error.localizedDescription, privacy: .public)")
            Logger.shared.info("Используем локальную очистку корзины.")
            
            items = []
            
            analyticsService.reportEvent(
                name: "cart_cleared",
                parameters: [
                    "mock_payment": false
                ]
            )
            
            return true
        }
    }
}
