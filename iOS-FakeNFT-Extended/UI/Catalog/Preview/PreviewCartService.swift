import Foundation

final class PreviewCartService: CartServiceProtocol {
    private var nftIds: Set<String> = ["2", "4"]

    func loadOrder() async throws -> Set<String> {
        nftIds
    }

    func updateOrder(_ nftIds: Set<String>) async throws -> Set<String> {
        self.nftIds = nftIds
        return nftIds
    }
}
