import XCTest
@testable import iOS_FakeNFT_Extended

@MainActor
final class ProfileServiceTests: XCTestCase {
    func testLoadDecodesAPIProfileUsingExistingClient() async throws {
        let service = makeService { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.url?.absoluteString, "\(RequestConstants.baseURL)/api/v1/profile/1")
            XCTAssertNil(request.httpBody)
            XCTAssertEqual(request.value(forHTTPHeaderField: "X-Practicum-Mobile-Token"), RequestConstants.token)
            return (200, profileJSON)
        }

        let profile = try await service.loadProfile()

        XCTAssertEqual(profile.id, "1")
        XCTAssertEqual(profile.name, "Серверное имя")
        XCTAssertEqual(profile.description, "Описание с сервера")
        XCTAssertEqual(profile.avatar, "https://example.com/avatar.png")
        XCTAssertEqual(profile.website, "https://example.com/site")
        XCTAssertEqual(profile.nfts, ["nft-1", "nft-2"])
        XCTAssertEqual(profile.likes, ["nft-2"])
    }

    func testSaveEncodesEditableFieldsAndReturnsServerProfile() async throws {
        let update = ProfileUpdate(
            name: "Имя + & = 🎨",
            description: "Строка 1\n100% + искусство & NFT",
            avatar: "https://example.com/photo.png?size=70&name=a+b",
            website: "https://example.com/?q=a+b&next=c=d#section"
        )
        let service = makeService { request in
            XCTAssertEqual(request.httpMethod, "PUT")
            XCTAssertEqual(request.url?.path, "/api/v1/profile/1")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/x-www-form-urlencoded")
            XCTAssertEqual(request.value(forHTTPHeaderField: "X-Practicum-Mobile-Token"), RequestConstants.token)
            let fields = try decodeForm(request)
            XCTAssertEqual(fields, [
                "name": update.name, "description": update.description,
                "avatar": update.avatar, "website": update.website
            ])
            // Profile editing must leave NFT ownership and favorites to their own services.
            XCTAssertNil(fields["id"])
            XCTAssertNil(fields["nfts"])
            XCTAssertNil(fields["likes"])
            return (200, profileJSON)
        }

        let saved = try await service.saveProfile(update)

        XCTAssertEqual(saved.name, "Серверное имя")
        XCTAssertEqual(saved.nfts, ["nft-1", "nft-2"])
        XCTAssertEqual(saved.likes, ["nft-2"])
    }

    func testSaveIncludesEmptyFieldsToClearProfileValues() async throws {
        let service = makeService { request in
            XCTAssertEqual(try decodeForm(request), ["name": "", "description": "", "avatar": "", "website": ""])
            return (200, profileJSON)
        }
        _ = try await service.saveProfile(ProfileUpdate(name: "", description: "", avatar: "", website: ""))
    }

    func testLoadPropagatesHTTPError() async {
        let service = makeService { _ in (503, Data()) }
        do {
            _ = try await service.loadProfile()
            XCTFail("Expected HTTP error")
        } catch NetworkClientError.httpStatusCode(let code) {
            XCTAssertEqual(code, 503)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testSavePropagatesInvalidResponse() async {
        let service = makeService { _ in (200, Data("{}".utf8)) }
        do {
            _ = try await service.saveProfile(ProfileUpdate(name: "Name", description: "", avatar: "", website: ""))
            XCTFail("Expected decoding error")
        } catch NetworkClientError.parsingError {
            // The server response, rather than the submitted draft, is decoded.
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testExistingRequestsStillEncodeJSON() async throws {
        let client = makeClient { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
            let data = try requestBody(request)
            let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: String])
            XCTAssertEqual(json, ["name": "JSON + &"])
            return (200, profileJSON)
        }
        let _: Profile = try await client.send(request: JSONTestRequest())
    }

    private func makeService(handler: @escaping ProfileURLProtocol.Handler) -> ProfileService {
        ProfileServiceImpl(networkClient: makeClient(handler: handler))
    }

    private func makeClient(handler: @escaping ProfileURLProtocol.Handler) -> DefaultNetworkClient {
        ProfileURLProtocol.handler = handler
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [ProfileURLProtocol.self]
        let session = URLSession(configuration: configuration)
        addTeardownBlock {
            session.invalidateAndCancel()
            ProfileURLProtocol.handler = nil
        }
        return DefaultNetworkClient(session: session)
    }
}

@MainActor
final class ProfileLoadingTests: XCTestCase {
    func testLoadReplacesEmptyStateWithServerData() async throws {
        let response = try JSONDecoder().decode(Profile.self, from: profileJSON)
        let service = ProfileServiceStub(response: response)
        let model = ProfileViewModel(profileService: service)
        XCTAssertEqual(model.profile, .empty)
        XCTAssertNil(model.loadedProfile)
        XCTAssertNil(model.profile.avatarAssetName)

        await model.loadProfile()

        XCTAssertEqual(model.loadedProfile, response)
        XCTAssertEqual(model.profile.name, response.name)
        XCTAssertEqual(model.profile.biography, response.description)
        XCTAssertEqual(model.profile.websiteTitle, response.website)
        XCTAssertEqual(model.websiteURL?.absoluteString, response.website)
        XCTAssertEqual(model.profile.avatarURL?.absoluteString, response.avatar)
        XCTAssertEqual(model.profile.ownedNFTCount, 2)
        XCTAssertEqual(model.profile.favoriteNFTCount, 1)
        XCTAssertNil(model.profile.avatarAssetName)
        XCTAssertNil(model.loadingError)
    }

    func testFailedReloadPreservesLastProfile() async throws {
        let response = try JSONDecoder().decode(Profile.self, from: profileJSON)
        let service = ProfileServiceStub(response: response)
        let model = ProfileViewModel(profileService: service)
        await model.loadProfile()
        let loaded = model.profile

        await service.setError(URLError(.notConnectedToInternet))
        await model.loadProfile()
        XCTAssertEqual(model.profile, loaded)
        XCTAssertNotNil(model.loadingError)

        await service.setError(nil)
        await model.loadProfile()
        XCTAssertNil(model.loadingError)
    }

    func testCancelledLoadDoesNotPublishResponse() async throws {
        let response = try JSONDecoder().decode(Profile.self, from: profileJSON)
        let model = ProfileViewModel(profileService: ProfileServiceStub(response: response))
        let task = Task { await model.loadProfile() }
        task.cancel()
        await task.value

        XCTAssertEqual(model.profile, .empty)
        XCTAssertNil(model.loadingError)
    }

    func testEmptyAvatarUsesPlaceholderAndEmptyListsHaveZeroCounts() throws {
        let response = Profile(id: "1", name: "Name", avatar: "", description: "", website: "", nfts: [], likes: [])
        let profile = UserProfile(profile: response)
        XCTAssertNil(profile.avatarURL)
        XCTAssertNil(profile.avatarAssetName)
        XCTAssertEqual(profile.ownedNFTCount, 0)
        XCTAssertEqual(profile.favoriteNFTCount, 0)
    }
}

private let profileJSON = Data("""
{"id":"1","name":"Серверное имя","avatar":"https://example.com/avatar.png",
"description":"Описание с сервера","website":"https://example.com/site",
"nfts":["nft-1","nft-2"],"likes":["nft-2"]}
""".utf8)

private func decodeForm(_ request: URLRequest) throws -> [String: String] {
    let body = try XCTUnwrap(String(data: requestBody(request), encoding: .utf8))
    var components = URLComponents()
    components.percentEncodedQuery = body.replacingOccurrences(of: "+", with: " ")
    return Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") })
}

private func requestBody(_ request: URLRequest) throws -> Data {
    var data = request.httpBody
    if data == nil, let stream = request.httpBodyStream {
        stream.open()
        defer { stream.close() }
        var buffer = [UInt8](repeating: 0, count: 1024)
        var body = Data()
        while stream.hasBytesAvailable {
            let count = stream.read(&buffer, maxLength: buffer.count)
            guard count > 0 else { break }
            body.append(contentsOf: buffer.prefix(count))
        }
        data = body
    }
    return try XCTUnwrap(data)
}

private struct JSONTestRequest: NetworkRequest {
    var endpoint: URL? { ProfileRequest().endpoint }
    var httpMethod: HttpMethod { .put }
    var dto: Encodable? { ["name": "JSON + &"] }
}

private actor ProfileServiceStub: ProfileService {
    let response: Profile
    var error: Error?

    init(response: Profile) { self.response = response }

    func setError(_ error: Error?) { self.error = error }

    func loadProfile() async throws -> Profile {
        if let error { throw error }
        return response
    }

    func saveProfile(_ profile: ProfileUpdate) async throws -> Profile {
        try await loadProfile()
    }

    func saveLikes(_ ids: [String]) async throws -> Profile {
        try await loadProfile()
    }
}

private final class ProfileURLProtocol: URLProtocol {
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
