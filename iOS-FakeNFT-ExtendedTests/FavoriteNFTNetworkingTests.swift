import XCTest
@testable import iOS_FakeNFT_Extended

@MainActor
final class FavoriteNFTsViewModelTests: XCTestCase {
    func testLoadPublishesServerCardsAndDoesNotReloadOnReappearance() async {
        let service = FavoriteNFTServiceStub()
        let viewModel = FavoriteNFTsViewModel(service: service)
        XCTAssertTrue(viewModel.items.isEmpty)

        await viewModel.loadFavorites()
        await viewModel.loadFavorites()

        XCTAssertEqual(service.calls, 1)
        XCTAssertEqual(viewModel.items.map(\.id), ["server-id", "other-id"])
        XCTAssertEqual(viewModel.items.first?.name, "Server NFT")
        XCTAssertEqual(viewModel.items.first?.rating, 4)
        XCTAssertEqual(viewModel.items.first?.price, Decimal(235) / 100)
        XCTAssertNil(viewModel.items.first?.imageName)
        XCTAssertEqual(viewModel.items.first?.imageURL, URL(string: "https://example.com/nft.png"))
        XCTAssertNil(viewModel.loadingError)
    }

    func testRemovalWaitsForSuccessAndPreservesOtherCards() async {
        let service = FavoriteNFTServiceStub()
        let viewModel = FavoriteNFTsViewModel(service: service)
        await viewModel.loadFavorites()
        service.waitsForRemoval = true
        let removal = Task { await viewModel.removeFavorite(id: "server-id") }
        while service.removalContinuation == nil { await Task.yield() }
        XCTAssertEqual(viewModel.removingIDs, ["server-id"])
        await viewModel.removeFavorite(id: "server-id")
        XCTAssertEqual(service.removedIDs, ["server-id"])
        XCTAssertEqual(viewModel.items.map(\.id), ["server-id", "other-id"])
        service.removalContinuation?.resume()
        await removal.value
        XCTAssertTrue(viewModel.removingIDs.isEmpty)
        XCTAssertEqual(service.removedIDs, ["server-id"])
        XCTAssertEqual(viewModel.items.map(\.id), ["other-id"])
    }

    func testFailedRemovalKeepsCardAndCanBeRetried() async throws {
        let service = FavoriteNFTServiceStub()
        let viewModel = FavoriteNFTsViewModel(service: service)
        await viewModel.loadFavorites()
        service.error = URLError(.notConnectedToInternet)
        await viewModel.removeFavorite(id: "server-id")
        XCTAssertEqual(viewModel.items.map(\.id), ["server-id", "other-id"])
        XCTAssertNotNil(viewModel.removalError)
        XCTAssertTrue(viewModel.removingIDs.isEmpty)
        let failedID = try XCTUnwrap(viewModel.failedRemovalID)
        viewModel.dismissRemovalError()
        XCTAssertNil(viewModel.removalError)
        XCTAssertNil(viewModel.failedRemovalID)
        // The alert captures the NFT ID before SwiftUI dismisses it.
        await viewModel.removeFavorite(id: failedID)
        XCTAssertEqual(viewModel.failedRemovalID, failedID)
        XCTAssertNotNil(viewModel.removalError)
        XCTAssertTrue(viewModel.removingIDs.isEmpty)
        service.error = nil
        service.waitsForRemoval = true
        let retry = Task { await viewModel.removeFavorite(id: failedID) }
        while service.removalContinuation == nil { await Task.yield() }
        XCTAssertEqual(viewModel.removingIDs, [failedID])
        service.removalContinuation?.resume()
        await retry.value
        XCTAssertEqual(viewModel.items.map(\.id), ["other-id"])
        XCTAssertNil(viewModel.removalError)
        XCTAssertNil(viewModel.failedRemovalID)
        XCTAssertTrue(viewModel.removingIDs.isEmpty)
        XCTAssertEqual(service.removedIDs, [failedID, failedID, failedID])
    }

    func testFailedLoadCanBeRetried() async {
        let service = FavoriteNFTServiceStub()
        service.error = URLError(.notConnectedToInternet)
        let viewModel = FavoriteNFTsViewModel(service: service)

        await viewModel.loadFavorites()
        XCTAssertTrue(viewModel.items.isEmpty)
        XCTAssertNotNil(viewModel.loadingError)

        service.error = nil
        await viewModel.loadFavorites()
        XCTAssertEqual(service.calls, 2)
        XCTAssertEqual(viewModel.items.count, 2)
        XCTAssertNil(viewModel.loadingError)
    }

    func testCancelledLoadDoesNotPublishResponse() async {
        let service = FavoriteNFTServiceStub()
        let viewModel = FavoriteNFTsViewModel(service: service)
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            await viewModel.loadFavorites()
        }
        await task.value

        XCTAssertTrue(viewModel.items.isEmpty)
        XCTAssertNil(viewModel.loadingError)
        await viewModel.loadFavorites()
        XCTAssertEqual(viewModel.items.count, 2)
    }
}

@MainActor
private final class FavoriteNFTServiceStub: FavoriteNFTService {
    var removedIDs: [String] = []
    var removalContinuation: CheckedContinuation<Void, Error>?
    var waitsForRemoval = false

    func removeFavoriteNFT(id: String) async throws {
        removedIDs.append(id)
        if let error { throw error }
        if waitsForRemoval {
            try await withCheckedThrowingContinuation { removalContinuation = $0 }
        }
    }

    var calls = 0
    var error: Error?

    func loadFavoriteNFTs() async throws -> [Nft] {
        calls += 1
        if let error { throw error }
        return [Nft(
            id: "server-id", name: "Server NFT", rating: 4, price: Decimal(235) / 100,
            images: [URL(string: "https://example.com/nft.png")!, URL(string: "https://example.com/second.png")!]
        ), Nft(id: "other-id", name: "Other NFT", rating: 3, price: 1, images: [])]
    }
}

@MainActor
final class FavoriteNFTServiceTests: XCTestCase {
    func testRemovalPersistsOnlyRemainingLikesAndReloadsWithoutDeletedNFT() async throws {
        var likes = ["nft-1", "nft-2", "nft-3"]
        var bodies: [String] = []
        let service = makeService { request in
            if request.httpMethod == "PUT" {
                XCTAssertEqual(request.url?.path, "/api/v1/profile/1")
                XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/x-www-form-urlencoded")
                let body = try favoriteRequestBody(request)
                bodies.append(body)
                var components = URLComponents()
                components.percentEncodedQuery = body
                let fields = try XCTUnwrap(components.queryItems)
                XCTAssertEqual(fields.map(\.name), ["likes"])
                let value = try XCTUnwrap(fields.first?.value)
                guard !value.isEmpty else { return (406, Data()) }
                likes = value == "null" ? [] : value.split(separator: ",").map(String.init)
            }
            if request.url?.path == "/api/v1/profile/1" {
                return (200, try profileData(likes: likes))
            }
            return (200, nftData(id: try XCTUnwrap(request.url?.lastPathComponent)))
        }
        try await service.removeFavoriteNFT(id: "nft-2")
        let reloaded = try await service.loadFavoriteNFTs()
        XCTAssertEqual(reloaded.map(\.id), ["nft-1", "nft-3"])
        async let first: Void = service.removeFavoriteNFT(id: "nft-1")
        async let second: Void = service.removeFavoriteNFT(id: "nft-3")
        _ = try await (first, second)
        XCTAssertEqual(bodies.count, 3)
        XCTAssertEqual(bodies.last, "likes=null")
        let empty = try await service.loadFavoriteNFTs()
        XCTAssertTrue(empty.isEmpty)
    }

    func testFailedRemovalPropagatesAndDoesNotBlockNextRemoval() async throws {
        var shouldFail = true
        let service = makeService { request in
            if request.httpMethod == "PUT", shouldFail { return (503, Data()) }
            return (200, try profileData(likes: ["nft-1"]))
        }
        do {
            try await service.removeFavoriteNFT(id: "nft-1")
            XCTFail("Expected update error")
        } catch NetworkClientError.httpStatusCode(let code) {
            XCTAssertEqual(code, 503)
        }
        shouldFail = false
        try await service.removeFavoriteNFT(id: "nft-1")
    }

    func testLoadUsesLikesAndPreservesProfileOrder() async throws {
        var paths: [String] = []
        let service = makeService { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.value(forHTTPHeaderField: "X-Practicum-Mobile-Token"), RequestConstants.token)
            let path = try XCTUnwrap(request.url?.path)
            paths.append(path)

            switch path {
            case "/api/v1/profile/1":
                return (200, try profileData(likes: ["nft-2", "nft-1"]))
            case "/api/v1/nft/nft-2":
                return (200, nftData(id: "nft-2", name: "April", rating: 5, price: "8.81"))
            case "/api/v1/nft/nft-1":
                return (200, nftData(id: "nft-1", name: "Spring", rating: 3, price: "1.78"))
            default:
                XCTFail("Unexpected request: \(path)")
                return (404, Data())
            }
        }

        let favorites = try await service.loadFavoriteNFTs()

        XCTAssertEqual(paths, ["/api/v1/profile/1", "/api/v1/nft/nft-2", "/api/v1/nft/nft-1"])
        XCTAssertEqual(favorites.map(\.id), ["nft-2", "nft-1"])
        XCTAssertEqual(favorites.map(\.name), ["April", "Spring"])
        XCTAssertEqual(favorites.map(\.rating), [5, 3])
        XCTAssertEqual(favorites.map(\.price), [Decimal(881) / 100, Decimal(178) / 100])
        XCTAssertEqual(favorites.first?.images.map(\.absoluteString), [
            "https://example.com/nft-2/1.png", "https://example.com/nft-2/2.png"
        ])
    }

    func testEmptyLikesReturnsEmptyListWithoutNFTRequests() async throws {
        var paths: [String] = []
        let service = makeService { request in
            paths.append(try XCTUnwrap(request.url?.path))
            return (200, try profileData(likes: []))
        }

        let favorites = try await service.loadFavoriteNFTs()

        XCTAssertTrue(favorites.isEmpty)
        XCTAssertEqual(paths, ["/api/v1/profile/1"])
    }

    func testProfileHTTPErrorPropagatesWithoutNFTRequests() async {
        var paths: [String] = []
        let service = makeService { request in
            paths.append(try XCTUnwrap(request.url?.path))
            return (503, Data())
        }

        do {
            _ = try await service.loadFavoriteNFTs()
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
            _ = try await service.loadFavoriteNFTs()
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
                return (200, try profileData(likes: ["nft-1", "nft-2", "nft-3"]))
            case "/api/v1/nft/nft-1":
                return (200, nftData(id: "nft-1"))
            default:
                return (404, Data())
            }
        }

        do {
            _ = try await service.loadFavoriteNFTs()
            XCTFail("Expected NFT HTTP error")
        } catch NetworkClientError.httpStatusCode(let code) {
            XCTAssertEqual(code, 404)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        XCTAssertEqual(paths, ["/api/v1/profile/1", "/api/v1/nft/nft-1", "/api/v1/nft/nft-2"])
    }

    func testMalformedNFTPropagatesParsingError() async {
        let service = makeService { request in
            if request.url?.path == "/api/v1/profile/1" {
                return (200, try profileData(likes: ["nft-1"]))
            }
            // The fields needed by favorite cards must be present in the response.
            return (200, Data("{\"id\":\"nft-1\",\"images\":[]}".utf8))
        }

        do {
            _ = try await service.loadFavoriteNFTs()
            XCTFail("Expected NFT decoding error")
        } catch NetworkClientError.parsingError {
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testTransportErrorPropagates() async {
        let service = makeService { _ in throw URLError(.notConnectedToInternet) }

        do {
            _ = try await service.loadFavoriteNFTs()
            XCTFail("Expected transport error")
        } catch let error as URLError {
            XCTAssertEqual(error.code, .notConnectedToInternet)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testEachLoadUsesCurrentProfileLikes() async throws {
        var profileRequestCount = 0
        let service = makeService { request in
            if request.url?.path == "/api/v1/profile/1" {
                profileRequestCount += 1
                return (200, try profileData(likes: ["nft-\(profileRequestCount)"]))
            }
            return (200, nftData(id: try XCTUnwrap(request.url?.lastPathComponent)))
        }

        let first = try await service.loadFavoriteNFTs()
        let second = try await service.loadFavoriteNFTs()

        XCTAssertEqual(first.map(\.id), ["nft-1"])
        XCTAssertEqual(second.map(\.id), ["nft-2"])
        XCTAssertEqual(profileRequestCount, 2)
    }

    private func makeService(handler: @escaping FavoriteNFTURLProtocol.Handler) -> FavoriteNFTService {
        FavoriteNFTURLProtocol.handler = handler
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [FavoriteNFTURLProtocol.self]
        let session = URLSession(configuration: configuration)
        addTeardownBlock {
            session.invalidateAndCancel()
            FavoriteNFTURLProtocol.handler = nil
        }
        return ServicesAssembly(
            networkClient: DefaultNetworkClient(session: session),
            nftStorage: NftStorageImpl()
        ).favoriteNFTService
    }
}

private func profileData(likes: [String]) throws -> Data {
    try JSONSerialization.data(withJSONObject: [
        "id": "1", "name": "User", "avatar": "", "description": "", "website": "",
        "nfts": ["owned-only"], "likes": likes
    ])
}

private func nftData(id: String, name: String = "April", rating: Int = 5, price: String = "8.81") -> Data {
    Data("""
    {"id":"\(id)","name":"\(name)","rating":\(rating),"price":\(price),
    "images":["https://example.com/\(id)/1.png","https://example.com/\(id)/2.png"]}
    """.utf8)
}

private final class FavoriteNFTURLProtocol: URLProtocol {
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

private func favoriteRequestBody(_ request: URLRequest) throws -> String {
    if let data = request.httpBody {
        return try XCTUnwrap(String(data: data, encoding: .utf8))
    }
    let stream = try XCTUnwrap(request.httpBodyStream)
    stream.open()
    defer { stream.close() }
    var data = Data()
    var buffer = [UInt8](repeating: 0, count: 1024)
    while stream.hasBytesAvailable {
        let count = stream.read(&buffer, maxLength: buffer.count)
        guard count > 0 else { break }
        data.append(contentsOf: buffer.prefix(count))
    }
    return try XCTUnwrap(String(data: data, encoding: .utf8))
}
