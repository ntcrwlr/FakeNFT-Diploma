import Foundation

final class PreviewFavoritesService: FavoritesServiceProtocol {
    private var likes: Set<String> = ["1", "3"]

    func loadLikes() async throws -> Set<String> {
        likes
    }

    func updateLikes(_ likes: Set<String>) async throws -> Set<String> {
        self.likes = likes
        return likes
    }
}
