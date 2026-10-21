import Foundation

struct NftCollection: Decodable, Sendable, Identifiable {
    let id: String
    let name: String
    let cover: String
    let description: String
    let author: String
    let nfts: [String]
}
