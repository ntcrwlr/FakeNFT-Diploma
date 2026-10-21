import Foundation

protocol CollectionService {
    func loadCollections() async throws -> [NftCollection]
}

final class CollectionServiceImpl: CollectionService {
    private let networkClient: NetworkClient

    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }

    func loadCollections() async throws -> [NftCollection] {
        try await networkClient.send(request: CollectionsRequest())
    }
}
