import Foundation

struct PreviewNftService: NftService {
    func loadNft(id: String) async throws -> Nft {
        let samples: [String: (name: String, rating: Int, price: Decimal)] = [
            "1": ("April", 8, Decimal(string: "1.78")!),
            "2": ("Aurora", 6, 1),
            "3": ("Biscuit", 4, Decimal(string: "2.5")!),
            "4": ("Cotton", 10, Decimal(string: "1.23")!),
            "5": ("Daisy", 2, 3),
            "6": ("Ellie", 0, Decimal(string: "0.5")!)
        ]
        let sample = samples[id] ?? (name: "NFT \(id)", rating: 0, price: 1)
        return Nft(
            id: id,
            name: sample.name,
            author: "John Doe",
            images: [],
            rating: sample.rating,
            price: sample.price
        )
    }
}
