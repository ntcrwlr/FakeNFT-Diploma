import Observation

@MainActor
@Observable
final class OwnedNFTsViewModel {
    private(set) var items: [OwnedNFT]
    var isSortMenuPresented = false

    var isEmpty: Bool { items.isEmpty }

    init(items: [OwnedNFT]) {
        self.items = items
    }

    // This iteration only presents the menu; sorting will be connected separately.
    func closeSortMenu() {
        isSortMenuPresented = false
    }
}
