import Foundation

struct UserProfile: Equatable {
    let name: String
    let biography: String
    let websiteTitle: String
    let avatarAssetName: String
    var avatarURL: URL? = nil
    var isAvatarRemoved = false
    let ownedNFTCount: Int
    let favoriteNFTCount: Int
}
