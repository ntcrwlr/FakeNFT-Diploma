import Foundation

struct OwnedNFT: Identifiable {
    let id: String
    let name: String
    let author: String
    let price: Decimal
    let rating: Int
    let imageName: String?
    let isFavorite: Bool

    var formattedPrice: String {
        price.formatted(.number.locale(Locale(identifier: "ru_RU"))) + " ETH"
    }
}

enum OwnedNFTFixtures {
    static let preview: [OwnedNFT] = ["Lilo", "Spring", "April"].map { name in
        OwnedNFT(
            id: name,
            name: name,
            author: "John Doe",
            price: Decimal(178) / 100,
            rating: 3,
            imageName: name,
            isFavorite: true
        )
    }
}
