import Foundation

protocol UserSettingsServiceProtocol: AnyObject {
    var ownedNFTSortOption: OwnedNFTSortOption { get set }
}

final class UserSettingsService: UserSettingsServiceProtocol {
    private enum Keys {
        static let ownedNFTSortOption = "profile.ownedNFTs.sortOption"
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    var ownedNFTSortOption: OwnedNFTSortOption {
        get {
            userDefaults.string(forKey: Keys.ownedNFTSortOption)
                .flatMap(OwnedNFTSortOption.init(rawValue:)) ?? .rating
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: Keys.ownedNFTSortOption)
        }
    }
}
