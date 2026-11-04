import Foundation

struct Nft: Decodable, Sendable {
    let id: String
    let name: String
    let author: String
    let rating: Int
    let price: Decimal
    let images: [URL]
}
