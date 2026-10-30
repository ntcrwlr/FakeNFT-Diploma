import Foundation

enum CatalogState {
    case loading
    case success([NftCollection])
    case error
}
