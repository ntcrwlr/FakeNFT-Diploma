import Foundation

struct Nft: Decodable, Sendable {
let id: String
let name: String
let author: String
let images: [URL]
let rating: Int
let price: Decimal

var imagesURLs: [URL] {
images
}
}