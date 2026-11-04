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
    func testLoadingStatePreventsDuplicatesAndClearsErrorBeforeRetry() async throws {
        let response = try JSONDecoder().decode(Profile.self, from: profileJSON)
        let service = DeferredProfileService(response: response)
        let model = ProfileViewModel(profileService: service)
        XCTAssertFalse(model.isLoading)
        XCTAssertFalse(model.hasLoaded)
        service.error = URLError(.notConnectedToInternet)
        await model.loadProfile()
        XCTAssertNotNil(model.loadingError)
        XCTAssertFalse(model.hasLoaded)
        XCTAssertFalse(model.isLoading)

        service.error = nil
        let started = expectation(description: "Retry started")
        var continuation: CheckedContinuation<Void, Never>?
        service.onLoad = {
            await withCheckedContinuation {
                continuation = $0
                started.fulfill()
            }
        }
        let retry = Task { await model.loadProfile() }
        await fulfillment(of: [started], timeout: 2)
        XCTAssertTrue(model.isLoading)
        XCTAssertNil(model.loadingError)
        XCTAssertFalse(model.hasLoaded)
        await model.loadProfile()
        XCTAssertEqual(service.loadCalls, 2)

        continuation?.resume()
        await retry.value
        XCTAssertFalse(model.isLoading)
        XCTAssertTrue(model.hasLoaded)
        XCTAssertEqual(model.profile, UserProfile(profile: response))
        XCTAssertNil(model.loadingError)
    }

    func testRepeatedLoadFailureAllowsAnotherRetry() async throws {
        let response = try JSONDecoder().decode(Profile.self, from: profileJSON)
        let service = ProfileServiceStub(response: response)
        let model = ProfileViewModel(profileService: service)
        await service.setError(URLError(.notConnectedToInternet))
        for _ in 0..<2 {
            await model.loadProfile()
            XCTAssertNotNil(model.loadingError)
            XCTAssertFalse(model.isLoading)
            XCTAssertFalse(model.hasLoaded)
            XCTAssertEqual(model.profile, .empty)
        }
        await service.setError(nil)
        await model.loadProfile()
        XCTAssertTrue(model.hasLoaded)
        XCTAssertNil(model.loadingError)
    }

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
        XCTAssertTrue(model.hasLoaded)
        XCTAssertFalse(model.isLoading)
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
        XCTAssertTrue(model.hasLoaded)
        XCTAssertFalse(model.isLoading)

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
        XCTAssertFalse(model.hasLoaded)
        XCTAssertFalse(model.isLoading)
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

@MainActor
final class ProfileEditingTests: XCTestCase {
    func testRepeatedSaveFailureKeepsDraftAndRetryUsesCurrentFields() async throws {
        let initial = try JSONDecoder().decode(Profile.self, from: profileJSON)
        let service = ProfileServiceStub(response: initial)
        let model = ProfileViewModel(profileService: service)
        await model.loadProfile()
        let original = model.profile
        let draft = EditProfileViewModel(profile: original)
        draft.name = "Новое имя"
        draft.biography = "Новое описание"
        draft.website = "https://new.example.com"
        draft.updateAvatar(link: "https://example.com/new.png")
        let edited = draft.updatedProfile

        await service.setError(URLError(.notConnectedToInternet))
        for _ in 0..<2 {
            let saved = await draft.save {
                XCTAssertTrue($0.isSaving)
                XCTAssertNil($0.errorMessage)
                XCTAssertFalse($0.canRetrySave)
                try await model.saveProfile($0.profileUpdate)
            }
            XCTAssertFalse(saved)
            XCTAssertFalse(draft.isSaving)
            XCTAssertTrue(draft.canRetrySave)
            XCTAssertNotNil(draft.errorMessage)
            XCTAssertEqual(draft.updatedProfile, edited)
            XCTAssertEqual(model.profile, original)
            XCTAssertEqual(model.loadedProfile, initial)
        }

        draft.dismissError()
        XCTAssertNil(draft.errorMessage)
        XCTAssertFalse(draft.canRetrySave)
        XCTAssertEqual(draft.updatedProfile, edited)
        draft.name = "Имя после ошибки"
        let response = Profile(
            id: initial.id, name: draft.name, avatar: draft.profileUpdate.avatar,
            description: draft.biography, website: draft.website,
            nfts: initial.nfts, likes: initial.likes
        )
        await service.setError(nil)
        await service.setResponse(response)

        let saved = await draft.save { try await model.saveProfile($0.profileUpdate) }

        XCTAssertTrue(saved)
        XCTAssertFalse(draft.isSaving)
        XCTAssertFalse(draft.canRetrySave)
        XCTAssertNil(draft.errorMessage)
        let updates = await service.savedUpdates
        XCTAssertEqual(updates.count, 3)
        let update = try XCTUnwrap(updates.last)
        XCTAssertEqual(update.name, "Имя после ошибки")
        XCTAssertEqual(update.description, edited.biography)
        XCTAssertEqual(update.website, edited.websiteTitle)
        XCTAssertEqual(update.avatar, edited.avatarURL?.absoluteString)
        XCTAssertEqual(model.profile, UserProfile(profile: response))
    }

    func testDraftUsesCurrentProfileAndDiscardingChangesDoesNotSave() async throws {
        let response = try JSONDecoder().decode(Profile.self, from: profileJSON)
        let service = ProfileServiceStub(response: response)
        let model = ProfileViewModel(profileService: service)
        await model.loadProfile()
        let original = model.profile
        let draft = EditProfileViewModel(profile: model.profile)
        XCTAssertEqual(draft.updatedProfile, original)
        XCTAssertFalse(draft.hasChanges)

        draft.name = "Несохранённое имя"
        draft.biography = "Несохранённое описание"
        draft.website = "https://new.example.com"
        draft.removeAvatar()

        XCTAssertEqual(model.profile, original)
        XCTAssertEqual(model.loadedProfile, response)
        let reopened = EditProfileViewModel(profile: model.profile)
        XCTAssertEqual(reopened.updatedProfile, original)
        XCTAssertFalse(reopened.hasChanges)
        let updates = await service.savedUpdates
        XCTAssertTrue(updates.isEmpty)
    }

    func testSaveSendsDraftAndPublishesServerResponseForNextEditingSession() async throws {
        let initial = try JSONDecoder().decode(Profile.self, from: profileJSON)
        let service = ProfileServiceStub(response: initial)
        let model = ProfileViewModel(profileService: service)
        await model.loadProfile()
        let original = model.profile
        let draft = EditProfileViewModel(profile: model.profile)
        draft.name = " Новое имя "
        draft.biography = "Новое описание\nВторая строка"
        draft.website = " https://new.example.com "
        draft.updateAvatar(link: "https://example.com/new.png")
        let response = Profile(
            id: initial.id, name: "Имя из ответа сервера", avatar: "https://example.com/saved.png",
            description: "Описание из ответа сервера", website: "https://saved.example.com",
            nfts: ["nft-1"], likes: []
        )
        await service.setResponse(response)

        let saved = await draft.save {
            XCTAssertEqual(model.profile, original)
            XCTAssertEqual(model.loadedProfile, initial)
            try await model.saveProfile($0.profileUpdate)
        }

        XCTAssertTrue(saved)
        let updates = await service.savedUpdates
        XCTAssertEqual(updates.count, 1)
        let update = try XCTUnwrap(updates.first)
        XCTAssertEqual(update.name, "Новое имя")
        XCTAssertEqual(update.description, "Новое описание\nВторая строка")
        XCTAssertEqual(update.website, "https://new.example.com")
        XCTAssertEqual(update.avatar, "https://example.com/new.png")
        XCTAssertEqual(model.loadedProfile, response)
        XCTAssertEqual(model.profile, UserProfile(profile: response))
        XCTAssertEqual(model.profile.ownedNFTCount, 1)
        XCTAssertEqual(model.profile.favoriteNFTCount, 0)
        let reopened = EditProfileViewModel(profile: model.profile)
        XCTAssertEqual(reopened.updatedProfile, UserProfile(profile: response))
        XCTAssertFalse(reopened.hasChanges)
    }

    func testSaveFailurePreservesOriginalProfileAndEditedFields() async throws {
        let initial = try JSONDecoder().decode(Profile.self, from: profileJSON)
        let service = ProfileServiceStub(response: initial)
        let model = ProfileViewModel(profileService: service)
        await model.loadProfile()
        let original = model.profile
        let draft = EditProfileViewModel(profile: model.profile)
        draft.name = "Новое имя"
        draft.biography = "Новое описание"
        draft.website = "https://new.example.com"
        draft.updateAvatar(link: "https://example.com/new.png")
        let edited = draft.updatedProfile
        await service.setError(URLError(.notConnectedToInternet))

        let saved = await draft.save { try await model.saveProfile($0.profileUpdate) }

        XCTAssertFalse(saved)
        XCTAssertEqual(model.profile, original)
        XCTAssertEqual(model.loadedProfile, initial)
        XCTAssertEqual(draft.updatedProfile, edited)
        XCTAssertTrue(draft.hasChanges)
        XCTAssertFalse(draft.isSaving)
    }

    func testSavingRemovedAvatarAndEmptyOptionalFieldsSendsEmptyValues() async throws {
        let initial = try JSONDecoder().decode(Profile.self, from: profileJSON)
        let service = ProfileServiceStub(response: initial)
        let model = ProfileViewModel(profileService: service)
        await model.loadProfile()
        let draft = EditProfileViewModel(profile: model.profile)
        draft.removeAvatar()
        draft.biography = ""
        draft.website = ""
        let response = Profile(id: initial.id, name: initial.name, avatar: "", description: "", website: "",
                               nfts: initial.nfts, likes: initial.likes)
        await service.setResponse(response)

        let saved = await draft.save { try await model.saveProfile($0.profileUpdate) }

        XCTAssertTrue(saved)
        let updates = await service.savedUpdates
        let update = try XCTUnwrap(updates.first)
        XCTAssertEqual(update.avatar, "")
        XCTAssertEqual(update.description, "")
        XCTAssertEqual(update.website, "")
        XCTAssertNil(model.profile.avatarURL)
        XCTAssertNil(EditProfileViewModel(profile: model.profile).avatarURL)
    }

    func testInvalidInputDoesNotCallServiceOrChangeProfile() async throws {
        let initial = try JSONDecoder().decode(Profile.self, from: profileJSON)
        let service = ProfileServiceStub(response: initial)
        let model = ProfileViewModel(profileService: service)
        await model.loadProfile()
        let original = model.profile
        let draft = EditProfileViewModel(profile: model.profile)
        draft.name = " \n"

        let saved = await draft.save { try await model.saveProfile($0.profileUpdate) }

        XCTAssertFalse(saved)
        let updates = await service.savedUpdates
        XCTAssertTrue(updates.isEmpty)
        XCTAssertEqual(model.profile, original)
        XCTAssertEqual(model.loadedProfile, initial)
    }

    func testCancelledSaveDoesNotPublishServerResponse() async throws {
        let initial = try JSONDecoder().decode(Profile.self, from: profileJSON)
        let service = ProfileServiceStub(response: initial)
        let model = ProfileViewModel(profileService: service)
        await model.loadProfile()
        let original = model.profile
        let draft = EditProfileViewModel(profile: model.profile)
        draft.name = "Новое имя"
        await service.setCancelsSave(true)

        let task = Task { await draft.save { try await model.saveProfile($0.profileUpdate) } }
        let saved = await task.value

        XCTAssertFalse(saved)
        XCTAssertEqual(model.profile, original)
        XCTAssertEqual(model.loadedProfile, initial)
        XCTAssertEqual(draft.name, "Новое имя")
        XCTAssertNil(draft.errorMessage)
        XCTAssertFalse(draft.isSaving)
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

@MainActor
private final class DeferredProfileService: ProfileService {
    let response: Profile
    var error: Error?
    var onLoad: (() async -> Void)?
    private(set) var loadCalls = 0

    init(response: Profile) { self.response = response }

    func loadProfile() async throws -> Profile {
        loadCalls += 1
        await onLoad?()
        if let error { throw error }
        return response
    }

    func saveProfile(_ profile: ProfileUpdate) async throws -> Profile { response }
    func saveLikes(_ ids: [String]) async throws -> Profile { response }
}

private actor ProfileServiceStub: ProfileService {
    private var response: Profile
    private var error: Error?
    private var cancelsSave = false
    private(set) var savedUpdates: [ProfileUpdate] = []

    init(response: Profile) { self.response = response }

    func setError(_ error: Error?) { self.error = error }
    func setResponse(_ response: Profile) { self.response = response }
    func setCancelsSave(_ cancelsSave: Bool) { self.cancelsSave = cancelsSave }

    func loadProfile() async throws -> Profile {
        if let error { throw error }
        return response
    }

    func saveProfile(_ profile: ProfileUpdate) async throws -> Profile {
        savedUpdates.append(profile)
        if cancelsSave { withUnsafeCurrentTask { $0?.cancel() } }
        return try await loadProfile()
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
