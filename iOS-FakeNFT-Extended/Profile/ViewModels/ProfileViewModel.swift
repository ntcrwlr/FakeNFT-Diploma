import Observation

@MainActor
@Observable
final class ProfileViewModel {
    private(set) var profile: UserProfile

    init(profile: UserProfile) {
        self.profile = profile
    }
}
