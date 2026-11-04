import XCTest
@testable import iOS_FakeNFT_Extended

@MainActor
final class OwnedNFTsLoadingTests: XCTestCase {
    func testEmptyStateRequiresSuccessfulLoadAndRetryClearsErrorWhileLoading() async {
        let service = OwnedNFTServiceStub()
        let viewModel = OwnedNFTsViewModel(service: service, settingsService: OwnedNFTLoadingSettingsStub())
        XCTAssertFalse(viewModel.isEmpty)
        XCTAssertFalse(viewModel.hasLoaded)

        service.error = URLError(.notConnectedToInternet)
        for _ in 0..<2 {
            await viewModel.loadOwnedNFTs()
            XCTAssertNotNil(viewModel.loadingError)
            XCTAssertFalse(viewModel.isEmpty)
            XCTAssertFalse(viewModel.isLoading)
        }

        let started = expectation(description: "Retry started")
        var continuation: CheckedContinuation<Void, Never>?
        service.onLoad = {
            await withCheckedContinuation {
                continuation = $0
                started.fulfill()
            }
        }
        service.error = nil
        service.response = []
        let retry = Task { await viewModel.loadOwnedNFTs() }
        await fulfillment(of: [started], timeout: 2)
        XCTAssertTrue(viewModel.isLoading)
        XCTAssertNil(viewModel.loadingError)
        XCTAssertFalse(viewModel.isEmpty)
        await viewModel.loadOwnedNFTs()
        XCTAssertEqual(service.calls, 3)

        continuation?.resume()
        await retry.value
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertTrue(viewModel.hasLoaded)
        XCTAssertTrue(viewModel.isEmpty)
        XCTAssertNil(viewModel.loadingError)
    }

    func testLoadPublishesServerDataAndUsesSelectedSortOption() async {
        let service = OwnedNFTServiceStub()
        let viewModel = OwnedNFTsViewModel(service: service, settingsService: OwnedNFTLoadingSettingsStub())
        viewModel.selectSortOption(.price)
        XCTAssertTrue(viewModel.items.isEmpty)

        await viewModel.loadOwnedNFTs()

        XCTAssertEqual(service.calls, 1)
        XCTAssertEqual(viewModel.items.map(\.id), ["other-id", "server-id"])
        let item = viewModel.items.last
        XCTAssertEqual(item?.name, "Server NFT")
        XCTAssertEqual(item?.author, "Alice")
        XCTAssertEqual(item?.rating, 4)
        XCTAssertEqual(item?.price, Decimal(235) / 100)
        XCTAssertEqual(item?.formattedPrice, "2,35 ETH")
        XCTAssertNil(item?.imageName)
        XCTAssertEqual(item?.imageURL, URL(string: "https://example.com/nft.png"))
        XCTAssertNil(viewModel.items.first?.imageURL)
        XCTAssertNil(viewModel.loadingError)
    }

    func testSuccessfulLoadReplacesListAndClearsItForEmptyResponse() async {
        let service = OwnedNFTServiceStub()
        let viewModel = OwnedNFTsViewModel(service: service, settingsService: OwnedNFTLoadingSettingsStub())
        await viewModel.loadOwnedNFTs()
        XCTAssertFalse(viewModel.items.isEmpty)

        service.response = [Nft(id: "added-id", name: "Added NFT", author: "Carol", rating: 5, price: 3, images: [])]
        await viewModel.loadOwnedNFTs()
        XCTAssertEqual(viewModel.items.map(\.id), ["added-id"])

        service.response = []
        await viewModel.loadOwnedNFTs()
        XCTAssertEqual(service.calls, 3)
        XCTAssertTrue(viewModel.items.isEmpty)
        XCTAssertTrue(viewModel.isEmpty)
    }

    func testFailedLoadPreservesListAndCanBeRetried() async {
        let service = OwnedNFTServiceStub()
        let viewModel = OwnedNFTsViewModel(service: service, settingsService: OwnedNFTLoadingSettingsStub())
        await viewModel.loadOwnedNFTs()
        let loadedIDs = viewModel.items.map(\.id)

        service.error = URLError(.notConnectedToInternet)
        await viewModel.loadOwnedNFTs()
        XCTAssertEqual(viewModel.items.map(\.id), loadedIDs)
        XCTAssertNotNil(viewModel.loadingError)

        service.error = nil
        service.response = []
        await viewModel.loadOwnedNFTs()
        XCTAssertTrue(viewModel.items.isEmpty)
        XCTAssertNil(viewModel.loadingError)
    }

    func testConcurrentLoadDoesNotStartDuplicateRequestOrClearList() async {
        let service = OwnedNFTServiceStub()
        let viewModel = OwnedNFTsViewModel(service: service, settingsService: OwnedNFTLoadingSettingsStub())
        await viewModel.loadOwnedNFTs()
        let loadedIDs = viewModel.items.map(\.id)
        let started = expectation(description: "Owned NFT load started")
        var continuation: CheckedContinuation<Void, Never>?
        service.onLoad = {
            await withCheckedContinuation {
                continuation = $0
                started.fulfill()
            }
        }
        service.response = []
        let load = Task { await viewModel.loadOwnedNFTs() }
        await fulfillment(of: [started], timeout: 2)

        await viewModel.loadOwnedNFTs()
        XCTAssertEqual(service.calls, 2)
        XCTAssertEqual(viewModel.items.map(\.id), loadedIDs)

        continuation?.resume()
        await load.value
        XCTAssertTrue(viewModel.items.isEmpty)
    }

    func testCancelledLoadDoesNotPublishResponseAndAllowsAnotherLoad() async {
        let service = OwnedNFTServiceStub()
        let viewModel = OwnedNFTsViewModel(service: service, settingsService: OwnedNFTLoadingSettingsStub())
        let started = expectation(description: "Owned NFT load started")
        var continuation: CheckedContinuation<Void, Never>?
        service.onLoad = {
            await withCheckedContinuation {
                continuation = $0
                started.fulfill()
            }
        }
        let load = Task { await viewModel.loadOwnedNFTs() }
        await fulfillment(of: [started], timeout: 2)
        load.cancel()
        continuation?.resume()
        await load.value

        XCTAssertTrue(viewModel.items.isEmpty)
        XCTAssertNil(viewModel.loadingError)

        service.onLoad = nil
        await viewModel.loadOwnedNFTs()
        XCTAssertEqual(service.calls, 2)
        XCTAssertFalse(viewModel.items.isEmpty)
    }
}

@MainActor
private final class OwnedNFTServiceStub: OwnedNFTService {
    var response = [
        Nft(id: "server-id", name: "Server NFT", author: "Alice", rating: 4, price: Decimal(235) / 100,
            images: [URL(string: "https://example.com/nft.png")!, URL(string: "https://example.com/other.png")!]),
        Nft(id: "other-id", name: "Other NFT", author: "Bob", rating: 2, price: 1, images: [])
    ]
    var error: Error?
    var calls = 0
    var onLoad: (() async -> Void)?

    func loadOwnedNFTs() async throws -> [Nft] {
        calls += 1
        await onLoad?()
        if let error { throw error }
        return response
    }
}

private final class OwnedNFTLoadingSettingsStub: UserSettingsServiceProtocol {
    var ownedNFTSortOption: OwnedNFTSortOption = .rating
}

@MainActor
final class OwnedNFTServiceTests: XCTestCase {
    func testLoadUsesOwnedIDsAndDecodesAllNFTFields() async throws {
        var paths: [String] = []
        let service = makeService { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.value(forHTTPHeaderField: "X-Practicum-Mobile-Token"), RequestConstants.token)
            let path = try XCTUnwrap(request.url?.path)
            paths.append(path)
            switch path {
            case "/api/v1/profile/1":
                return (200, try ownedProfileData(nfts: ["nft-2", "nft-1"]))
            case "/api/v1/nft/nft-2":
                return (200, ownedNFTData(id: "nft-2", author: "Alice"))
            case "/api/v1/nft/nft-1":
                return (200, ownedNFTData(id: "nft-1", author: "Bob"))
            default:
                XCTFail("Unexpected request: \(path)")
                return (404, Data())
            }
        }

        let nfts = try await service.loadOwnedNFTs()

        XCTAssertEqual(paths, ["/api/v1/profile/1", "/api/v1/nft/nft-2", "/api/v1/nft/nft-1"])
        XCTAssertEqual(nfts.map(\.id), ["nft-2", "nft-1"])
        XCTAssertEqual(nfts.map(\.author), ["Alice", "Bob"])
        XCTAssertEqual(nfts.first?.name, "April")
        XCTAssertEqual(nfts.first?.rating, 5)
        XCTAssertEqual(nfts.first?.price, Decimal(881) / 100)
        XCTAssertEqual(nfts.first?.images.map(\.absoluteString), [
            "https://example.com/nft-2/1.png", "https://example.com/nft-2/2.png"
        ])
    }

    func testEmptyOwnedIDsReturnsEmptyListWithoutLoadingLikes() async throws {
        var paths: [String] = []
        let service = makeService { request in
            paths.append(try XCTUnwrap(request.url?.path))
            return (200, try ownedProfileData(nfts: []))
        }

        let nfts = try await service.loadOwnedNFTs()

        XCTAssertTrue(nfts.isEmpty)
        XCTAssertEqual(paths, ["/api/v1/profile/1"])
    }

    func testProfileHTTPErrorPropagatesWithoutNFTRequests() async {
        var paths: [String] = []
        let service = makeService { request in
            paths.append(try XCTUnwrap(request.url?.path))
            return (503, Data())
        }

        do {
            _ = try await service.loadOwnedNFTs()
            XCTFail("Expected profile HTTP error")
        } catch NetworkClientError.httpStatusCode(let code) {
            XCTAssertEqual(code, 503)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        XCTAssertEqual(paths, ["/api/v1/profile/1"])
    }

    func testMalformedProfilePropagatesParsingError() async {
        let service = makeService { _ in (200, Data("{}".utf8)) }

        do {
            _ = try await service.loadOwnedNFTs()
            XCTFail("Expected profile decoding error")
        } catch NetworkClientError.parsingError {
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testNFTErrorPropagatesInsteadOfReturningPartialList() async {
        var paths: [String] = []
        let service = makeService { request in
            let path = try XCTUnwrap(request.url?.path)
            paths.append(path)
            switch path {
            case "/api/v1/profile/1":
                return (200, try ownedProfileData(nfts: ["nft-1", "nft-2", "nft-3"]))
            case "/api/v1/nft/nft-1":
                return (200, ownedNFTData(id: "nft-1"))
            default:
                return (404, Data())
            }
        }

        do {
            _ = try await service.loadOwnedNFTs()
            XCTFail("Expected NFT HTTP error")
        } catch NetworkClientError.httpStatusCode(let code) {
            XCTAssertEqual(code, 404)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        XCTAssertEqual(paths, ["/api/v1/profile/1", "/api/v1/nft/nft-1", "/api/v1/nft/nft-2"])
    }

    func testMissingAuthorPropagatesParsingError() async {
        let service = makeService { request in
            if request.url?.path == "/api/v1/profile/1" {
                return (200, try ownedProfileData(nfts: ["nft-1"]))
            }
            return (200, Data("""
            {"id":"nft-1","name":"April","rating":5,"price":8.81,"images":[]}
            """.utf8))
        }

        do {
            _ = try await service.loadOwnedNFTs()
            XCTFail("Expected NFT decoding error")
        } catch NetworkClientError.parsingError {
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testTransportErrorPropagates() async {
        let service = makeService { _ in throw URLError(.notConnectedToInternet) }

        do {
            _ = try await service.loadOwnedNFTs()
            XCTFail("Expected transport error")
        } catch let error as URLError {
            XCTAssertEqual(error.code, .notConnectedToInternet)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testEachLoadUsesCurrentOwnedIDsAndReusesCachedNFTs() async throws {
        var profileRequests = 0
        var nftRequests = 0
        let service = makeService { request in
            if request.url?.path == "/api/v1/profile/1" {
                profileRequests += 1
                return (200, try ownedProfileData(nfts: profileRequests == 1 ? ["nft-1"] : ["nft-2", "nft-1"]))
            }
            nftRequests += 1
            return (200, ownedNFTData(id: try XCTUnwrap(request.url?.lastPathComponent)))
        }

        let first = try await service.loadOwnedNFTs()
        let second = try await service.loadOwnedNFTs()

        XCTAssertEqual(first.map(\.id), ["nft-1"])
        XCTAssertEqual(second.map(\.id), ["nft-2", "nft-1"])
        XCTAssertEqual(second.map(\.author), ["Alice", "Alice"])
        XCTAssertEqual(profileRequests, 2)
        XCTAssertEqual(nftRequests, 2)
    }

    func testCancelledLoadDoesNotRequestProfile() async {
        var requests = 0
        let service = makeService { _ in
            requests += 1
            return (200, try ownedProfileData(nfts: []))
        }
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await service.loadOwnedNFTs()
        }

        do {
            _ = try await task.value
            XCTFail("Expected cancellation")
        } catch is CancellationError {
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        XCTAssertEqual(requests, 0)
    }

    private func makeService(handler: @escaping OwnedNFTURLProtocol.Handler) -> OwnedNFTService {
        OwnedNFTURLProtocol.handler = handler
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [OwnedNFTURLProtocol.self]
        let session = URLSession(configuration: configuration)
        addTeardownBlock {
            session.invalidateAndCancel()
            OwnedNFTURLProtocol.handler = nil
        }
        return ServicesAssembly(
            networkClient: DefaultNetworkClient(session: session),
            nftStorage: NftStorageImpl()
        ).ownedNFTService
    }
}

private func ownedProfileData(nfts: [String]) throws -> Data {
    try JSONSerialization.data(withJSONObject: [
        "id": "1", "name": "User", "avatar": "", "description": "", "website": "",
        "nfts": nfts, "likes": ["favorite-only"]
    ])
}

private func ownedNFTData(id: String, author: String = "Alice") -> Data {
    Data("""
    {"id":"\(id)","name":"April","author":"\(author)","rating":5,"price":8.81,
    "images":["https://example.com/\(id)/1.png","https://example.com/\(id)/2.png"]}
    """.utf8)
}

private final class OwnedNFTURLProtocol: URLProtocol {
    typealias Handler = (URLRequest) throws -> (Int, Data)
    static var handler: Handler?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        do {
            let handler = try XCTUnwrap(Self.handler)
            let (status, data) = try handler(request)
            let response = try XCTUnwrap(HTTPURLResponse(
                url: XCTUnwrap(request.url), statusCode: status, httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            ))
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
