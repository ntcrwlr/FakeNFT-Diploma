import Foundation
import Observation

enum CatalogSort: String {
    case name
    case nftCount

    static let storageKey = "catalog.sort"
}

@MainActor
@Observable
final class CatalogViewModel {
    private let collectionService: CollectionService
    private var collections: [NftCollection] = []
    private var isLoading = false

    private(set) var phase: Phase = .idle
    private(set) var sort: CatalogSort

    enum Phase {
        case idle
        case loading
        case loaded([NftCollection])
        case failed
    }

    init(collectionService: CollectionService, sort: CatalogSort) {
        self.collectionService = collectionService
        self.sort = sort
    }

    convenience init(previewCollections: [NftCollection], sort: CatalogSort) {
        self.init(collectionService: PreviewCollectionService(), sort: sort)
        collections = previewCollections
        phase = .loaded(sorted(previewCollections))
    }

    func loadIfNeeded() async {
        if case .idle = phase {
            await load()
        }
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        phase = .loading
        do {
            let collections = try await collectionService.loadCollections()
            guard !Task.isCancelled else {
                phase = .idle
                return
            }
            self.collections = collections
            phase = .loaded(sorted(collections))
        } catch {
            guard !Task.isCancelled else {
                phase = .idle
                return
            }
            phase = .failed
        }
    }

    func setSort(_ sort: CatalogSort) {
        guard self.sort != sort else { return }
        self.sort = sort
        guard case .loaded = phase else { return }
        phase = .loaded(sorted(collections))
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

private final class PreviewCollectionService: CollectionService {
    func loadCollections() async throws -> [NftCollection] {
        []
    }
}
