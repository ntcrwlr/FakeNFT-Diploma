import Foundation

protocol FavoritesServiceProtocol {
    func loadLikes() async throws -> Set<String>
    func updateLikes(_ likes: Set<String>) async throws -> Set<String>
}

final class FavoritesService: FavoritesServiceProtocol {
    private let networkClient: NetworkClient

    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }

    func loadLikes() async throws -> Set<String> {
        let profile: ProfileLikesResponse = try await networkClient.send(request: ProfileLikesRequest())
        return Set(profile.likes ?? [])
    }

    func updateLikes(_ likes: Set<String>) async throws -> Set<String> {
        let profile: ProfileLikesResponse = try await networkClient.send(
            request: UpdateProfileLikesRequest(likes: likes)
        )
        return Set(profile.likes ?? [])
    }
}
