import Foundation

struct FavoriteNFT: Identifiable {
    let id: String
    let name: String
    let price: Decimal
    let rating: Int
    let imageName: String

    var formattedPrice: String {
        price.formatted(.number.locale(Locale(identifier: "ru_RU"))) + " ETH"
    }
}

enum FavoriteNFTFixtures {
    // Reuse bundled artwork until the remaining images from the mockup are supplied.
    static let preview: [FavoriteNFT] = [
        ("Archie", "Spring", 1),
        ("Pixi", "April", 3),
        ("Melissa", "Spring", 5),
        ("April", "April", 2),
        ("Daisy", "Lilo", 1),
        ("Lilo", "Lilo", 4)
    ].map { name, imageName, rating in
        FavoriteNFT(
            id: name,
            name: name,
            price: Decimal(178) / 100,
            rating: rating,
            imageName: imageName
        )
    }
}
