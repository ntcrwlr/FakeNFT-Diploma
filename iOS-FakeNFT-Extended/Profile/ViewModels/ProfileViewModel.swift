import Foundation
import Observation

@MainActor
@Observable
final class ProfileViewModel {
    private(set) var profile: UserProfile

    var websiteURL: URL? {
        let value = profile.websiteTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.contains(where: { $0.isWhitespace }),
              let url = URL(string: value),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              let host = url.host, !host.isEmpty else { return nil }
        return url
    }

    func updateProfile(_ profile: UserProfile) {
        self.profile = profile
    }

    init(profile: UserProfile) {
        self.profile = profile
    }
}
