import Foundation

@MainActor
enum CatalogAssembly {
    static func makeView(
        collectionService: CollectionServiceProtocol,
        nftService: NftService
    ) -> CatalogView {
        let rawValue = UserDefaults.standard.string(forKey: CatalogSort.storageKey)
        let sort = CatalogSort(rawValue: rawValue ?? "") ?? .nftCount
        let viewModel = CatalogViewModel(collectionService: collectionService, sort: sort)

        return CatalogView(viewModel: viewModel, nftService: nftService)
    }
}
