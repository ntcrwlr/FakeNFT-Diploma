import Foundation
import Observation

@MainActor
@Observable
final class CatalogViewModel {
    private let collectionService: CollectionServiceProtocol
    private var collections: [NftCollection] = []
    private var isLoading = false

    private(set) var state: CatalogState = .loading
    private(set) var sort: CatalogSort

    init(collectionService: CollectionServiceProtocol, sort: CatalogSort) {
        self.collectionService = collectionService
        self.sort = sort
    }

    convenience init(previewCollections: [NftCollection], sort: CatalogSort) {
        self.init(collectionService: PreviewCollectionService(), sort: sort)
        collections = previewCollections
        state = .success(sorted(previewCollections))
    }

    func loadIfNeeded() async {
        guard case .loading = state else { return }
        await load()
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        state = .loading
        do {
            let collections = try await collectionService.loadCollections()
            guard !Task.isCancelled else { return }
            self.collections = collections
            state = .success(sorted(collections))
        } catch {
            guard !Task.isCancelled else { return }
            state = .error
        }
    }

    func setSort(_ sort: CatalogSort) {
        guard self.sort != sort else { return }
        self.sort = sort
        guard case .success = state else { return }
        state = .success(sorted(collections))
    }

    private func sorted(_ collections: [NftCollection]) -> [NftCollection] {
        switch sort {
        case .name:
            collections.sorted {
                $0.name.localizedStandardCompare($1.name) == .orderedAscending
            }
        case .nftCount:
            collections.sorted { $0.nfts.count > $1.nfts.count }
        }
    }
}

private final class PreviewCollectionService: CollectionServiceProtocol {
    func loadCollections() async throws -> [NftCollection] {
        []
    }
}
