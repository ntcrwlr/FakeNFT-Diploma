import Foundation

struct Nft: Decodable {
    let id: String
    let name: String
    let imagesURLs: [URL]
    let rating: Int
    let price: Double

    enum CodingKeys: String, CodingKey {
        case id, name, rating, price
        case imagesURLs = "images"
    }
}
