import Foundation

struct PreviewNftService: NftService {
    func loadNft(id: String) async throws -> Nft {
        let samples: [String: (name: String, rating: Int, price: Double)] = [
            "1": ("April", 8, 1.78),
            "2": ("Aurora", 6, 1),
            "3": ("Biscuit", 4, 2.5),
            "4": ("Cotton", 10, 1.23),
            "5": ("Daisy", 2, 3),
            "6": ("Ellie", 0, 0.5)
        ]
        let sample = samples[id] ?? (name: "NFT \(id)", rating: 0, price: 1)
        return Nft(id: id, name: sample.name, images: [], rating: sample.rating, price: sample.price)
    }
}
