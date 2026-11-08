//
//  CartViewModelTests.swift
//  iOS-FakeNFT-ExtendedTests
//
//  Created by Leo Gabuev on 08.11.2026.
//


import XCTest
@testable import iOS_FakeNFT_Extended

@MainActor
final class CartViewModelTests: XCTestCase {

    private func makeNFT(
        id: String,
        name: String,
        rating: Int,
        price: Double
    ) -> Nft {
        Nft(
            id: id,
            name: name,
            imagesURLs: [],
            rating: rating,
            price: price
        )
    }

    private func makeViewModel(
        order: Order,
        nfts: [String: Result<Nft, Error>],
        updateResult: Result<Void, Error> = .success(())
    ) -> CartViewModel {
        CartViewModel(
            cartService: MockCartService(
                loadOrderResult: .success(order),
                updateOrderResult: updateResult
            ),
            nftService: MockNftService(results: nfts),
            analyticsService: MockAnalyticsService()
        )
    }

    private func makeLoadedViewModel() async -> CartViewModel {
        let order = Order(id: "1", nfts: ["1", "2", "3"])

        let nfts: [String: Result<Nft, Error>] = [
            "1": .success(makeNFT(id: "1", name: "April", rating: 1, price: 3.5)),
            "2": .success(makeNFT(id: "2", name: "Greena", rating: 3, price: 1.5)),
            "3": .success(makeNFT(id: "3", name: "Spring", rating: 5, price: 2.5))
        ]

        let viewModel = makeViewModel(order: order, nfts: nfts)
        await viewModel.loadCart()
        return viewModel
    }

    // MARK: - Loading

    func testLoadCartSuccess() async {
        let viewModel = await makeLoadedViewModel()

        XCTAssertEqual(viewModel.items.count, 3)
        XCTAssertEqual(viewModel.items.first?.name, "April")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testLoadCartFailure() async {
        let cartService = MockCartService(
            loadOrderResult: .failure(NSError(domain: "Test", code: 1)),
            updateOrderResult: .success(())
        )

        let nftService = MockNftService(results: [:])

        let viewModel = CartViewModel(
            cartService: cartService,
            nftService: nftService,
            analyticsService: MockAnalyticsService()
        )

        await viewModel.loadCart()

        XCTAssertEqual(viewModel.items.count, CartMockData.items.count)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }

    // MARK: - Sorting

    func testSortItemsByPrice() async {
        let viewModel = await makeLoadedViewModel()

        viewModel.sortItems(by: .price)

        XCTAssertEqual(
            viewModel.items.map(\.price),
            [1.5, 2.5, 3.5]
        )
    }

    func testSortItemsByRating() async {
        let viewModel = await makeLoadedViewModel()

        viewModel.sortItems(by: .rating)

        XCTAssertEqual(
            viewModel.items.map(\.rating),
            [5, 3, 1]
        )
    }

    func testSortItemsByName() async {
        let viewModel = await makeLoadedViewModel()

        viewModel.sortItems(by: .name)

        XCTAssertEqual(
            viewModel.items.map(\.name),
            ["April", "Greena", "Spring"]
        )
    }

    // MARK: - Removing

    func testRemoveItemSuccess() async {
        let viewModel = await makeLoadedViewModel()
        let itemToRemove = viewModel.items[0]

        await viewModel.removeItem(itemToRemove)

        XCTAssertEqual(viewModel.items.count, 2)
        XCTAssertFalse(viewModel.items.contains { $0.id == itemToRemove.id })
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testRemoveItemFailure() async {
        let order = Order(id: "1", nfts: ["1", "2", "3"])

        let nfts: [String: Result<Nft, Error>] = [
            "1": .success(makeNFT(id: "1", name: "April", rating: 1, price: 3.5)),
            "2": .success(makeNFT(id: "2", name: "Greena", rating: 3, price: 1.5)),
            "3": .success(makeNFT(id: "3", name: "Spring", rating: 5, price: 2.5))
        ]

        let viewModel = makeViewModel(
            order: order,
            nfts: nfts,
            updateResult: .failure(NSError(domain: "Test", code: 1))
        )

        await viewModel.loadCart()
        let itemToRemove = viewModel.items[0]

        await viewModel.removeItem(itemToRemove)

        XCTAssertEqual(viewModel.items.count, 3)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }

    // MARK: - Clearing

    func testClearCartWithMockPayment() async {
        let viewModel = await makeLoadedViewModel()

        let result = await viewModel.clearCart(isMockPayment: true)

        XCTAssertTrue(result)
        XCTAssertTrue(viewModel.items.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testClearCartSuccess() async {
        let viewModel = await makeLoadedViewModel()

        let result = await viewModel.clearCart(isMockPayment: false)

        XCTAssertTrue(result)
        XCTAssertTrue(viewModel.items.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testClearCartFailureStillClearsLocally() async {
        let order = Order(id: "1", nfts: ["1"])

        let nfts: [String: Result<Nft, Error>] = [
            "1": .success(makeNFT(id: "1", name: "April", rating: 1, price: 3.5))
        ]

        let viewModel = makeViewModel(
            order: order,
            nfts: nfts,
            updateResult: .failure(NSError(domain: "Test", code: 1))
        )

        await viewModel.loadCart()

        let result = await viewModel.clearCart(isMockPayment: false)

        XCTAssertTrue(result)
        XCTAssertTrue(viewModel.items.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
    }
}
