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
        XCTAssertEqual(viewModel.items.map(\.id), ["server-id"])
        XCTAssertEqual(viewModel.items.first?.name, "Server NFT")
        XCTAssertEqual(viewModel.items.first?.rating, 4)
        XCTAssertEqual(viewModel.items.first?.price, Decimal(235) / 100)
        XCTAssertNil(viewModel.items.first?.imageName)
        XCTAssertNil(viewModel.loadingError)
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
        XCTAssertEqual(viewModel.items.count, 1)
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
        XCTAssertEqual(viewModel.items.count, 1)
    }
}

@MainActor
private final class FavoriteNFTServiceStub: FavoriteNFTService {
    var calls = 0
    var error: Error?

    func loadFavoriteNFTs() async throws -> [Nft] {
        calls += 1
        if let error { throw error }
        return [Nft(id: "server-id", name: "Server NFT", rating: 4, price: Decimal(235) / 100, images: [])]
    }
}

@MainActor
final class FavoriteNFTServiceTests: XCTestCase {
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
