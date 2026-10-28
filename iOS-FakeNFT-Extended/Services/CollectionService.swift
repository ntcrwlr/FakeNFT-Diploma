import Foundation

protocol CollectionServiceProtocol {
    func loadCollections() async throws -> [NftCollection]
}

final class CollectionService: CollectionServiceProtocol {
    private let networkClient: NetworkClient

    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }

    func loadCollections() async throws -> [NftCollection] {
        try await networkClient.send(request: CollectionsRequest())
    }
}
