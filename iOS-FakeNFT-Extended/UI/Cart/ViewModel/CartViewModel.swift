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
            
            let nftIDs = order.nfts
                .flatMap { $0.split(separator: ",") }
                .map {
                    String($0).trimmingCharacters(in: .whitespaces)
                }
                .filter { !$0.isEmpty }
            
            var loadedItems: [CartItem] = []
            
            for nftID in nftIDs {
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
            Logger.shared.error(
                "Ошибка загрузки корзины: \(error.localizedDescription, privacy: .public)"
            )
            
            errorMessage = NSLocalizedString(
                "Cart.error.load",
                comment: ""
            )
            
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
        
        let previousItems = items
        
        let updatedNFTIDs = items
            .filter { $0.id != item.id }
            .map { $0.id }
        
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
            
            errorMessage = NSLocalizedString(
                "Cart.error.delete",
                comment: ""
            )
            
            analyticsService.reportEvent(
                name: "item_delete_failed",
                parameters: [
                    "nft_id": item.id
                ]
            )
        }
    }
    
    
    func clearCart(isMockPayment: Bool) async -> Bool {
        guard !isLoading else {
            return false
        }
        guard !items.isEmpty else {
            errorMessage = "Корзина пуста"
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        defer {
            isLoading = false
        }
        
        let nftIDs = items.map { $0.id }
        
        do {
            try await cartService.completeOrder(
                id: "1",
                nftIDs: nftIDs
            )
            
            let serverOrder = try await cartService.loadOrder(id: "1")
            let remainingNFTs = serverOrder.nfts
                .flatMap { $0.split(separator: ",") }
                .map {
                    String($0).trimmingCharacters(in: .whitespaces)
                }
                .filter { !$0.isEmpty }
            
            guard remainingNFTs.isEmpty else {
                errorMessage = "Сервер не очистил заказ. NFT остались в корзине."
                return false
            }
            
            items = []
            
            analyticsService.reportEvent(
                name: "cart_cleared",
                parameters: [
                    "mock_payment": false,
                    "items_count": nftIDs.count
                ]
            )
            
            return true
            
        } catch {
            Logger.shared.error(
                "Ошибка завершения заказа: \(error.localizedDescription, privacy: .public)"
            )
            
            errorMessage = "Не удалось подтвердить завершение заказа. Корзина не очищена."
            
            analyticsService.reportEvent(
                name: "cart_clear_failed",
                parameters: [
                    "items_count": nftIDs.count
                ]
            )
            
            return false
        }
    }
}
