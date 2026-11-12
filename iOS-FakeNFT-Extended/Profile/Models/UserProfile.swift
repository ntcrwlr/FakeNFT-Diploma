import Foundation

struct UserProfile: Equatable {
    let name: String
    let biography: String
    let websiteTitle: String
    let avatarAssetName: String?
    var avatarURL: URL? = nil
    var isAvatarRemoved = false
    let ownedNFTCount: Int
    let favoriteNFTCount: Int
}

extension UserProfile {
    static let empty = UserProfile(
        name: "", biography: "", websiteTitle: "", avatarAssetName: nil,
        ownedNFTCount: 0, favoriteNFTCount: 0
    )

    init(profile: Profile) {
        self.init(
            name: profile.name,
            biography: profile.description,
            websiteTitle: profile.website,
            avatarAssetName: nil,
            avatarURL: profile.avatar.isEmpty ? nil : URL(string: profile.avatar),
            ownedNFTCount: profile.nfts.count,
            favoriteNFTCount: profile.likes.count
        )
    }
}
