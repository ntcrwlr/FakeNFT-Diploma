import Foundation

enum CollectionDetailsState {
    case idle
    case loading
    case success([Nft])
    case error
}
