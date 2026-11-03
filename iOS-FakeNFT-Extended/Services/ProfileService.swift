import Foundation

protocol ProfileService: Sendable {
    func loadProfile() async throws -> Profile
    func saveProfile(_ profile: ProfileUpdate) async throws -> Profile
}

actor ProfileServiceImpl: ProfileService {
    private let networkClient: NetworkClient

    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }

    func loadProfile() async throws -> Profile {
        try await networkClient.send(request: ProfileRequest())
    }

    func saveProfile(_ profile: ProfileUpdate) async throws -> Profile {
        try await networkClient.send(request: UpdateProfileRequest(profile: profile))
    }
}
