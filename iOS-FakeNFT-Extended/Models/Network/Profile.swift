import Foundation

struct Profile: Decodable, Equatable, Sendable {
    let id: String
    let name: String
    let avatar: String
    let description: String
    let website: String
    let nfts: [String]
    let likes: [String]
}

struct ProfileUpdate: Sendable {
    let name: String
    let description: String
    let avatar: String
    let website: String
}
